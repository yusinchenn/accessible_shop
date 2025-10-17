import 'package:isar/isar.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/user_settings.dart';

/// 測試資料服務
/// 用於初始化和管理測試資料
class TestDataService {
  final Isar isar;

  TestDataService(this.isar);

  /// 初始化所有測試資料
  Future<void> initializeAllTestData() async {
    await clearAllData();
    await initializeProducts();
    await initializeUserSettings();
    print('✅ 所有測試資料已初始化完成');
  }

  /// 清空所有資料
  Future<void> clearAllData() async {
    await isar.writeTxn(() async {
      await isar.products.clear();
      await isar.cartItems.clear();
      await isar.userSettings.clear();
    });
    print('🗑️  已清空所有資料');
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
      // 運動鞋類
      Product()
        ..name = 'Nike Air Max 270'
        ..price = 4500
        ..description = '經典氣墊運動鞋，提供絕佳緩震效果，適合日常穿著與運動'
        ..imageUrl = 'https://picsum.photos/400/400?random=1'
        ..category = '運動鞋',

      Product()
        ..name = 'Adidas Ultraboost 22'
        ..price = 5800
        ..description = '頂級跑步鞋款，採用 Boost 中底技術，提供卓越能量回饋'
        ..imageUrl = 'https://picsum.photos/400/400?random=2'
        ..category = '運動鞋',

      Product()
        ..name = 'New Balance 574'
        ..price = 3200
        ..description = '復古經典款式，舒適耐穿，百搭各種休閒造型'
        ..imageUrl = 'https://picsum.photos/400/400?random=3'
        ..category = '運動鞋',

      Product()
        ..name = 'Converse Chuck Taylor'
        ..price = 2200
        ..description = '永不退流行的帆布鞋，經典高筒設計'
        ..imageUrl = 'https://picsum.photos/400/400?random=4'
        ..category = '休閒鞋',

      // 運動服飾
      Product()
        ..name = 'Under Armour 運動上衣'
        ..price = 1200
        ..description = '吸濕排汗機能上衣，適合各種運動場合'
        ..imageUrl = 'https://picsum.photos/400/400?random=5'
        ..category = '運動服飾',

      Product()
        ..name = 'Nike Dri-FIT 運動短褲'
        ..price = 900
        ..description = '輕量透氣運動短褲，搭載 Dri-FIT 科技'
        ..imageUrl = 'https://picsum.photos/400/400?random=6'
        ..category = '運動服飾',

      Product()
        ..name = 'Adidas 運動外套'
        ..price = 2800
        ..description = '防風防潑水外套，三線經典設計'
        ..imageUrl = 'https://picsum.photos/400/400?random=7'
        ..category = '運動服飾',

      // 運動配件
      Product()
        ..name = '智能運動手環'
        ..price = 1500
        ..description = '心率監測、步數記錄、睡眠追蹤，支援多種運動模式'
        ..imageUrl = 'https://picsum.photos/400/400?random=8'
        ..category = '運動配件',

      Product()
        ..name = '瑜珈墊'
        ..price = 800
        ..description = '加厚防滑瑜珈墊，附收納背帶，適合居家運動'
        ..imageUrl = 'https://picsum.photos/400/400?random=9'
        ..category = '運動配件',

      Product()
        ..name = '運動水壺'
        ..price = 450
        ..description = '750ml 大容量運動水壺，不含 BPA，易於清洗'
        ..imageUrl = 'https://picsum.photos/400/400?random=10'
        ..category = '運動配件',

      Product()
        ..name = '運動腰包'
        ..price = 600
        ..description = '防水運動腰包，可放手機、鑰匙等小物'
        ..imageUrl = 'https://picsum.photos/400/400?random=11'
        ..category = '運動配件',

      // 健身器材
      Product()
        ..name = '啞鈴組合 (2-10kg)'
        ..price = 3500
        ..description = '可調式啞鈴組，適合居家重訓'
        ..imageUrl = 'https://picsum.photos/400/400?random=12'
        ..category = '健身器材',

      Product()
        ..name = '彈力帶組合'
        ..price = 650
        ..description = '5 條不同阻力彈力帶，適合各種訓練'
        ..imageUrl = 'https://picsum.photos/400/400?random=13'
        ..category = '健身器材',

      Product()
        ..name = '跳繩'
        ..price = 280
        ..description = '專業競速跳繩，可調節長度，培林設計更順暢'
        ..imageUrl = 'https://picsum.photos/400/400?random=14'
        ..category = '健身器材',

      Product()
        ..name = '瑜珈磚'
        ..price = 350
        ..description = 'EVA 材質瑜珈磚，輔助伸展與平衡訓練'
        ..imageUrl = 'https://picsum.photos/400/400?random=15'
        ..category = '健身器材',

      // 球類運動
      Product()
        ..name = 'Wilson 籃球'
        ..price = 1200
        ..description = '7號標準籃球，室內外兩用'
        ..imageUrl = 'https://picsum.photos/400/400?random=16'
        ..category = '球類運動',

      Product()
        ..name = 'Molten 排球'
        ..price = 950
        ..description = '5號標準排球，柔軟觸感，適合比賽與訓練'
        ..imageUrl = 'https://picsum.photos/400/400?random=17'
        ..category = '球類運動',

      Product()
        ..name = 'Adidas 足球'
        ..price = 1100
        ..description = '5號標準足球，機縫設計，耐用度高'
        ..imageUrl = 'https://picsum.photos/400/400?random=18'
        ..category = '球類運動',

      // 戶外用品
      Product()
        ..name = '登山背包 40L'
        ..price = 2500
        ..description = '多功能登山背包，防潑水材質，透氣背負系統'
        ..imageUrl = 'https://picsum.photos/400/400?random=19'
        ..category = '戶外用品',

      Product()
        ..name = '登山杖'
        ..price = 1200
        ..description = '鋁合金登山杖，可調節長度，減輕膝蓋負擔'
        ..imageUrl = 'https://picsum.photos/400/400?random=20'
        ..category = '戶外用品',
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

  /// 取得資料庫統計資訊
  Future<Map<String, int>> getDatabaseStats() async {
    final productCount = await isar.products.count();
    final cartItemCount = await isar.cartItems.count();
    final userSettingsCount = await isar.userSettings.count();

    return {
      'products': productCount,
      'cartItems': cartItemCount,
      'userSettings': userSettingsCount,
    };
  }

  /// 列印資料庫統計資訊
  Future<void> printDatabaseStats() async {
    final stats = await getDatabaseStats();
    print('📊 資料庫統計：');
    print('   - 商品數量: ${stats['products']}');
    print('   - 購物車項目: ${stats['cartItems']}');
    print('   - 用戶設定: ${stats['userSettings']}');
  }
}
