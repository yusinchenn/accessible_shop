/// ai_agent_service.dart
/// "大千世界" AI 智能代理服務
/// 整合 DeepSeek 對話，支援語音智能助理功能
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'openai_client.dart';
import 'database_service.dart';
import 'ai_agent_tools.dart';
import '../models/order_status.dart';
import '../models/notification.dart';

/// AI 代理回應類型
enum AIAgentResponseType {
  /// 純文字回應
  text,

  /// 執行工具中
  executingTool,

  /// 工具執行完成
  toolExecuted,

  /// 錯誤
  error,

  /// 顯示商品卡片
  displayProductCard,

  /// 顯示訂單卡片
  displayOrderCard,

  /// 顯示購物車卡片
  displayCartCard,

  /// 顯示通知卡片
  displayNotificationCard,
}

/// AI 代理回應
class AIAgentResponse {
  final AIAgentResponseType type;
  final String content;
  final String? toolName;
  final Map<String, dynamic>? toolResult;

  /// 卡片資料（用於顯示商品、訂單等卡片）
  final dynamic cardData;

  AIAgentResponse({
    required this.type,
    required this.content,
    this.toolName,
    this.toolResult,
    this.cardData,
  });
}

/// AI 智能代理服務
class AIAgentService {
  static final AIAgentService _instance = AIAgentService._internal();
  factory AIAgentService() => _instance;
  AIAgentService._internal();

  late final OpenAICompatibleClient _client;
  bool _isInitialized = false;

  /// 對話歷史
  final List<ChatMessage> _conversationHistory = [];

  /// 初始化服務
  void initialize() {
    if (_isInitialized) return;

    final apiKey = dotenv.env['DEEPSEEK_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('⚠️ [AIAgent] DEEPSEEK_API_KEY not found in .env');
    }

    final provider = ProviderConfig(
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com',
      apiKey: apiKey,
      defaultModel: 'deepseek-chat',
    );

    _client = OpenAICompatibleClient(provider);

    // 設置系統提示
    _conversationHistory.clear();
    _conversationHistory.add(
      ChatMessage(
        role: Role.system,
        content: '''你是「大千」，一個透過語音幫助用戶完成購物相關操作的智能助理。

你的主要能力：
1. 搜索商品：使用 search_products 工具搜尋商品
2. 查詢商品詳情：使用 get_product_detail 工具取得商品完整資訊
3. 管理購物車：
   - 使用 add_to_cart 加入商品（需要規格：尺寸、顏色）
   - 使用 get_cart_items 查看購物車
   - 使用 update_cart_quantity 更新數量
   - 使用 remove_from_cart 移除項目
4. 訂單管理：
   - 使用 checkout 完成結帳
   - 使用 get_orders 查詢訂單（可篩選狀態）
   - 使用 get_order_detail 查看訂單詳情
5. 查詢通知：使用 get_notifications 查看通知

工具使用規則：
- 當用戶要求搜尋、查詢、加入購物車、結帳等操作時，自動調用對應工具
- 如果需要規格資訊但用戶未提供，先詢問用戶再調用工具
- 工具執行後會自動顯示卡片（商品卡片、訂單卡片等），你只需簡短回應即可

重要規則：
- 始終使用繁體中文回答
- 保持友善、口語化的對話態度，像朋友般自然交談
- 你稱呼自己為「大千」
- 回答要簡短精煉，符合日常對話長度，上限60字
- 只輸出純文字，絕對不使用表情符號、emoji、markdown格式或任何特殊符號

輸出格式要求：
- 純文字，無表情符號
- 無markdown格式（不使用*、_、#、-等）
- 無特殊符號（不使用★、✓、→等）
- 像朋友對話般自然簡潔''',
      ),
    );

    _isInitialized = true;
    debugPrint('✅ [AIAgent] Service initialized');
  }

  /// 獲取對話歷史
  List<ChatMessage> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  /// 清除對話歷史（保留系統提示）
  void clearHistory() {
    if (_conversationHistory.length > 1) {
      _conversationHistory.removeRange(1, _conversationHistory.length);
    }
  }

  /// 發送訊息並獲取流式回應（支援 Function Calling）
  Stream<AIAgentResponse> sendMessageStream(String userMessage) async* {
    if (!_isInitialized) {
      initialize();
    }

    // 添加用戶訊息到歷史
    _conversationHistory.add(
      ChatMessage(role: Role.user, content: userMessage),
    );

    try {
      // 最多 5 次 Function Calling 迴圈（防止無限迴圈）
      for (int iteration = 0; iteration < 5; iteration++) {
        // 調用 AI（帶 Tools）
        final nonStreamOpts = ChatCompletionOptions(
          messages: _conversationHistory,
          temperature: 0.7,
          stream: false,
          tools: AIAgentTools.getAllTools(),
          toolChoice: 'auto',
        );

        final reply = await _client.chatCompletion(nonStreamOpts);

        // 檢查是否有 tool_calls
        if (reply.toolCalls != null && reply.toolCalls!.isNotEmpty) {
          debugPrint('🔧 [AIAgent] Tool calls detected: ${reply.toolCalls!.length}');

          // 將 assistant 訊息（帶 tool_calls）加入歷史
          _conversationHistory.add(
            ChatMessage(
              role: Role.assistant,
              content: reply.content ?? '',
              toolCalls: reply.toolCalls,
            ),
          );

          // 執行所有 tool_calls
          for (final toolCall in reply.toolCalls!) {
            final toolName = toolCall['function']['name'] as String;
            final arguments = toolCall['function']['arguments'];
            final toolCallId = toolCall['id'] as String;

            debugPrint('🛠️ [AIAgent] Executing tool: $toolName');
            debugPrint('📋 [AIAgent] Arguments: $arguments');

            // 執行工具
            final toolResult = await _executeToolCall(toolName, arguments);

            // 如果工具執行返回卡片資料，yield 卡片回應
            if (toolResult['cardData'] != null) {
              yield AIAgentResponse(
                type: toolResult['cardType'] as AIAgentResponseType,
                content: '',
                cardData: toolResult['cardData'],
              );
            }

            // 將工具結果加入對話歷史
            _conversationHistory.add(
              ChatMessage(
                role: Role.tool,
                content: jsonEncode(toolResult['result']),
                name: toolName,
                toolCallId: toolCallId,
              ),
            );
          }

          // 繼續下一次迴圈，讓 AI 根據工具結果生成最終回應
          continue;
        }

        // 沒有 tool_calls，串流輸出最終回應
        if (reply.content != null && reply.content!.isNotEmpty) {
          // 將回應加入歷史
          _conversationHistory.add(
            ChatMessage(role: Role.assistant, content: reply.content!),
          );

          // 模擬串流效果（逐字輸出）
          final content = reply.content!;
          for (int i = 0; i < content.length; i++) {
            yield AIAgentResponse(
              type: AIAgentResponseType.text,
              content: content[i],
            );
            // 短暫延遲以模擬打字效果
            await Future.delayed(const Duration(milliseconds: 20));
          }
        }

        // 完成，跳出迴圈
        break;
      }
    } catch (e) {
      debugPrint('❌ [AIAgent] Error: $e');
      yield AIAgentResponse(
        type: AIAgentResponseType.error,
        content: '抱歉，處理您的請求時發生錯誤：$e',
      );
    }
  }

  /// 執行工具調用
  Future<Map<String, dynamic>> _executeToolCall(
    String toolName,
    dynamic arguments,
  ) async {
    try {
      // 解析參數
      final Map<String, dynamic> args =
          arguments is String ? jsonDecode(arguments) : arguments;

      debugPrint('🔧 [AIAgent] Executing: $toolName with args: $args');

      final db = DatabaseService();

      switch (toolName) {
        case 'search_products':
          return await _searchProducts(args, db);
        case 'get_product_detail':
          return await _getProductDetail(args, db);
        case 'add_to_cart':
          return await _addToCart(args, db);
        case 'get_cart_items':
          return await _getCartItems(db);
        case 'update_cart_quantity':
          return await _updateCartQuantity(args, db);
        case 'remove_from_cart':
          return await _removeFromCart(args, db);
        case 'checkout':
          return await _checkout(args, db);
        case 'get_orders':
          return await _getOrders(args, db);
        case 'get_order_detail':
          return await _getOrderDetail(args, db);
        case 'get_notifications':
          return await _getNotifications(args, db);
        default:
          return {
            'result': {'error': '未知的工具: $toolName'},
            'cardType': null,
            'cardData': null,
          };
      }
    } catch (e) {
      debugPrint('❌ [AIAgent] Tool execution error: $e');
      return {
        'result': {'error': '執行失敗: $e'},
        'cardType': null,
        'cardData': null,
      };
    }
  }

  /// 搜尋商品
  Future<Map<String, dynamic>> _searchProducts(
    Map<String, dynamic> args,
    DatabaseService db,
  ) async {
    final keyword = args['keyword'] as String;
    final products = await db.searchProducts(keyword);

    return {
      'result': {
        'count': products.length,
        'products': products
            .map((p) => {
                  'id': p.id,
                  'name': p.name,
                  'price': p.price,
                  'description': p.description,
                })
            .toList(),
      },
      'cardType': AIAgentResponseType.displayProductCard,
      'cardData': products.take(10).toList(), // 最多顯示 10 個商品卡片
    };
  }

  /// 取得商品詳情
  Future<Map<String, dynamic>> _getProductDetail(
    Map<String, dynamic> args,
    DatabaseService db,
  ) async {
    final productId = args['product_id'] as int;
    final product = await db.getProductById(productId);

    if (product == null) {
      return {
        'result': {'error': '找不到商品'},
        'cardType': null,
        'cardData': null,
      };
    }

    // 取得商家資訊
    final store = await db.getStoreById(product.storeId);

    return {
      'result': {
        'id': product.id,
        'name': product.name,
        'price': product.price,
        'description': product.description,
        'stock': product.stock,
        'averageRating': product.averageRating,
        'reviewCount': product.reviewCount,
        'soldCount': product.soldCount,
        'store': store?.name ?? '未知商家',
      },
      'cardType': AIAgentResponseType.displayProductCard,
      'cardData': [product],
    };
  }

  /// 加入購物車
  Future<Map<String, dynamic>> _addToCart(
    Map<String, dynamic> args,
    DatabaseService db,
  ) async {
    final productId = args['product_id'] as int;
    final size = args['size'] as String? ?? '通用尺寸';
    final color = args['color'] as String? ?? '預設顏色';
    final quantity = args['quantity'] as int? ?? 1;

    // 取得商品資訊
    final product = await db.getProductById(productId);
    if (product == null) {
      return {
        'result': {'error': '商品不存在'},
        'cardType': null,
        'cardData': null,
      };
    }

    // 檢查庫存
    if (product.stock < quantity) {
      return {
        'result': {'error': '庫存不足，目前庫存：${product.stock}'},
        'cardType': null,
        'cardData': null,
      };
    }

    // 取得商家資訊
    final store = await db.getStoreById(product.storeId);
    if (store == null) {
      return {
        'result': {'error': '商家不存在'},
        'cardType': null,
        'cardData': null,
      };
    }

    // 組合規格字串
    final specification = '尺寸: $size / 顏色: $color';

    // 加入購物車
    await db.addToCart(
      productId: productId,
      productName: product.name,
      price: product.price,
      specification: specification,
      storeId: product.storeId,
      storeName: store.name,
      quantity: quantity,
    );

    return {
      'result': {
        'success': true,
        'product': product.name,
        'specification': specification,
        'quantity': quantity,
      },
      'cardType': null,
      'cardData': null,
    };
  }

  /// 取得購物車
  Future<Map<String, dynamic>> _getCartItems(DatabaseService db) async {
    final cartItems = await db.getCartItems();

    return {
      'result': {
        'count': cartItems.length,
        'items': cartItems
            .map((item) => {
                  'id': item.id,
                  'name': item.name,
                  'specification': item.specification,
                  'quantity': item.quantity,
                  'unitPrice': item.unitPrice,
                  'isSelected': item.isSelected,
                })
            .toList(),
      },
      'cardType': AIAgentResponseType.displayCartCard,
      'cardData': cartItems,
    };
  }

  /// 更新購物車數量
  Future<Map<String, dynamic>> _updateCartQuantity(
    Map<String, dynamic> args,
    DatabaseService db,
  ) async {
    final cartItemId = args['cart_item_id'] as int;
    final quantity = args['quantity'] as int;

    await db.updateCartItemQuantity(cartItemId, quantity);

    return {
      'result': {
        'success': true,
        'cart_item_id': cartItemId,
        'new_quantity': quantity,
      },
      'cardType': null,
      'cardData': null,
    };
  }

  /// 移除購物車項目
  Future<Map<String, dynamic>> _removeFromCart(
    Map<String, dynamic> args,
    DatabaseService db,
  ) async {
    final cartItemId = args['cart_item_id'] as int;

    await db.removeFromCart(cartItemId);

    return {
      'result': {
        'success': true,
        'cart_item_id': cartItemId,
      },
      'cardType': null,
      'cardData': null,
    };
  }

  /// 結帳
  Future<Map<String, dynamic>> _checkout(
    Map<String, dynamic> args,
    DatabaseService db,
  ) async {
    final shippingMethodId = args['shipping_method_id'] as int? ?? 1;
    final paymentMethodId = args['payment_method_id'] as int? ?? 1;
    // final couponId = args['coupon_id'] as int?; // 暫時不使用優惠券
    final deliveryType = args['delivery_type'] as String?;

    // 取得已選購物車項目
    final cartItems = await db.getCartItems();
    final selectedItems =
        cartItems.where((item) => item.isSelected).toList();

    if (selectedItems.isEmpty) {
      return {
        'result': {'error': '購物車沒有已選取的項目'},
        'cardType': null,
        'cardData': null,
      };
    }

    // 配送方式對應
    final shippingMethodName = shippingMethodId == 1 ? '宅配' : '超商取貨';
    final shippingFee = shippingMethodId == 1 ? 60.0 : 45.0;

    // 付款方式對應
    final paymentMethodName = paymentMethodId == 1
        ? '信用卡'
        : paymentMethodId == 2
            ? 'ATM轉帳'
            : '貨到付款';
    final isCashOnDelivery = paymentMethodId == 3;

    // 建立訂單（按商家分組）
    final orders = await db.createOrdersByStore(
      cartItems: selectedItems,
      shippingMethodId: shippingMethodId,
      shippingMethodName: shippingMethodName,
      shippingFee: shippingFee,
      paymentMethodId: paymentMethodId,
      paymentMethodName: paymentMethodName,
      isCashOnDelivery: isCashOnDelivery,
      deliveryType: deliveryType,
    );

    return {
      'result': {
        'success': true,
        'order_count': orders.length,
        'order_numbers': orders.map((o) => o.orderNumber).toList(),
        'total_amount': orders.fold<double>(0, (sum, o) => sum + o.total),
      },
      'cardType': AIAgentResponseType.displayOrderCard,
      'cardData': orders,
    };
  }

  /// 查詢訂單
  Future<Map<String, dynamic>> _getOrders(
    Map<String, dynamic> args,
    DatabaseService db,
  ) async {
    final mainStatusStr = args['main_status'] as String?;
    final logisticsStatusStr = args['logistics_status'] as String?;

    // 取得所有訂單
    var orders = await db.getOrders();

    // 篩選主要狀態
    if (mainStatusStr != null) {
      final mainStatus = OrderMainStatus.values.firstWhere(
        (e) => e.name == mainStatusStr,
        orElse: () => OrderMainStatus.pendingPayment,
      );
      orders = orders.where((o) => o.mainStatus == mainStatus).toList();
    }

    // 篩選物流狀態
    if (logisticsStatusStr != null) {
      final logisticsStatus = LogisticsStatus.values.firstWhere(
        (e) => e.name == logisticsStatusStr,
        orElse: () => LogisticsStatus.none,
      );
      orders =
          orders.where((o) => o.logisticsStatus == logisticsStatus).toList();
    }

    return {
      'result': {
        'count': orders.length,
        'orders': orders
            .map((o) => {
                  'id': o.id,
                  'orderNumber': o.orderNumber,
                  'storeName': o.storeName,
                  'total': o.total,
                  'mainStatus': o.mainStatus.name,
                  'logisticsStatus': o.logisticsStatus.name,
                })
            .toList(),
      },
      'cardType': AIAgentResponseType.displayOrderCard,
      'cardData': orders,
    };
  }

  /// 取得訂單詳情
  Future<Map<String, dynamic>> _getOrderDetail(
    Map<String, dynamic> args,
    DatabaseService db,
  ) async {
    final orderId = args['order_id'] as int;

    final order = await db.getOrderById(orderId);
    if (order == null) {
      return {
        'result': {'error': '訂單不存在'},
        'cardType': null,
        'cardData': null,
      };
    }

    final orderItems = await db.getOrderItems(orderId);

    return {
      'result': {
        'id': order.id,
        'orderNumber': order.orderNumber,
        'storeName': order.storeName,
        'total': order.total,
        'mainStatus': order.mainStatus.name,
        'logisticsStatus': order.logisticsStatus.name,
        'items': orderItems
            .map((item) => {
                  'productName': item.productName,
                  'specification': item.specification,
                  'quantity': item.quantity,
                  'unitPrice': item.unitPrice,
                  'subtotal': item.subtotal,
                })
            .toList(),
      },
      'cardType': AIAgentResponseType.displayOrderCard,
      'cardData': [order],
    };
  }

  /// 查詢通知
  Future<Map<String, dynamic>> _getNotifications(
    Map<String, dynamic> args,
    DatabaseService db,
  ) async {
    final unreadOnly = args['unread_only'] as bool? ?? false;
    final typeStr = args['type'] as String?;

    var notifications = await db.getNotifications();

    // 篩選未讀
    if (unreadOnly) {
      notifications = notifications.where((n) => !n.isRead).toList();
    }

    // 篩選類型
    if (typeStr != null) {
      final type = NotificationType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => NotificationType.system,
      );
      notifications = notifications.where((n) => n.type == type).toList();
    }

    return {
      'result': {
        'count': notifications.length,
        'notifications': notifications
            .map((n) => {
                  'id': n.id,
                  'title': n.title,
                  'content': n.content,
                  'type': n.type.name,
                  'isRead': n.isRead,
                  'timestamp': n.timestamp.toIso8601String(),
                })
            .toList(),
      },
      'cardType': AIAgentResponseType.displayNotificationCard,
      'cardData': notifications.take(10).toList(), // 最多顯示 10 個
    };
  }
}

/// 全局單例
final aiAgentService = AIAgentService();