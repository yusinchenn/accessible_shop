import 'dart:math';
import 'package:flutter/foundation.dart';
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
    await initializeUserSettings();
    debugPrint('✅ 所有測試資料已初始化完成');
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
      await isar.productReviews.clear();
    });

    debugPrint('🗑️  已清空用戶資料');
    debugPrint('💰 已重置所有使用者錢包餘額');

    // 重新初始化基礎測試資料
    await initializeStores();
    await initializeProducts();
    await initializeProductReviews();
    await initializeUserSettings();

    debugPrint('✅ 已重置到乾淨狀態');
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
    debugPrint('🗑️  已清空所有資料');
  }

  /// 初始化商家測試資料
  Future<void> initializeStores() async {
    final stores = _getSampleStores();

    await isar.writeTxn(() async {
      await isar.stores.putAll(stores);
    });

    debugPrint('✅ 已新增 ${stores.length} 筆商家資料');
  }

  /// 初始化商品測試資料
  Future<void> initializeProducts() async {
    final products = _getSampleProducts();

    await isar.writeTxn(() async {
      await isar.products.putAll(products);
    });

    debugPrint('✅ 已新增 ${products.length} 筆商品資料');
  }

  /// 初始化購物車測試資料（範例）
  Future<void> initializeCartItems() async {
    final cartItems = _getSampleCartItems();

    await isar.writeTxn(() async {
      await isar.cartItems.putAll(cartItems);
    });

    debugPrint('✅ 已新增 ${cartItems.length} 筆購物車資料');
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

    debugPrint('✅ 已初始化用戶設定');
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
  /// 保留此方法以備將來需要，目前返回空列表
  List<CartItem> _getSampleCartItems() {
    return [];
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

    debugPrint('✅ 已新增 ${orders.length} 筆訂單資料和 ${orderItems.length} 筆訂單項目');
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
  /// 保留此方法以備將來需要，目前返回空列表
  List<Order> _getSampleOrders() {
    return [];
  }

  /// 取得範例訂單項目資料
  /// 保留此方法以備將來需要，目前返回空列表
  List<OrderItem> _getSampleOrderItems() {
    return [];
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

    debugPrint('✅ 已新增 ${reviews.length} 筆商品評論資料');
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

  /// 取得範例商品評論資料（每個商品隨機 0-15 則評論）
  List<ProductReview> _getSampleProductReviews() {
    final now = DateTime.now();
    final reviews = <ProductReview>[];
    final random = Random(42); // 使用固定種子以保持一致性

    // 更豐富的評論者名稱庫
    final reviewers = [
      '王小明', '李小華', '張大同', '陳美玲', '林志明', '黃淑芬', '吳建宏', '劉雅婷',
      '鄭國強', '謝佳玲', '周思涵', '蔡宗翰', '許雅文', '郭建志', '楊欣怡', '賴文傑',
      '蘇雅婷', '何志豪', '呂佳穎', '曾俊傑', '徐美惠', '韓宗憲', '魏淑華', '羅建成',
      '梁雅雯', '潘志偉', '丁小芳', '范文彬', '孔雅琪', '龔宗翰',
    ];

    // 5星評論 (4.5-5.0)
    final excellentReviews = [
      '超級滿意！品質遠超預期，真的物超所值！已經推薦給朋友了',
      '完美！材質、做工都是一流，使用起來非常順手，值得五星好評',
      '收到商品後非常驚艷，質感比照片還好，包裝也很用心，會再回購',
      '真的很棒！功能齊全，操作簡單，完全符合我的需求，大推！',
      '品質太好了！使用了一段時間都沒有任何問題，非常耐用，強力推薦',
      '非常滿意這次購物！商品質感極佳，賣家服務也很好，五星好評',
      '太喜歡了！設計美觀實用，使用體驗極佳，會持續關注這家店',
      '優質商品！收到後立刻試用，效果超乎想像，真的買對了',
      '極力推薦！性價比超高，品質完全不輸大品牌，非常值得購買',
      '愛不釋手！每個細節都很到位，可以感受到用心，必須給五星',
    ];

    // 4星評論 (4.0-4.4)
    final goodReviews = [
      '整體表現不錯，品質很好，使用起來很滿意，值得推薦',
      '商品質感很棒，功能完善，雖然價格稍高但物有所值',
      '使用體驗很好，設計合理，唯一小建議是包裝可以更精緻',
      '質量很好，做工精細，使用順暢，整體很滿意這次購買',
      '商品符合描述，品質優良，配送速度也很快，推薦購買',
      '很實用的商品，質感不錯，雖然有點小瑕疵但不影響使用',
      '整體來說很棒，功能齊全，操作簡便，滿意這次購物',
      '品質很好，設計用心，使用起來很舒適，會考慮再次購買',
      '收到商品很滿意，質量可靠，外觀也很漂亮，值得入手',
      '表現不錯的商品，各方面都達到預期，整體體驗良好',
    ];

    // 3星評論 (3.0-3.9)
    final averageReviews = [
      '還可以，品質中規中矩，符合價格，適合基本需求',
      '商品普通，沒有特別驚艷但也不算差，日常使用夠用',
      '整體還行，有些小細節可以改進，但基本功能正常',
      '價格合理，品質也還可以，就是包裝有點簡陋',
      '使用上沒什麼大問題，算是一般水準的商品',
      '跟描述差不多，質感普通，適合預算有限的買家',
      '還算可以接受，功能基本滿足，但做工略顯粗糙',
      '一般般的商品，沒有太多亮點，但也沒有明顯缺點',
      '符合預期，就是普通的商品，不好不壞',
      '可以用，但品質不算特別好，建議多比較再決定',
    ];

    // 2-3星評論（有具體建議）
    final criticalReviews = [
      '商品還可以，但配送時間太久，等了快一週才到',
      '質感普通，而且顏色跟照片有明顯色差，有點失望',
      '功能正常，但包裝破損，希望賣家改進物流包裝',
      '使用上還行，不過說明書太簡略，花了一些時間摸索',
      '品質尚可，但有些小瑕疵，建議出貨前再檢查仔細',
      '整體還好，就是尺寸跟描述有點出入，建議標示清楚',
      '東西可以用，但做工有待加強，細節處理不夠細緻',
      '還算堪用，不過材質摸起來有點廉價，價格可以再優惠',
      '基本功能有達到，但耐用度存疑，用沒多久就有鬆動',
      '收到商品覺得普通，CP值不高，可能會考慮其他品牌',
    ];

    // 運動鞋類專業評論
    final shoesReviews = [
      '楦頭寬度很適中，足弓支撐做得很好，長時間穿著也不會累',
      '鞋底緩震效果很棒，跑步時能明顯感受到保護，推薦給跑者',
      '包覆性很好，鞋面透氣性也不錯，打球時穿很舒適',
      '版型偏大建議選小半號，但整體質感很好，很喜歡',
      '輕量化設計很棒，但抓地力略弱，比較適合室內運動',
    ];

    // 運動服飾專業評論
    final clothingReviews = [
      '排汗效果很好，運動完不會黏身，材質很舒適透氣',
      '版型修身，尺寸準確，剪裁很好看，顏色也很正',
      '彈性很足，活動自如，洗過幾次也不會變形，品質很好',
      '布料觸感柔軟，吸濕速乾效果不錯，夏天穿很涼爽',
      '車工精細，沒有線頭，做工很扎實，可以放心購買',
    ];

    // 健身器材專業評論
    final equipmentReviews = [
      '重量分配很均勻，握把設計人體工學，訓練起來很順手',
      '材質扎實耐用，組裝簡單，佔用空間不大，很適合居家使用',
      '阻力調節很順暢，不同訓練強度都能滿足，CP值很高',
      '防滑效果很好，穩定性佳，訓練時很有安全感',
      '便攜性不錯，收納方便，適合小空間或常搬家的人',
    ];

    // 戶外用品專業評論
    final outdoorReviews = [
      '防水性能很好，背負系統舒適，調節扣具也很順手',
      '材質耐磨，縫線紮實，實際登山測試表現很優秀',
      '重量控制得宜，收納空間充足，很適合多日行程',
      '防潑水效果不錯，但透氣性還可以再加強',
      'CP值很高，適合入門者使用，品質穩定可靠',
    ];

    // 為所有商品生成評論（假設有20個商品）
    for (int productId = 1; productId <= 20; productId++) {
      // 每個商品隨機 0-15 則評論
      final reviewCount = random.nextInt(16); // 0 到 15

      for (int i = 0; i < reviewCount; i++) {
        // 隨機選擇評論者
        final reviewer = reviewers[random.nextInt(reviewers.length)];

        // 根據隨機權重決定評分分佈 (偏向高分，符合真實情況)
        final ratingRoll = random.nextDouble();
        double rating;
        String comment;

        if (ratingRoll < 0.5) {
          // 50% 機率 5星評論
          rating = 4.5 + random.nextDouble() * 0.5;
          comment = excellentReviews[random.nextInt(excellentReviews.length)];

          // 根據商品類別添加專業評論
          if (random.nextDouble() > 0.5) {
            if (productId >= 1 && productId <= 4) {
              comment = shoesReviews[random.nextInt(shoesReviews.length)];
            } else if (productId >= 5 && productId <= 7) {
              comment = clothingReviews[random.nextInt(clothingReviews.length)];
            } else if (productId >= 12 && productId <= 15) {
              comment = equipmentReviews[random.nextInt(equipmentReviews.length)];
            } else if (productId >= 19 && productId <= 20) {
              comment = outdoorReviews[random.nextInt(outdoorReviews.length)];
            }
          }
        } else if (ratingRoll < 0.85) {
          // 35% 機率 4星評論
          rating = 4.0 + random.nextDouble() * 0.4;
          comment = goodReviews[random.nextInt(goodReviews.length)];
        } else if (ratingRoll < 0.95) {
          // 10% 機率 3星評論
          rating = 3.0 + random.nextDouble() * 0.9;
          comment = averageReviews[random.nextInt(averageReviews.length)];
        } else {
          // 5% 機率 2-3星批評性評論
          rating = 2.5 + random.nextDouble() * 1.4;
          comment = criticalReviews[random.nextInt(criticalReviews.length)];
        }

        // 四捨五入到小數點後一位
        rating = (rating * 10).round() / 10;
        if (rating > 5.0) rating = 5.0;
        if (rating < 1.0) rating = 1.0;

        // 隨機生成評論日期（最近90天內）
        final daysAgo = random.nextInt(90) + 1;

        reviews.add(
          ProductReview()
            ..productId = productId
            ..orderId = 0 // 測試評論不關聯訂單
            ..userName = reviewer
            ..rating = rating
            ..comment = comment
            ..createdAt = now.subtract(Duration(days: daysAgo)),
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
    debugPrint('📊 資料庫統計：');
    debugPrint('   - 商家數量: ${stats['stores']}');
    debugPrint('   - 商品數量: ${stats['products']}');
    debugPrint('   - 商品評論: ${stats['reviews']}');
    debugPrint('   - 購物車項目: ${stats['cartItems']}');
    debugPrint('   - 用戶設定: ${stats['userSettings']}');
    debugPrint('   - 訂單數量: ${stats['orders']}');
    debugPrint('   - 訂單項目: ${stats['orderItems']}');
  }
}
