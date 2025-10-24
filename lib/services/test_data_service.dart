import 'package:isar/isar.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/user_settings.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../models/store.dart';
import '../models/product_review.dart';
import '../models/user_profile.dart';

/// 測試資料服務
/// 用於初始化和管理測試資料
class TestDataService {
  final Isar isar;

  TestDataService(this.isar);

  /// 初始化所有測試資料
  Future<void> initializeAllTestData() async {
    await clearAllData();
    await initializeStores();
    await initializeProducts();
    await initializeProductReviews();
    await initializeOrders();
    await initializeUserSettings();
    print('✅ 所有測試資料已初始化完成');
  }

  /// 重置到乾淨狀態
  /// 清除用戶操作產生的資料（訂單、購物車、用戶評論）
  /// 保持基礎測試資料（商家、商品、測試評論）
  Future<void> resetToCleanState() async {
    await isar.writeTxn(() async {
      // 清空用戶操作產生的資料
      await isar.orders.clear();
      await isar.orderItems.clear();
      await isar.orderStatusTimestamps.clear();
      await isar.orderStatusHistorys.clear();
      await isar.cartItems.clear();
      await isar.productReviews.clear();

      // 重置所有使用者的錢包餘額
      final allProfiles = await isar.userProfiles.where().findAll();
      for (var profile in allProfiles) {
        profile.walletBalance = 0.0;
        profile.lastDailyRewardDate = null;
        await isar.userProfiles.put(profile);
      }

      // 清空並重新插入基礎資料
      await isar.stores.clear();
      await isar.products.clear();
    });

    print('🗑️  已清空用戶資料');
    print('💰 已重置所有使用者錢包餘額');

    // 重新初始化基礎測試資料
    await initializeStores();
    await initializeProducts();
    await initializeProductReviews();
    await initializeUserSettings();

    print('✅ 已重置到乾淨狀態');
  }

  /// 清空所有資料
  Future<void> clearAllData() async {
    await isar.writeTxn(() async {
      await isar.stores.clear();
      await isar.products.clear();
      await isar.productReviews.clear();
      await isar.cartItems.clear();
      await isar.userSettings.clear();
      await isar.orders.clear();
      await isar.orderItems.clear();
    });
    print('🗑️  已清空所有資料');
  }

  /// 初始化商家測試資料
  Future<void> initializeStores() async {
    final stores = _getSampleStores();

    await isar.writeTxn(() async {
      await isar.stores.putAll(stores);
    });

    print('✅ 已新增 ${stores.length} 筆商家資料');
  }

  /// 初始化商品測試資料
  Future<void> initializeProducts() async {
    final products = _getSampleProducts();

    await isar.writeTxn(() async {
      await isar.products.putAll(products);
    });

    print('✅ 已新增 ${products.length} 筆商品資料');
  }

  /// 初始化購物車測試資料（範例）
  Future<void> initializeCartItems() async {
    final cartItems = _getSampleCartItems();

    await isar.writeTxn(() async {
      await isar.cartItems.putAll(cartItems);
    });

    print('✅ 已新增 ${cartItems.length} 筆購物車資料');
  }

  /// 初始化用戶設定
  Future<void> initializeUserSettings() async {
    final settings = UserSettings()
      ..ttsEnabled = true
      ..ttsSpeed = 1.0
      ..fontSize = 16.0
      ..preferredLanguage = 'zh-TW';

    await isar.writeTxn(() async {
      await isar.userSettings.put(settings);
    });

    print('✅ 已初始化用戶設定');
  }

  /// 取得範例商品資料
  List<Product> _getSampleProducts() {
    return [
      // 商家 1 - 運動世界專賣店 (7個商品)
      Product()
        ..name = 'Nike Air Max 270'
        ..price = 4500
        ..description = '經典氣墊運動鞋，提供絕佳緩震效果，適合日常穿著與運動'
        ..imageUrl = 'https://picsum.photos/400/400?random=1'
        ..category = '運動鞋'
        ..storeId = 1,

      Product()
        ..name = 'Adidas Ultraboost 22'
        ..price = 5800
        ..description = '頂級跑步鞋款，採用 Boost 中底技術，提供卓越能量回饋'
        ..imageUrl = 'https://picsum.photos/400/400?random=2'
        ..category = '運動鞋'
        ..storeId = 1,

      Product()
        ..name = 'Nike Dri-FIT 運動短褲'
        ..price = 900
        ..description = '輕量透氣運動短褲，搭載 Dri-FIT 科技'
        ..imageUrl = 'https://picsum.photos/400/400?random=6'
        ..category = '運動服飾'
        ..storeId = 1,

      Product()
        ..name = 'Adidas 運動外套'
        ..price = 2800
        ..description = '防風防潑水外套，三線經典設計'
        ..imageUrl = 'https://picsum.photos/400/400?random=7'
        ..category = '運動服飾'
        ..storeId = 1,

      Product()
        ..name = 'Under Armour 運動上衣'
        ..price = 1200
        ..description = '吸濕排汗機能上衣，適合各種運動場合'
        ..imageUrl = 'https://picsum.photos/400/400?random=5'
        ..category = '運動服飾'
        ..storeId = 1,

      Product()
        ..name = 'Adidas 足球'
        ..price = 1100
        ..description = '5號標準足球，機縫設計，耐用度高'
        ..imageUrl = 'https://picsum.photos/400/400?random=18'
        ..category = '球類運動'
        ..storeId = 1,

      Product()
        ..name = 'Wilson 籃球'
        ..price = 1200
        ..description = '7號標準籃球，室內外兩用'
        ..imageUrl = 'https://picsum.photos/400/400?random=16'
        ..category = '球類運動'
        ..storeId = 1,

      // 商家 2 - 健身器材專賣店 (7個商品)
      Product()
        ..name = '啞鈴組合 (2-10kg)'
        ..price = 3500
        ..description = '可調式啞鈴組，適合居家重訓'
        ..imageUrl = 'https://picsum.photos/400/400?random=12'
        ..category = '健身器材'
        ..storeId = 2,

      Product()
        ..name = '彈力帶組合'
        ..price = 650
        ..description = '5 條不同阻力彈力帶，適合各種訓練'
        ..imageUrl = 'https://picsum.photos/400/400?random=13'
        ..category = '健身器材'
        ..storeId = 2,

      Product()
        ..name = '跳繩'
        ..price = 280
        ..description = '專業競速跳繩，可調節長度，培林設計更順暢'
        ..imageUrl = 'https://picsum.photos/400/400?random=14'
        ..category = '健身器材'
        ..storeId = 2,

      Product()
        ..name = '瑜珈磚'
        ..price = 350
        ..description = 'EVA 材質瑜珈磚，輔助伸展與平衡訓練'
        ..imageUrl = 'https://picsum.photos/400/400?random=15'
        ..category = '健身器材'
        ..storeId = 2,

      Product()
        ..name = '瑜珈墊'
        ..price = 800
        ..description = '加厚防滑瑜珈墊，附收納背帶，適合居家運動'
        ..imageUrl = 'https://picsum.photos/400/400?random=9'
        ..category = '運動配件'
        ..storeId = 2,

      Product()
        ..name = '智能運動手環'
        ..price = 1500
        ..description = '心率監測、步數記錄、睡眠追蹤，支援多種運動模式'
        ..imageUrl = 'https://picsum.photos/400/400?random=8'
        ..category = '運動配件'
        ..storeId = 2,

      Product()
        ..name = '運動水壺'
        ..price = 450
        ..description = '750ml 大容量運動水壺，不含 BPA，易於清洗'
        ..imageUrl = 'https://picsum.photos/400/400?random=10'
        ..category = '運動配件'
        ..storeId = 2,

      // 商家 3 - 戶外探險家 (6個商品)
      Product()
        ..name = '登山背包 40L'
        ..price = 2500
        ..description = '多功能登山背包，防潑水材質，透氣背負系統'
        ..imageUrl = 'https://picsum.photos/400/400?random=19'
        ..category = '戶外用品'
        ..storeId = 3,

      Product()
        ..name = '登山杖'
        ..price = 1200
        ..description = '鋁合金登山杖，可調節長度，減輕膝蓋負擔'
        ..imageUrl = 'https://picsum.photos/400/400?random=20'
        ..category = '戶外用品'
        ..storeId = 3,

      Product()
        ..name = 'New Balance 574'
        ..price = 3200
        ..description = '復古經典款式，舒適耐穿，百搭各種休閒造型'
        ..imageUrl = 'https://picsum.photos/400/400?random=3'
        ..category = '運動鞋'
        ..storeId = 3,

      Product()
        ..name = 'Converse Chuck Taylor'
        ..price = 2200
        ..description = '永不退流行的帆布鞋，經典高筒設計'
        ..imageUrl = 'https://picsum.photos/400/400?random=4'
        ..category = '休閒鞋'
        ..storeId = 3,

      Product()
        ..name = '運動腰包'
        ..price = 600
        ..description = '防水運動腰包，可放手機、鑰匙等小物'
        ..imageUrl = 'https://picsum.photos/400/400?random=11'
        ..category = '運動配件'
        ..storeId = 3,

      Product()
        ..name = 'Molten 排球'
        ..price = 950
        ..description = '5號標準排球，柔軟觸感，適合比賽與訓練'
        ..imageUrl = 'https://picsum.photos/400/400?random=17'
        ..category = '球類運動'
        ..storeId = 3,
    ];
  }

  /// 取得範例購物車資料
  List<CartItem> _getSampleCartItems() {
    return [
      CartItem()
        ..productId = 1 // Nike Air Max 270
        ..name = 'Nike Air Max 270'
        ..specification = '尺寸: L / 顏色: 黑色'
        ..unitPrice = 4500
        ..quantity = 1
        ..isSelected = true,

      CartItem()
        ..productId = 10 // 運動水壺
        ..name = '運動水壺'
        ..specification = '尺寸: 通用尺寸 / 顏色: 藍色'
        ..unitPrice = 450
        ..quantity = 2
        ..isSelected = true,

      CartItem()
        ..productId = 9 // 瑜珈墊
        ..name = '瑜珈墊'
        ..specification = '尺寸: 通用尺寸 / 顏色: 紫色'
        ..unitPrice = 800
        ..quantity = 1
        ..isSelected = false,
    ];
  }

  /// 初始化訂單測試資料
  Future<void> initializeOrders() async {
    final orders = _getSampleOrders();
    final orderItems = _getSampleOrderItems();

    await isar.writeTxn(() async {
      await isar.orders.putAll(orders);
      await isar.orderItems.putAll(orderItems);
    });

    // 為每個訂單建立時間戳記錄
    for (var order in orders) {
      await _initializeOrderTimestamps(order);
    }

    print('✅ 已新增 ${orders.length} 筆訂單資料和 ${orderItems.length} 筆訂單項目');
  }

  /// 為訂單初始化時間戳記錄
  Future<void> _initializeOrderTimestamps(Order order) async {
    final timestamps = OrderStatusTimestamps()
      ..orderId = order.id
      ..createdAt = order.createdAt;

    // 根據訂單狀態設定對應的時間戳
    switch (order.mainStatus) {
      case OrderMainStatus.pendingPayment:
        timestamps.pendingPaymentAt = order.createdAt;
        break;
      case OrderMainStatus.pendingShipment:
        timestamps.pendingPaymentAt = order.createdAt;
        timestamps.pendingShipmentAt = order.createdAt;
        break;
      case OrderMainStatus.pendingDelivery:
        timestamps.pendingPaymentAt = order.createdAt;
        timestamps.pendingShipmentAt = order.createdAt;
        timestamps.pendingDeliveryAt = order.createdAt;
        if (order.logisticsStatus == LogisticsStatus.inTransit) {
          timestamps.inTransitAt = order.createdAt;
        } else if (order.logisticsStatus == LogisticsStatus.arrivedAtPickupPoint) {
          timestamps.inTransitAt = order.createdAt;
          timestamps.arrivedAtPickupPointAt = order.createdAt;
        } else if (order.logisticsStatus == LogisticsStatus.signed) {
          timestamps.inTransitAt = order.createdAt;
          timestamps.signedAt = order.createdAt;
        }
        break;
      case OrderMainStatus.completed:
        timestamps.pendingPaymentAt = order.createdAt;
        timestamps.pendingShipmentAt = order.createdAt;
        timestamps.pendingDeliveryAt = order.createdAt;
        timestamps.inTransitAt = order.createdAt;
        timestamps.signedAt = order.createdAt;
        timestamps.completedAt = order.createdAt;
        break;
      case OrderMainStatus.returnRefund:
        timestamps.returnRefundAt = order.createdAt;
        break;
      case OrderMainStatus.invalid:
        timestamps.invalidAt = order.createdAt;
        break;
    }

    await isar.writeTxn(() async {
      await isar.orderStatusTimestamps.put(timestamps);
    });
  }

  /// 取得範例訂單資料
  List<Order> _getSampleOrders() {
    final now = DateTime.now();

    return [
      Order()
        ..orderNumber = '20250117-0001'
        ..createdAt = now.subtract(const Duration(days: 2))
        ..status = 'completed'
        ..subtotal = 5400
        ..discount = 100
        ..shippingFee = 60
        ..total = 5360
        ..couponId = 1
        ..couponName = '新會員優惠'
        ..shippingMethodId = 1
        ..shippingMethodName = '超商取貨'
        ..paymentMethodId = 1
        ..paymentMethodName = '信用卡',

      Order()
        ..orderNumber = '20250115-0001'
        ..createdAt = now.subtract(const Duration(days: 5))
        ..status = 'processing'
        ..subtotal = 1200
        ..discount = 0
        ..shippingFee = 100
        ..total = 1300
        ..shippingMethodId = 2
        ..shippingMethodName = '宅配'
        ..paymentMethodId = 2
        ..paymentMethodName = '貨到付款',

      Order()
        ..orderNumber = '20250110-0001'
        ..createdAt = now.subtract(const Duration(days: 10))
        ..status = 'completed'
        ..subtotal = 3500
        ..discount = 0
        ..shippingFee = 80
        ..total = 3580
        ..shippingMethodId = 3
        ..shippingMethodName = '郵局'
        ..paymentMethodId = 3
        ..paymentMethodName = 'ATM轉帳',
    ];
  }

  /// 取得範例訂單項目資料
  List<OrderItem> _getSampleOrderItems() {
    return [
      // 訂單 1 的項目
      OrderItem()
        ..orderId = 1
        ..productId = 1
        ..productName = 'Nike Air Max 270'
        ..specification = '尺寸: L / 顏色: 黑色'
        ..unitPrice = 4500
        ..quantity = 1
        ..subtotal = 4500,

      OrderItem()
        ..orderId = 1
        ..productId = 10
        ..productName = '運動水壺'
        ..specification = '尺寸: 通用尺寸 / 顏色: 藍色'
        ..unitPrice = 450
        ..quantity = 2
        ..subtotal = 900,

      // 訂單 2 的項目
      OrderItem()
        ..orderId = 2
        ..productId = 5
        ..productName = 'Under Armour 運動上衣'
        ..specification = '尺寸: M / 顏色: 黑色'
        ..unitPrice = 1200
        ..quantity = 1
        ..subtotal = 1200,

      // 訂單 3 的項目
      OrderItem()
        ..orderId = 3
        ..productId = 12
        ..productName = '啞鈴組合 (2-10kg)'
        ..specification = '尺寸: 通用尺寸 / 顏色: 預設顏色'
        ..unitPrice = 3500
        ..quantity = 1
        ..subtotal = 3500,
    ];
  }

  /// 取得範例商家資料
  List<Store> _getSampleStores() {
    return [
      Store()
        ..name = '運動世界專賣店'
        ..rating = 4.8
        ..followersCount = 15230
        ..imageUrl = 'https://picsum.photos/400/400?random=101'
        ..description = '專營各大運動品牌，提供最新款運動鞋與服飾，品質保證，價格實惠',

      Store()
        ..name = '健身器材專賣店'
        ..rating = 4.6
        ..followersCount = 8965
        ..imageUrl = 'https://picsum.photos/400/400?random=102'
        ..description = '居家健身器材首選，從入門到專業，應有盡有，免費提供健身諮詢',

      Store()
        ..name = '戶外探險家'
        ..rating = 4.9
        ..followersCount = 22100
        ..imageUrl = 'https://picsum.photos/400/400?random=103'
        ..description = '登山、露營、戶外運動裝備專賣，多年經驗的專業團隊為您服務',
    ];
  }

  /// 初始化商品評論測試資料
  Future<void> initializeProductReviews() async {
    final reviews = _getSampleProductReviews();

    await isar.writeTxn(() async {
      await isar.productReviews.putAll(reviews);
    });

    // 更新每個商品的平均評分和評論數量
    await _updateAllProductRatings();

    print('✅ 已新增 ${reviews.length} 筆商品評論資料');
  }

  /// 更新所有商品的評分統計
  Future<void> _updateAllProductRatings() async {
    final products = await isar.products.where().findAll();

    for (var product in products) {
      final reviews = await isar.productReviews
          .filter()
          .productIdEqualTo(product.id)
          .findAll();

      if (reviews.isNotEmpty) {
        final totalRating = reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
        final averageRating = totalRating / reviews.length;

        await isar.writeTxn(() async {
          product.averageRating = averageRating;
          product.reviewCount = reviews.length;
          await isar.products.put(product);
        });
      }
    }
  }

  /// 取得範例商品評論資料（每個商品 3-5 則評論）
  List<ProductReview> _getSampleProductReviews() {
    final now = DateTime.now();
    final reviews = <ProductReview>[];

    // 定義評論者名稱和評論範本
    final reviewers = ['王小明', '李小華', '張大同', '陳美玲', '林志明', '黃淑芬', '吳建宏', '劉雅婷', '鄭國強', '謝佳玲'];

    final positiveComments = [
      '商品品質很好，非常滿意！',
      '使用起來非常舒適，值得推薦',
      '質感很棒，符合期待',
      '物超所值，cp值很高',
      '收到貨很驚艷，比照片還好看',
      '做工精細，使用體驗很好',
      '賣家服務很好，商品也很棒',
      '功能齊全，使用方便',
      '非常實用的商品，推薦購買',
      '品質優良，會再回購',
    ];

    final neutralComments = [
      '整體還不錯，符合價格',
      '商品普通，但還算可以接受',
      '使用上沒什麼問題，算是中規中矩',
      '跟描述差不多，還可以',
      '價格合理，品質也還行',
    ];

    final criticalComments = [
      '商品還不錯，但配送時間有點久',
      '質感可以，但有一點小瑕疵',
      '使用上沒問題，但包裝可以再改進',
      '整體還好，但顏色跟照片有點色差',
      '功能正常，但說明書不太清楚',
    ];

    // 為前 20 個商品添加評論（可根據需要調整）
    for (int productId = 1; productId <= 20; productId++) {
      // 每個商品隨機 3-5 則評論
      final reviewCount = 3 + (productId % 3); // 3, 4 或 5 則

      for (int i = 0; i < reviewCount; i++) {
        final reviewerIndex = (productId * 3 + i) % reviewers.length;
        final reviewer = reviewers[reviewerIndex];

        // 根據評論順序決定評分和內容
        double rating;
        String comment;

        if (i == 0) {
          // 第一則評論：高分 (4.5-5.0)
          rating = 4.5 + (productId % 6) * 0.1;
          if (rating > 5.0) rating = 5.0;
          comment = positiveComments[(productId + i) % positiveComments.length];
        } else if (i == reviewCount - 1 && reviewCount > 3) {
          // 最後一則（如果有4則以上）：中低分 (3.0-4.0)
          rating = 3.0 + (productId % 11) * 0.1;
          comment = criticalComments[(productId + i) % criticalComments.length];
        } else if (i == 1) {
          // 第二則：高分 (4.0-5.0)
          rating = 4.0 + (productId % 11) * 0.1;
          comment = positiveComments[(productId + i + 3) % positiveComments.length];
        } else {
          // 其他：中等分數 (3.5-4.5)
          rating = 3.5 + (productId % 11) * 0.1;
          comment = neutralComments[(productId + i) % neutralComments.length];
        }

        reviews.add(
          ProductReview()
            ..productId = productId
            ..orderId = 0  // 測試評論不關聯訂單，使用 0 表示
            ..userName = reviewer
            ..rating = rating
            ..comment = comment
            ..createdAt = now.subtract(Duration(days: (i + 1) * 5)),
        );
      }
    }

    return reviews;
  }

  /// 取得資料庫統計資訊
  Future<Map<String, int>> getDatabaseStats() async {
    final storeCount = await isar.stores.count();
    final productCount = await isar.products.count();
    final cartItemCount = await isar.cartItems.count();
    final userSettingsCount = await isar.userSettings.count();
    final orderCount = await isar.orders.count();
    final orderItemCount = await isar.orderItems.count();
    final reviewCount = await isar.productReviews.count();

    return {
      'stores': storeCount,
      'products': productCount,
      'cartItems': cartItemCount,
      'userSettings': userSettingsCount,
      'orders': orderCount,
      'orderItems': orderItemCount,
      'reviews': reviewCount,
    };
  }

  /// 列印資料庫統計資訊
  Future<void> printDatabaseStats() async {
    final stats = await getDatabaseStats();
    print('📊 資料庫統計：');
    print('   - 商家數量: ${stats['stores']}');
    print('   - 商品數量: ${stats['products']}');
    print('   - 商品評論: ${stats['reviews']}');
    print('   - 購物車項目: ${stats['cartItems']}');
    print('   - 用戶設定: ${stats['userSettings']}');
    print('   - 訂單數量: ${stats['orders']}');
    print('   - 訂單項目: ${stats['orderItems']}');
  }
}
