import 'package:isar/isar.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/user_settings.dart';
import '../models/order.dart';
import '../models/store.dart';

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
    await initializeUserSettings();
    print('✅ 所有測試資料已初始化完成');
  }

  /// 清空所有資料
  Future<void> clearAllData() async {
    await isar.writeTxn(() async {
      await isar.stores.clear();
      await isar.products.clear();
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

    print('✅ 已新增 ${orders.length} 筆訂單資料和 ${orderItems.length} 筆訂單項目');
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

  /// 取得資料庫統計資訊
  Future<Map<String, int>> getDatabaseStats() async {
    final storeCount = await isar.stores.count();
    final productCount = await isar.products.count();
    final cartItemCount = await isar.cartItems.count();
    final userSettingsCount = await isar.userSettings.count();
    final orderCount = await isar.orders.count();
    final orderItemCount = await isar.orderItems.count();

    return {
      'stores': storeCount,
      'products': productCount,
      'cartItems': cartItemCount,
      'userSettings': userSettingsCount,
      'orders': orderCount,
      'orderItems': orderItemCount,
    };
  }

  /// 列印資料庫統計資訊
  Future<void> printDatabaseStats() async {
    final stats = await getDatabaseStats();
    print('📊 資料庫統計：');
    print('   - 商家數量: ${stats['stores']}');
    print('   - 商品數量: ${stats['products']}');
    print('   - 購物車項目: ${stats['cartItems']}');
    print('   - 用戶設定: ${stats['userSettings']}');
    print('   - 訂單數量: ${stats['orders']}');
    print('   - 訂單項目: ${stats['orderItems']}');
  }
}
