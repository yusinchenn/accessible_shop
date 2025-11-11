/// product_comparison_service.dart
/// 使用 DeepSeek API 進行商品智能比較服務
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/store.dart';
import '../models/product_review.dart';
import '../services/database_service.dart';
import '../services/openai_client.dart';

/// 商品詳細資訊（用於 AI 比較）
class ProductDetail {
  final CartItem cartItem;
  final Product? product;
  final Store? store;
  final List<ProductReview> reviews;

  ProductDetail({
    required this.cartItem,
    this.product,
    this.store,
    this.reviews = const [],
  });
}

/// 商品比較服務
class ProductComparisonService {
  final DatabaseService _databaseService;
  late final OpenAICompatibleClient _aiClient;

  ProductComparisonService(this._databaseService) {
    // 從環境變數讀取 API Key
    final apiKey = dotenv.env['DEEPSEEK_API_KEY'] ?? '';

    if (apiKey.isEmpty || apiKey == 'your_deepseek_api_key_here') {
      if (kDebugMode) {
        print('⚠️ [ProductComparisonService] DeepSeek API Key 未設置或無效');
      }
    }

    // 初始化 DeepSeek API 客戶端
    final config = ProviderConfig(
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com',
      apiKey: apiKey,
      defaultModel: 'deepseek-chat',
    );

    _aiClient = OpenAICompatibleClient(config);
  }

  /// 收集商品的詳細資訊
  Future<ProductDetail> _fetchProductDetail(CartItem cartItem) async {
    try {
      // 獲取商品資訊
      final product = await _databaseService.getProductById(cartItem.productId);

      // 獲取商家資訊
      Store? store;
      if (product != null) {
        store = await _databaseService.getStoreById(product.storeId);
      }

      // 獲取評論（最多取前 5 則）
      final reviews = await _databaseService.getProductReviews(cartItem.productId);
      final topReviews = reviews.take(5).toList();

      return ProductDetail(
        cartItem: cartItem,
        product: product,
        store: store,
        reviews: topReviews,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ProductComparisonService] 獲取商品詳情失敗: $e');
      }
      return ProductDetail(cartItem: cartItem);
    }
  }

  /// 將商品詳情轉換為文字描述（供 AI 分析）
  String _formatProductInfo(ProductDetail detail, int index) {
    final buffer = StringBuffer();

    buffer.writeln('【商品 ${index + 1}】');
    buffer.writeln('商品名稱：${detail.cartItem.name}');
    buffer.writeln('規格：${detail.cartItem.specification}');
    buffer.writeln('單價：${detail.cartItem.unitPrice.toStringAsFixed(0)} 元');

    if (detail.product != null) {
      final product = detail.product!;
      if (product.category != null && product.category!.isNotEmpty) {
        buffer.writeln('分類：${product.category}');
      }
      if (product.description != null && product.description!.isNotEmpty) {
        buffer.writeln('描述：${product.description}');
      }
      buffer.writeln('庫存：${product.stock} 件');
      buffer.writeln('平均評分：${product.averageRating.toStringAsFixed(1)} 星（${product.reviewCount} 則評論）');
    }

    if (detail.store != null) {
      final store = detail.store!;
      buffer.writeln('商家：${store.name}');
      buffer.writeln('商家評分：${store.rating.toStringAsFixed(1)} 星');
      buffer.writeln('商家粉絲：${store.followersCount} 人');
      if (store.description != null && store.description!.isNotEmpty) {
        buffer.writeln('商家簡介：${store.description}');
      }
    }

    if (detail.reviews.isNotEmpty) {
      buffer.writeln('用戶評論摘要（前 ${detail.reviews.length} 則）：');
      for (var i = 0; i < detail.reviews.length; i++) {
        final review = detail.reviews[i];
        buffer.writeln('  ${i + 1}. ${review.userName}（${review.rating} 星）：${review.comment}');
      }
    }

    buffer.writeln(''); // 空行分隔
    return buffer.toString();
  }

  /// 使用 AI 比較商品
  ///
  /// [items] 要比較的購物車商品列表
  /// 回傳 AI 生成的比較結果文字
  Future<String> compareProducts(List<CartItem> items) async {
    if (items.isEmpty) {
      return '沒有商品可比較';
    }

    if (items.length == 1) {
      return '需要至少兩個商品才能進行比較';
    }

    try {
      // 1. 收集所有商品的詳細資訊
      if (kDebugMode) {
        print('🔍 [ProductComparisonService] 開始收集 ${items.length} 個商品的詳細資訊...');
      }

      final productDetails = <ProductDetail>[];
      for (var item in items) {
        final detail = await _fetchProductDetail(item);
        productDetails.add(detail);
      }

      // 2. 組織商品資訊文字
      final buffer = StringBuffer();
      buffer.writeln('以下是要比較的商品資訊：\n');

      for (var i = 0; i < productDetails.length; i++) {
        buffer.write(_formatProductInfo(productDetails[i], i));
      }

      final productsInfo = buffer.toString();

      // 3. 建立 AI 提示詞
      final systemPrompt = '''你是一個專業的購物助手，擅長分析和比較商品。
請用清晰、簡潔、易於朗讀的中文為視障使用者進行商品比較分析。

比較時請注意以下要點：
1. 重點突出價格差異和性價比
2. 分析商品評分和評論的差異
3. 比較商家的信譽和服務
4. 指出各商品的優缺點
5. 根據不同需求給出推薦建議
6. 使用口語化的表達方式，適合語音朗讀

請將比較結果組織成以下結構：
- 【價格比較】
- 【評分與評論】
- 【商家信譽】
- 【商品特色】
- 【購買建議】

每個部分請保持簡潔，總字數控制在 500 字以內。''';

      final userPrompt = productsInfo;

      // 4. 調用 DeepSeek API
      if (kDebugMode) {
        print('🤖 [ProductComparisonService] 正在調用 DeepSeek API 進行比較...');
      }

      final options = ChatCompletionOptions(
        messages: [
          ChatMessage(role: Role.system, content: systemPrompt),
          ChatMessage(role: Role.user, content: userPrompt),
        ],
        temperature: 0.7,
        maxTokens: 1500,
      );

      final result = await _aiClient.chatCompletionText(options);

      if (kDebugMode) {
        print('✅ [ProductComparisonService] AI 比較完成，結果長度: ${result.length} 字元');
      }

      return result;

    } catch (e) {
      if (kDebugMode) {
        print('❌ [ProductComparisonService] 商品比較失敗: $e');
      }

      // 返回友善的錯誤訊息
      if (e.toString().contains('API key')) {
        return '錯誤：DeepSeek API Key 未設置或無效。請檢查 .env 檔案中的 DEEPSEEK_API_KEY 設定。';
      } else if (e.toString().contains('HTTP')) {
        return '錯誤：無法連接到 DeepSeek API 服務。請檢查網路連線。';
      } else {
        return '錯誤：商品比較失敗。請稍後再試。\n詳細資訊：${e.toString()}';
      }
    }
  }

  /// 使用 AI 比較商品（串流模式）
  ///
  /// [items] 要比較的購物車商品列表
  /// 回傳 AI 生成的比較結果串流
  Stream<String> compareProductsStream(List<CartItem> items) async* {
    if (items.isEmpty) {
      yield '沒有商品可比較';
      return;
    }

    if (items.length == 1) {
      yield '需要至少兩個商品才能進行比較';
      return;
    }

    try {
      // 1. 收集所有商品的詳細資訊
      if (kDebugMode) {
        print('🔍 [ProductComparisonService] 開始收集 ${items.length} 個商品的詳細資訊...');
      }

      final productDetails = <ProductDetail>[];
      for (var item in items) {
        final detail = await _fetchProductDetail(item);
        productDetails.add(detail);
      }

      // 2. 組織商品資訊文字
      final buffer = StringBuffer();
      buffer.writeln('以下是要比較的商品資訊：\n');

      for (var i = 0; i < productDetails.length; i++) {
        buffer.write(_formatProductInfo(productDetails[i], i));
      }

      final productsInfo = buffer.toString();

      // 3. 建立 AI 提示詞
      final systemPrompt = '''你是一個專業的購物助手，擅長分析和比較商品。
請用清晰、簡潔、易於朗讀的中文為視障使用者進行商品比較分析。

比較時請注意以下要點：
1. 重點突出價格差異和性價比
2. 分析商品評分和評論的差異
3. 比較商家的信譽和服務
4. 指出各商品的優缺點
5. 根據不同需求給出推薦建議
6. 使用口語化的表達方式，適合語音朗讀

請將比較結果組織成以下結構：
- 【價格比較】
- 【評分與評論】
- 【商家信譽】
- 【商品特色】
- 【購買建議】

每個部分請保持簡潔，總字數控制在 500 字以內。''';

      final userPrompt = productsInfo;

      // 4. 調用 DeepSeek API（串流模式）
      if (kDebugMode) {
        print('🤖 [ProductComparisonService] 正在調用 DeepSeek API 進行比較（串流模式）...');
      }

      final options = ChatCompletionOptions(
        messages: [
          ChatMessage(role: Role.system, content: systemPrompt),
          ChatMessage(role: Role.user, content: userPrompt),
        ],
        temperature: 0.7,
        maxTokens: 1500,
        stream: true,
      );

      await for (final chunk in _aiClient.chatCompletionStream(options)) {
        yield chunk;
      }

      if (kDebugMode) {
        print('✅ [ProductComparisonService] AI 比較串流完成');
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ [ProductComparisonService] 商品比較失敗: $e');
      }

      // 返回友善的錯誤訊息
      if (e.toString().contains('API key')) {
        yield '錯誤：DeepSeek API Key 未設置或無效。請檢查 .env 檔案中的 DEEPSEEK_API_KEY 設定。';
      } else if (e.toString().contains('HTTP')) {
        yield '錯誤：無法連接到 DeepSeek API 服務。請檢查網路連線。';
      } else {
        yield '錯誤：商品比較失敗。請稍後再試。\n詳細資訊：${e.toString()}';
      }
    }
  }
}
