import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 匯入模型
import '../models/store.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/user_settings.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../models/user_profile.dart';
import '../models/notification.dart';
import '../models/product_review.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';

// 匯入工具類
import '../utils/fuzzy_search_helper.dart';

// 匯入服務
import 'notification_service.dart';
import 'test_data_service.dart';

class DatabaseService extends ChangeNotifier {
  late Future<Isar> _isarFuture;
  static const String _kDatabaseInitializedKey = 'database_initialized';

  DatabaseService() {
    _isarFuture = _initIsar();
  }

  /// 初始化 Isar（非同步，不阻塞 UI）
  Future<Isar> _initIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open([
      StoreSchema,
      ProductSchema,
      CartItemSchema,
      UserSettingsSchema,
      OrderSchema,
      OrderItemSchema,
      OrderStatusHistorySchema,
      OrderStatusTimestampsSchema,
      UserProfileSchema,
      NotificationModelSchema,
      ProductReviewSchema,
      ConversationSchema,
      ChatMessageSchema,
    ], directory: dir.path);

    // 檢查是否為首次啟動，如果是則自動初始化測試資料
    await _checkAndInitializeTestData(isar);

    return isar;
  }

  /// 檢查並在首次啟動時初始化測試資料
  Future<void> _checkAndInitializeTestData(Isar isar) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isInitialized = prefs.getBool(_kDatabaseInitializedKey) ?? false;

      if (!isInitialized) {
        if (kDebugMode) {
          print('📦 [DatabaseService] 偵測到首次啟動，開始自動初始化測試資料...');
        }

        // 使用 TestDataService 初始化測試資料
        final testDataService = TestDataService(isar);
        await testDataService.initializeAllTestData();

        // 標記為已初始化
        await prefs.setBool(_kDatabaseInitializedKey, true);

        if (kDebugMode) {
          print('✅ [DatabaseService] 測試資料初始化完成');
        }
      } else {
        if (kDebugMode) {
          print('ℹ️ [DatabaseService] 資料庫已初始化，跳過測試資料自動載入');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [DatabaseService] 自動初始化測試資料失敗: $e');
        print('   您可以稍後從開發工具頁面手動初始化');
      }
      // 不要拋出錯誤，讓應用程式繼續運行
    }
  }

  // ==================== 商家相關方法 ====================

  /// 取得所有商家
  Future<List<Store>> getStores() async {
    final isar = await _isarFuture;
    return await isar.stores.where().findAll();
  }

  /// 用 id 查詢商家
  Future<Store?> getStoreById(int id) async {
    final isar = await _isarFuture;
    return await isar.stores.get(id);
  }

  /// 取得商家的所有商品
  Future<List<Product>> getProductsByStoreId(int storeId) async {
    final isar = await _isarFuture;
    final allProducts = await isar.products.where().findAll();
    return allProducts.where((product) => product.storeId == storeId).toList();
  }

  /// 外部存取 Isar 實例
  Future<Isar> get isar async => await _isarFuture;

  /// 取得所有商品
  Future<List<Product>> getProducts() async {
    final isar = await _isarFuture; // ✅ 先取得 Isar 實例
    return await isar.products.where().findAll();
  }

  /// 用 id 查詢商品
  Future<Product?> getProductById(int id) async {
    final isar = await _isarFuture; // ✅ 先取得 Isar 實例
    return await isar.products.get(id);
  }

  /// 智能搜尋商品（支援模糊搜尋與優先級排序）
  /// 排序優先級：
  /// 1. 商品名稱完全匹配 (100分)
  /// 2. 商品名稱開頭匹配 (95分)
  /// 3. 商品名稱包含關鍵字 (90分)
  /// 4. 描述完全匹配 (80分)
  /// 5. 描述包含關鍵字 (70分)
  /// 6. 店家名稱完全匹配 (60分)
  /// 7. 店家名稱包含關鍵字 (50分)
  /// 8. 分類包含關鍵字 (40分)
  /// 9. 商品名稱模糊匹配 (30分以下)
  /// 10. 描述模糊匹配 (20分以下)
  /// 11. 店家名稱模糊匹配 (10分以下)
  Future<List<Product>> searchProducts(String keyword) async {
    if (keyword.isEmpty) {
      return await getProducts();
    }

    final isar = await _isarFuture;
    final allProducts = await isar.products.where().findAll();
    final allStores = await isar.stores.where().findAll();

    // 建立店家 Map 以便快速查詢
    final storesMap = {for (var store in allStores) store.id: store};

    if (kDebugMode) {
      print('🔍 [DatabaseService] 資料庫總商品數: ${allProducts.length}');
      print('🔍 [DatabaseService] 搜尋關鍵字: "$keyword"');
    }

    final searchKeyword = keyword.toLowerCase().trim();

    // 使用評分系統進行排序
    final scoredProducts = allProducts.map((product) {
      double score = 0.0;
      final name = product.name.toLowerCase();
      final description = (product.description ?? '').toLowerCase();
      final category = (product.category ?? '').toLowerCase();

      // 取得店家名稱
      final store = storesMap[product.storeId];
      final storeName = (store?.name ?? '').toLowerCase();

      // === 精確匹配階段 ===

      // 1. 商品名稱完全匹配 - 最高分 100
      if (name == searchKeyword) {
        score = 100.0;
      }
      // 2. 商品名稱開頭匹配 - 95 分
      else if (name.startsWith(searchKeyword)) {
        score = 95.0;
      }
      // 3. 商品名稱包含關鍵字 - 90 分
      else if (name.contains(searchKeyword)) {
        score = 90.0;
      }
      // 4. 描述完全匹配 - 80 分
      else if (description == searchKeyword) {
        score = 80.0;
      }
      // 5. 描述包含關鍵字 - 70 分
      else if (description.contains(searchKeyword)) {
        score = 70.0;
      }
      // 6. 店家名稱完全匹配 - 60 分
      else if (storeName == searchKeyword) {
        score = 60.0;
      }
      // 7. 店家名稱包含關鍵字 - 50 分
      else if (storeName.contains(searchKeyword)) {
        score = 50.0;
      }
      // 8. 分類包含關鍵字 - 40 分
      else if (category.contains(searchKeyword)) {
        score = 40.0;
      }

      // === 模糊匹配階段 ===
      else {
        // 對商品名稱進行模糊匹配（權重最高）
        final nameFuzzyScore = FuzzySearchHelper.calculateFuzzyScore(
          searchKeyword,
          name,
        );

        // 對描述進行模糊匹配（權重中等）
        final descriptionFuzzyScore = FuzzySearchHelper.calculateFuzzyScore(
          searchKeyword,
          description,
        );

        // 對店家名稱進行模糊匹配（權重較低）
        final storeNameFuzzyScore = FuzzySearchHelper.calculateFuzzyScore(
          searchKeyword,
          storeName,
        );

        // 取最高的模糊匹配分數，並根據來源調整權重
        if (nameFuzzyScore > 0) {
          // 商品名稱模糊匹配：20-35分
          score = 20.0 + (nameFuzzyScore * 0.15);
        } else if (descriptionFuzzyScore > 0) {
          // 描述模糊匹配：10-25分
          score = 10.0 + (descriptionFuzzyScore * 0.15);
        } else if (storeNameFuzzyScore > 0) {
          // 店家名稱模糊匹配：5-15分
          score = 5.0 + (storeNameFuzzyScore * 0.10);
        }
      }

      return MapEntry(product, score);
    }).where((entry) => entry.value > 0).toList();

    // 按分數排序（高到低），分數相同則按商品評分排序
    scoredProducts.sort((a, b) {
      final scoreCompare = b.value.compareTo(a.value);
      if (scoreCompare != 0) return scoreCompare;

      // 分數相同時，優先顯示評分較高的商品
      return b.key.averageRating.compareTo(a.key.averageRating);
    });

    if (kDebugMode) {
      print('🔍 [DatabaseService] 找到 ${scoredProducts.length} 筆符合的商品');
      if (scoredProducts.isNotEmpty) {
        print('🔍 [DatabaseService] 前 5 筆結果（含分數）:');
        for (var i = 0; i < scoredProducts.length && i < 5; i++) {
          final entry = scoredProducts[i];
          final storeName = storesMap[entry.key.storeId]?.name ?? '未知';
          print('   ${i + 1}. ${entry.key.name} (分數: ${entry.value.toStringAsFixed(1)}, 店家: $storeName)');
        }
      }
    }

    // 返回排序後的商品列表
    return scoredProducts.map((entry) => entry.key).toList();
  }

  // ==================== 購物車相關方法 ====================

  /// 取得所有購物車項目
  Future<List<CartItem>> getCartItems() async {
    try {
      final isar = await _isarFuture;
      // 取得所有購物車項目
      final items = await isar.cartItems.where().findAll();

      // 過濾掉無效的項目（缺少必要欄位）
      final validItems = <CartItem>[];
      final invalidIds = <int>[];

      for (var item in items) {
        try {
          // 檢查必要欄位是否存在且有效
          if (item.storeId > 0 && item.storeName.isNotEmpty) {
            validItems.add(item);
          } else {
            invalidIds.add(item.id);
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ [DatabaseService] 發現無效的購物車項目 ID ${item.id}: $e');
          }
          invalidIds.add(item.id);
        }
      }

      // 如果有無效項目，清理資料庫
      if (invalidIds.isNotEmpty) {
        if (kDebugMode) {
          print('⚠️ [DatabaseService] 發現 ${invalidIds.length} 個無效項目，正在清理...');
        }
        await _cleanInvalidCartItems(invalidIds);
      }

      // 按 ID 降序排序，新加入的商品顯示在前面
      validItems.sort((a, b) => b.id.compareTo(a.id));
      return validItems;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [DatabaseService] 讀取購物車失敗: $e');
        print('   建議清空購物車並重試');
      }
      return [];
    }
  }

  /// 清理無效的購物車項目
  Future<void> _cleanInvalidCartItems(List<int> invalidIds) async {
    try {
      final isar = await _isarFuture;

      await isar.writeTxn(() async {
        for (var id in invalidIds) {
          await isar.cartItems.delete(id);
          if (kDebugMode) {
            print('🗑️ [DatabaseService] 已刪除無效項目 ID: $id');
          }
        }
      });

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [DatabaseService] 清理無效項目失敗: $e');
      }
    }
  }

  /// 加入商品到購物車
  /// 如果相同商品+規格已存在，則增加數量；否則新增項目
  Future<void> addToCart({
    required int productId,
    required String productName,
    required double price,
    required String specification,
    required int storeId,
    required String storeName,
    int quantity = 1,
  }) async {
    final isar = await _isarFuture;

    // 檢查是否已有相同商品+規格的項目
    final allItems = await isar.cartItems.where().findAll();
    CartItem? existingItem;

    try {
      existingItem = allItems.firstWhere(
        (item) => item.productId == productId && item.specification == specification,
      );
    } catch (e) {
      existingItem = null;
    }

    await isar.writeTxn(() async {
      if (existingItem != null) {
        // 更新數量
        existingItem.quantity += quantity;
        await isar.cartItems.put(existingItem);
        if (kDebugMode) {
          print('🛒 [DatabaseService] 更新購物車項目: ${existingItem.name}, 新數量: ${existingItem.quantity}');
        }
      } else {
        // 新增項目
        final newItem = CartItem()
          ..productId = productId
          ..storeId = storeId
          ..storeName = storeName
          ..name = productName
          ..specification = specification
          ..unitPrice = price
          ..quantity = quantity
          ..isSelected = true; // 預設為選取狀態

        await isar.cartItems.put(newItem);
        if (kDebugMode) {
          print('🛒 [DatabaseService] 新增購物車項目: $productName ($specification) x$quantity, 商家: $storeName');
        }
      }
    });

    notifyListeners();
  }

  /// 更新購物車項目的數量
  Future<void> updateCartItemQuantity(int cartItemId, int newQuantity) async {
    if (newQuantity < 1) return;

    final isar = await _isarFuture;
    final item = await isar.cartItems.get(cartItemId);

    if (item != null) {
      await isar.writeTxn(() async {
        item.quantity = newQuantity;
        await isar.cartItems.put(item);
      });

      if (kDebugMode) {
        print('🛒 [DatabaseService] 更新購物車項目數量: ${item.name}, 新數量: $newQuantity');
      }

      notifyListeners();
    }
  }

  /// 切換購物車項目的選取狀態
  Future<void> toggleCartItemSelection(int cartItemId) async {
    final isar = await _isarFuture;
    final item = await isar.cartItems.get(cartItemId);

    if (item != null) {
      await isar.writeTxn(() async {
        item.isSelected = !item.isSelected;
        await isar.cartItems.put(item);
      });

      if (kDebugMode) {
        print('🛒 [DatabaseService] 切換購物車項目選取狀態: ${item.name}, 選取: ${item.isSelected}');
      }

      notifyListeners();
    }
  }

  /// 清除所有購物車項目的選取狀態
  Future<void> clearAllCartItemSelections() async {
    final isar = await _isarFuture;
    final allItems = await isar.cartItems.where().findAll();

    await isar.writeTxn(() async {
      for (var item in allItems) {
        item.isSelected = false;
        await isar.cartItems.put(item);
      }
    });

    if (kDebugMode) {
      print('🛒 [DatabaseService] 已清除所有購物車項目的選取狀態 (${allItems.length} 項)');
    }

    notifyListeners();
  }

  /// 從購物車移除項目
  Future<void> removeFromCart(int cartItemId) async {
    final isar = await _isarFuture;

    await isar.writeTxn(() async {
      final deleted = await isar.cartItems.delete(cartItemId);
      if (kDebugMode) {
        print('🛒 [DatabaseService] 從購物車移除項目, 成功: $deleted');
      }
    });

    notifyListeners();
  }

  /// 清空購物車
  Future<void> clearCart() async {
    final isar = await _isarFuture;

    await isar.writeTxn(() async {
      await isar.cartItems.clear();
      if (kDebugMode) {
        print('🛒 [DatabaseService] 已清空購物車');
      }
    });

    notifyListeners();
  }

  // ==================== 訂單相關方法 ====================

  /// 生成訂單編號（格式：YYYYMMDD-序號）
  Future<String> generateOrderNumber() async {
    final isar = await _isarFuture;
    final now = DateTime.now();
    final datePrefix = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // 查詢今天已有的訂單數量
    final todayOrders = await isar.orders
        .filter()
        .orderNumberStartsWith(datePrefix)
        .findAll();

    final sequence = (todayOrders.length + 1).toString().padLeft(4, '0');
    return '$datePrefix-$sequence';
  }

  /// 建立訂單
  /// 從購物車選取項目和結帳選項建立訂單
  /// isCashOnDelivery: true 表示貨到付款，false 表示線上付款
  Future<Order> createOrder({
    required List<CartItem> cartItems,
    int? couponId,
    String? couponName,
    double discount = 0.0,
    required int shippingMethodId,
    required String shippingMethodName,
    required double shippingFee,
    required int paymentMethodId,
    required String paymentMethodName,
    required bool isCashOnDelivery,
    String? deliveryType, // 'convenience_store' 或 'home_delivery'
  }) async {
    final isar = await _isarFuture;

    // 計算金額
    final subtotal = cartItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );
    final total = subtotal - discount + shippingFee;

    // 生成訂單編號
    final orderNumber = await generateOrderNumber();

    // 根據付款方式設定訂單狀態
    // 貨到付款：待付款
    // 線上付款：待出貨（假設已完成付款）
    final OrderMainStatus initialStatus = isCashOnDelivery
        ? OrderMainStatus.pendingPayment
        : OrderMainStatus.pendingShipment;

    // 取得商家資訊（假設購物車商品都來自同一個商家）
    final storeId = cartItems.isNotEmpty ? cartItems.first.storeId : 0;
    final storeName = cartItems.isNotEmpty ? cartItems.first.storeName : '未知商家';

    // 建立訂單
    final order = Order()
      ..orderNumber = orderNumber
      ..storeId = storeId
      ..storeName = storeName
      ..createdAt = DateTime.now()
      ..status = 'pending' // 舊版狀態，保留兼容性
      ..mainStatus = initialStatus
      ..logisticsStatus = LogisticsStatus.none
      ..subtotal = subtotal
      ..discount = discount
      ..shippingFee = shippingFee
      ..total = total
      ..couponId = couponId
      ..couponName = couponName
      ..shippingMethodId = shippingMethodId
      ..shippingMethodName = shippingMethodName
      ..paymentMethodId = paymentMethodId
      ..paymentMethodName = paymentMethodName
      ..deliveryType = deliveryType;

    await isar.writeTxn(() async {
      // 儲存訂單
      await isar.orders.put(order);

      // 建立訂單項目
      for (var cartItem in cartItems) {
        final orderItem = OrderItem()
          ..orderId = order.id
          ..productId = cartItem.productId
          ..productName = cartItem.name
          ..specification = cartItem.specification
          ..unitPrice = cartItem.unitPrice
          ..quantity = cartItem.quantity
          ..subtotal = cartItem.unitPrice * cartItem.quantity;

        await isar.orderItems.put(orderItem);
      }

      if (kDebugMode) {
        print('📦 [DatabaseService] 建立訂單: $orderNumber, 共 ${cartItems.length} 項商品, 總金額: \$${total.toStringAsFixed(0)}, 狀態: ${initialStatus.name}');
      }
    });

    // 創建訂單狀態時間戳記錄（在創建歷史記錄之前）
    final now = DateTime.now();
    final timestamps = OrderStatusTimestamps()
      ..orderId = order.id
      ..createdAt = now;

    // 根據付款方式設定對應的時間戳
    if (isCashOnDelivery) {
      timestamps.pendingPaymentAt = now;
    } else {
      timestamps.paidAt = now;
      timestamps.pendingShipmentAt = now;
    }

    await isar.writeTxn(() async {
      await isar.orderStatusTimestamps.put(timestamps);
    });

    // 創建訂單狀態歷史記錄
    final history = OrderStatusHistory()
      ..orderId = order.id
      ..mainStatus = initialStatus
      ..logisticsStatus = LogisticsStatus.none
      ..description = isCashOnDelivery ? '訂單成立（貨到付款）' : '訂單成立（線上付款已完成）'
      ..timestamp = now;

    await isar.writeTxn(() async {
      await isar.orderStatusHistorys.put(history);
    });

    // 創建訂單成立通知
    await createOrderNotification(
      title: '訂單成立',
      content: '您的訂單 #$orderNumber 已成立，總金額 \$${total.toStringAsFixed(0)} 元',
      orderId: order.id,
      orderNumber: orderNumber,
    );

    notifyListeners();
    return order;
  }

  /// 按商家分組建立訂單
  /// 將購物車商品按商家分組，為每個商家創建獨立訂單
  /// 返回所有創建的訂單列表
  Future<List<Order>> createOrdersByStore({
    required List<CartItem> cartItems,
    int? couponId,
    String? couponName,
    double discount = 0.0,
    required int shippingMethodId,
    required String shippingMethodName,
    required double shippingFee,
    required int paymentMethodId,
    required String paymentMethodName,
    required bool isCashOnDelivery,
    String? deliveryType,
  }) async {
    // 按商家 ID 分組購物車項目
    final Map<int, List<CartItem>> itemsByStore = {};
    for (var item in cartItems) {
      if (!itemsByStore.containsKey(item.storeId)) {
        itemsByStore[item.storeId] = [];
      }
      itemsByStore[item.storeId]!.add(item);
    }

    if (kDebugMode) {
      print('📦 [DatabaseService] 購物車商品分組: 共 ${itemsByStore.length} 個商家');
      for (var entry in itemsByStore.entries) {
        final storeName = entry.value.first.storeName;
        print('   - 商家 $storeName (ID: ${entry.key}): ${entry.value.length} 項商品');
      }
    }

    // 計算每個商家應分攤的優惠和運費
    final totalSubtotal = cartItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );

    final List<Order> createdOrders = [];

    // 為每個商家創建訂單
    for (var entry in itemsByStore.entries) {
      final storeItems = entry.value;
      final storeSubtotal = storeItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.unitPrice * item.quantity),
      );

      // 按商品金額比例分攤優惠券折扣
      final storeDiscount = totalSubtotal > 0
          ? (discount * storeSubtotal / totalSubtotal)
          : 0.0;

      // 按商品金額比例分攤運費
      final storeShippingFee = totalSubtotal > 0
          ? (shippingFee * storeSubtotal / totalSubtotal)
          : 0.0;

      // 為該商家創建訂單
      final order = await createOrder(
        cartItems: storeItems,
        couponId: couponId,
        couponName: couponName,
        discount: storeDiscount,
        shippingMethodId: shippingMethodId,
        shippingMethodName: shippingMethodName,
        shippingFee: storeShippingFee,
        paymentMethodId: paymentMethodId,
        paymentMethodName: paymentMethodName,
        isCashOnDelivery: isCashOnDelivery,
        deliveryType: deliveryType,
      );

      createdOrders.add(order);
    }

    if (kDebugMode) {
      print('✅ [DatabaseService] 成功創建 ${createdOrders.length} 個訂單');
    }

    return createdOrders;
  }

  /// 取得所有訂單（按時間倒序）
  Future<List<Order>> getOrders() async {
    final isar = await _isarFuture;
    return await isar.orders
        .where()
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// 查詢單筆訂單
  Future<Order?> getOrderById(int orderId) async {
    final isar = await _isarFuture;
    return await isar.orders.get(orderId);
  }

  /// 取得訂單的所有項目
  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final isar = await _isarFuture;
    return await isar.orderItems
        .filter()
        .orderIdEqualTo(orderId)
        .findAll();
  }

  /// 更新訂單狀態
  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    final isar = await _isarFuture;
    final order = await isar.orders.get(orderId);

    if (order != null) {
      await isar.writeTxn(() async {
        order.status = newStatus;
        await isar.orders.put(order);
      });

      if (kDebugMode) {
        print('📦 [DatabaseService] 更新訂單狀態: ${order.orderNumber}, 新狀態: $newStatus');
      }

      notifyListeners();
    }
  }

  /// 結帳後清除購物車中已選取的項目
  Future<void> clearSelectedCartItems() async {
    final isar = await _isarFuture;
    final selectedItems = await isar.cartItems
        .filter()
        .isSelectedEqualTo(true)
        .findAll();

    await isar.writeTxn(() async {
      for (var item in selectedItems) {
        await isar.cartItems.delete(item.id);
      }

      if (kDebugMode) {
        print('🛒 [DatabaseService] 已清除 ${selectedItems.length} 個已結帳的購物車項目');
      }
    });

    notifyListeners();
  }

  // ==================== 使用者資料相關方法 ====================

  /// 取得使用者資料（根據 Firebase Auth UID）
  Future<UserProfile?> getUserProfile(String userId) async {
    final isar = await _isarFuture;
    return await isar.userProfiles
        .filter()
        .userIdEqualTo(userId)
        .findFirst();
  }

  /// 建立或更新使用者資料
  Future<UserProfile> saveUserProfile({
    required String userId,
    String? displayName,
    String? email,
    DateTime? birthday,
    String? phoneNumber,
  }) async {
    final isar = await _isarFuture;

    // 先查詢是否已存在
    var profile = await getUserProfile(userId);

    if (profile == null) {
      // 建立新資料
      profile = UserProfile()
        ..userId = userId
        ..email = email
        ..displayName = displayName
        ..birthday = birthday
        ..phoneNumber = phoneNumber
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..membershipLevel = 'regular'
        ..membershipPoints = 0
        ..walletBalance = 0.0;

      if (kDebugMode) {
        print('👤 [DatabaseService] 建立使用者資料: $userId');
      }
    } else {
      // 更新現有資料
      profile.email = email ?? profile.email;
      profile.displayName = displayName ?? profile.displayName;
      profile.birthday = birthday ?? profile.birthday;
      profile.phoneNumber = phoneNumber ?? profile.phoneNumber;
      profile.updatedAt = DateTime.now();

      if (kDebugMode) {
        print('👤 [DatabaseService] 更新使用者資料: $userId');
      }
    }

    await isar.writeTxn(() async {
      await isar.userProfiles.put(profile!);
    });

    notifyListeners();
    return profile;
  }

  /// 更新使用者名稱
  Future<void> updateDisplayName(String userId, String displayName) async {
    final profile = await getUserProfile(userId);
    if (profile != null) {
      await saveUserProfile(
        userId: userId,
        displayName: displayName,
        email: profile.email,
        birthday: profile.birthday,
        phoneNumber: profile.phoneNumber,
      );
    }
  }

  /// 更新生日
  Future<void> updateBirthday(String userId, DateTime birthday) async {
    final profile = await getUserProfile(userId);
    if (profile != null) {
      await saveUserProfile(
        userId: userId,
        displayName: profile.displayName,
        email: profile.email,
        birthday: birthday,
        phoneNumber: profile.phoneNumber,
      );
    }
  }

  /// 更新手機號碼
  Future<void> updatePhoneNumber(String userId, String phoneNumber) async {
    final profile = await getUserProfile(userId);
    if (profile != null) {
      await saveUserProfile(
        userId: userId,
        displayName: profile.displayName,
        email: profile.email,
        birthday: profile.birthday,
        phoneNumber: phoneNumber,
      );
    }
  }

  // ==================== 錢包相關方法 ====================

  /// 領取每日登入獎勵
  /// 回傳值：獎勵金額（0 表示今天已領取過）
  Future<double> claimDailyReward(String userId) async {
    final isar = await _isarFuture;
    var profile = await getUserProfile(userId);

    if (profile == null) {
      if (kDebugMode) {
        print('💰 [DatabaseService] 找不到使用者資料: $userId');
      }
      return 0.0;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 檢查今天是否已經領取過
    if (profile.lastDailyRewardDate != null) {
      final lastRewardDate = DateTime(
        profile.lastDailyRewardDate!.year,
        profile.lastDailyRewardDate!.month,
        profile.lastDailyRewardDate!.day,
      );

      if (lastRewardDate.isAtSameMomentAs(today)) {
        if (kDebugMode) {
          print('💰 [DatabaseService] 今天已經領取過每日獎勵');
        }
        return 0.0;
      }
    }

    // 每日獎勵金額
    const double dailyReward = 1.0;

    // 更新錢包餘額和領取日期
    await isar.writeTxn(() async {
      profile.walletBalance = (profile.walletBalance ?? 0.0) + dailyReward;
      profile.lastDailyRewardDate = now;
      profile.updatedAt = now;
      await isar.userProfiles.put(profile);
    });

    if (kDebugMode) {
      print('💰 [DatabaseService] 領取每日獎勵成功: +$dailyReward 元，當前餘額: ${profile.walletBalance}');
    }

    notifyListeners();
    return dailyReward;
  }

  /// 檢查今天是否已領取每日獎勵
  Future<bool> hasClaimedDailyReward(String userId) async {
    var profile = await getUserProfile(userId);

    if (profile == null || profile.lastDailyRewardDate == null) {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastRewardDate = DateTime(
      profile.lastDailyRewardDate!.year,
      profile.lastDailyRewardDate!.month,
      profile.lastDailyRewardDate!.day,
    );

    return lastRewardDate.isAtSameMomentAs(today);
  }

  /// 取得錢包餘額
  Future<double> getWalletBalance(String userId) async {
    var profile = await getUserProfile(userId);
    return profile?.walletBalance ?? 0.0;
  }

  /// 使用錢包餘額（扣款）
  /// 回傳值：是否成功
  Future<bool> useWalletBalance(String userId, double amount) async {
    if (amount <= 0) {
      if (kDebugMode) {
        print('💰 [DatabaseService] 扣款金額必須大於 0');
      }
      return false;
    }

    final isar = await _isarFuture;
    var profile = await getUserProfile(userId);

    if (profile == null) {
      if (kDebugMode) {
        print('💰 [DatabaseService] 找不到使用者資料: $userId');
      }
      return false;
    }

    final currentBalance = profile.walletBalance ?? 0.0;

    if (currentBalance < amount) {
      if (kDebugMode) {
        print('💰 [DatabaseService] 錢包餘額不足: 當前 $currentBalance，需要 $amount');
      }
      return false;
    }

    // 扣除餘額
    await isar.writeTxn(() async {
      profile.walletBalance = currentBalance - amount;
      profile.updatedAt = DateTime.now();
      await isar.userProfiles.put(profile);
    });

    if (kDebugMode) {
      print('💰 [DatabaseService] 使用錢包餘額成功: -$amount 元，剩餘餘額: ${profile.walletBalance}');
    }

    notifyListeners();
    return true;
  }

  /// 重置錢包餘額（開發工具用）
  Future<void> resetWalletBalance(String userId) async {
    final isar = await _isarFuture;
    var profile = await getUserProfile(userId);

    if (profile != null) {
      await isar.writeTxn(() async {
        profile.walletBalance = 0.0;
        profile.lastDailyRewardDate = null;
        profile.updatedAt = DateTime.now();
        await isar.userProfiles.put(profile);
      });

      if (kDebugMode) {
        print('💰 [DatabaseService] 已重置錢包餘額');
      }

      notifyListeners();
    }
  }

  // ==================== 通知相關方法 ====================

  /// 創建通知
  Future<NotificationModel> createNotification({
    required String title,
    required String content,
    required NotificationType type,
    int? orderId,
    String? orderNumber,
  }) async {
    final isar = await _isarFuture;

    final notification = NotificationModel()
      ..title = title
      ..content = content
      ..type = type
      ..timestamp = DateTime.now()
      ..isRead = false
      ..orderId = orderId
      ..orderNumber = orderNumber;

    await isar.writeTxn(() async {
      await isar.notificationModels.put(notification);

      if (kDebugMode) {
        print('🔔 [DatabaseService] 創建通知: $title');
      }
    });

    // 同步發送手機通知
    await notificationService.showNotification(
      id: notification.id,
      title: title,
      body: content,
      type: type,
      payload: orderId != null ? 'order_$orderId' : null,
    );

    notifyListeners();
    return notification;
  }

  /// 創建訂單通知
  Future<NotificationModel> createOrderNotification({
    required String title,
    required String content,
    required int orderId,
    required String orderNumber,
  }) async {
    return await createNotification(
      title: title,
      content: content,
      type: NotificationType.order,
      orderId: orderId,
      orderNumber: orderNumber,
    );
  }

  /// 獲取所有通知（按時間倒序）
  Future<List<NotificationModel>> getNotifications() async {
    final isar = await _isarFuture;
    return await isar.notificationModels
        .where()
        .sortByTimestampDesc()
        .findAll();
  }

  /// 獲取未讀通知數量
  Future<int> getUnreadNotificationCount() async {
    final isar = await _isarFuture;
    return await isar.notificationModels
        .filter()
        .isReadEqualTo(false)
        .count();
  }

  /// 標記通知為已讀
  Future<void> markNotificationAsRead(int notificationId) async {
    final isar = await _isarFuture;
    final notification = await isar.notificationModels.get(notificationId);

    if (notification != null && !notification.isRead) {
      await isar.writeTxn(() async {
        notification.isRead = true;
        await isar.notificationModels.put(notification);
      });

      notifyListeners();

      if (kDebugMode) {
        print('🔔 [DatabaseService] 通知已標記為已讀: ${notification.title}');
      }
    }
  }

  /// 切換通知已讀狀態
  Future<void> toggleNotificationReadStatus(int notificationId) async {
    final isar = await _isarFuture;
    final notification = await isar.notificationModels.get(notificationId);

    if (notification != null) {
      await isar.writeTxn(() async {
        notification.isRead = !notification.isRead;
        await isar.notificationModels.put(notification);
      });

      notifyListeners();

      if (kDebugMode) {
        print('🔔 [DatabaseService] 通知狀態切換: ${notification.title} -> ${notification.isRead ? "已讀" : "未讀"}');
      }
    }
  }

  /// 標記所有通知為已讀
  Future<void> markAllNotificationsAsRead() async {
    final isar = await _isarFuture;
    final unreadNotifications = await isar.notificationModels
        .filter()
        .isReadEqualTo(false)
        .findAll();

    if (unreadNotifications.isNotEmpty) {
      await isar.writeTxn(() async {
        for (var notification in unreadNotifications) {
          notification.isRead = true;
          await isar.notificationModels.put(notification);
        }
      });

      notifyListeners();

      if (kDebugMode) {
        print('🔔 [DatabaseService] 所有通知已標記為已讀 (${unreadNotifications.length} 則)');
      }
    }
  }

  /// 刪除通知
  Future<void> deleteNotification(int notificationId) async {
    final isar = await _isarFuture;

    await isar.writeTxn(() async {
      await isar.notificationModels.delete(notificationId);
    });

    notifyListeners();

    if (kDebugMode) {
      print('🔔 [DatabaseService] 通知已刪除: ID=$notificationId');
    }
  }

  /// 清除所有已讀通知
  Future<void> clearReadNotifications() async {
    final isar = await _isarFuture;
    final readNotifications = await isar.notificationModels
        .filter()
        .isReadEqualTo(true)
        .findAll();

    if (readNotifications.isNotEmpty) {
      await isar.writeTxn(() async {
        for (var notification in readNotifications) {
          await isar.notificationModels.delete(notification.id);
        }
      });

      notifyListeners();

      if (kDebugMode) {
        print('🔔 [DatabaseService] 已清除所有已讀通知 (${readNotifications.length} 則)');
      }
    }
  }

  // ==================== 商品評論相關方法 ====================

  /// 取得商品的所有評論（按時間倒序）
  Future<List<ProductReview>> getProductReviews(int productId) async {
    final isar = await _isarFuture;
    return await isar.productReviews
        .filter()
        .productIdEqualTo(productId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// 新增商品評論
  Future<void> addProductReview({
    required int productId,
    required String userName,
    required double rating,
    required String comment,
    String? userAvatar,
    int orderId = 0,  // 默認 0 表示不關聯訂單的評論
  }) async {
    final isar = await _isarFuture;

    final review = ProductReview()
      ..productId = productId
      ..orderId = orderId
      ..userName = userName
      ..rating = rating
      ..comment = comment
      ..userAvatar = userAvatar
      ..createdAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.productReviews.put(review);
    });

    // 更新商品的平均評分和評論數量
    await _updateProductRating(productId);

    if (kDebugMode) {
      print('⭐ [DatabaseService] 新增評論: $userName 對商品 $productId 評分 $rating 分');
    }

    notifyListeners();
  }

  /// 更新商品的平均評分和評論數量
  Future<void> _updateProductRating(int productId) async {
    final isar = await _isarFuture;
    final product = await isar.products.get(productId);

    if (product != null) {
      final reviews = await getProductReviews(productId);

      if (reviews.isNotEmpty) {
        final totalRating = reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
        final averageRating = totalRating / reviews.length;

        await isar.writeTxn(() async {
          product.averageRating = averageRating;
          product.reviewCount = reviews.length;
          await isar.products.put(product);
        });

        if (kDebugMode) {
          print('⭐ [DatabaseService] 更新商品 $productId 評分: ${averageRating.toStringAsFixed(1)} (${reviews.length} 則評論)');
        }
      }
    }
  }

  // ==================== 對話相關方法 ====================

  /// 取得所有對話對象（按最後訊息時間倒序）
  Future<List<Conversation>> getConversations() async {
    final isar = await _isarFuture;
    final conversations = await isar.conversations.where().findAll();

    // 按最後訊息時間排序（最新的在前）
    conversations.sort((a, b) {
      if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
      if (a.lastMessageTime == null) return 1;
      if (b.lastMessageTime == null) return -1;
      return b.lastMessageTime!.compareTo(a.lastMessageTime!);
    });

    return conversations;
  }

  /// 取得單個對話對象
  Future<Conversation?> getConversationById(int conversationId) async {
    final isar = await _isarFuture;
    return await isar.conversations.get(conversationId);
  }

  /// 初始化默認的"小千助手"對話對象
  Future<Conversation> initializeDefaultConversation() async {
    final isar = await _isarFuture;

    // 檢查是否已存在小千助手
    final existing = await isar.conversations
        .filter()
        .nameEqualTo('小千助手')
        .findFirst();

    if (existing != null) {
      return existing;
    }

    // 創建小千助手對話對象
    final conversation = Conversation()
      ..name = '小千助手'
      ..type = ConversationType.platform
      ..avatarEmoji = '🤖'
      ..unreadCount = 0;

    await isar.writeTxn(() async {
      await isar.conversations.put(conversation);
    });

    if (kDebugMode) {
      print('💬 [DatabaseService] 創建默認對話: 小千助手');
    }

    notifyListeners();
    return conversation;
  }

  /// 更新對話的最後訊息信息
  Future<void> updateConversationLastMessage({
    required int conversationId,
    required String lastMessage,
    required DateTime lastMessageTime,
  }) async {
    final isar = await _isarFuture;
    final conversation = await isar.conversations.get(conversationId);

    if (conversation != null) {
      await isar.writeTxn(() async {
        conversation.lastMessage = lastMessage;
        conversation.lastMessageTime = lastMessageTime;
        await isar.conversations.put(conversation);
      });

      notifyListeners();
    }
  }

  /// 增加對話的未讀數量
  Future<void> incrementUnreadCount(int conversationId) async {
    final isar = await _isarFuture;
    final conversation = await isar.conversations.get(conversationId);

    if (conversation != null) {
      await isar.writeTxn(() async {
        conversation.unreadCount += 1;
        await isar.conversations.put(conversation);
      });

      notifyListeners();
    }
  }

  /// 清除對話的未讀數量
  Future<void> clearUnreadCount(int conversationId) async {
    final isar = await _isarFuture;
    final conversation = await isar.conversations.get(conversationId);

    if (conversation != null) {
      await isar.writeTxn(() async {
        conversation.unreadCount = 0;
        await isar.conversations.put(conversation);
      });

      notifyListeners();
    }
  }

  // ==================== 聊天訊息相關方法 ====================

  /// 取得某個對話的所有訊息（按時間順序）
  Future<List<ChatMessage>> getChatMessages(int conversationId) async {
    final isar = await _isarFuture;
    return await isar.chatMessages
        .filter()
        .conversationIdEqualTo(conversationId)
        .sortByTimestamp()
        .findAll();
  }

  /// 添加聊天訊息
  Future<ChatMessage> addChatMessage({
    required int conversationId,
    required String content,
    required bool isUserMessage,
  }) async {
    final isar = await _isarFuture;
    final now = DateTime.now();

    final message = ChatMessage()
      ..conversationId = conversationId
      ..content = content
      ..isUserMessage = isUserMessage
      ..timestamp = now;

    await isar.writeTxn(() async {
      await isar.chatMessages.put(message);
    });

    // 更新對話的最後訊息
    await updateConversationLastMessage(
      conversationId: conversationId,
      lastMessage: content.length > 30 ? '${content.substring(0, 30)}...' : content,
      lastMessageTime: now,
    );

    if (kDebugMode) {
      print('💬 [DatabaseService] 添加訊息: ${isUserMessage ? "用戶" : "AI"} - ${content.length > 20 ? "${content.substring(0, 20)}..." : content}');
    }

    notifyListeners();
    return message;
  }

  /// 清空某個對話的所有訊息
  Future<void> clearChatMessages(int conversationId) async {
    final isar = await _isarFuture;
    final messages = await isar.chatMessages
        .filter()
        .conversationIdEqualTo(conversationId)
        .findAll();

    if (messages.isNotEmpty) {
      await isar.writeTxn(() async {
        for (var message in messages) {
          await isar.chatMessages.delete(message.id);
        }
      });

      // 清空對話的最後訊息信息
      final conversation = await isar.conversations.get(conversationId);
      if (conversation != null) {
        await isar.writeTxn(() async {
          conversation.lastMessage = null;
          conversation.lastMessageTime = null;
          conversation.unreadCount = 0;
          await isar.conversations.put(conversation);
        });
      }

      if (kDebugMode) {
        print('💬 [DatabaseService] 已清空對話 $conversationId 的所有訊息 (${messages.length} 則)');
      }

      notifyListeners();
    }
  }

  // 這裡還可以擴充其他 CRUD 方法...
}
