import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// models (Isar collections)
import 'package:accessible_shop/models/product.dart';
import 'package:accessible_shop/models/cart_item.dart';
import 'package:accessible_shop/models/order.dart';
import 'package:accessible_shop/models/user_settings.dart';

// services
import 'package:accessible_shop/services/database_service.dart';

// pages - 使用 package 匯入，確保 analyzer 能正確解析符號
import 'package:accessible_shop/pages/home/home_page.dart';
import 'package:accessible_shop/pages/product/product_detail_page.dart';
import 'package:accessible_shop/pages/cart/cart_page.dart';
import 'package:accessible_shop/pages/checkout/checkout_page.dart';
import 'package:accessible_shop/pages/orders/order_history_page.dart';
import 'package:accessible_shop/pages/settings/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 取得 app documents 目錄 (Isar 存放目錄)
  final dir = await getApplicationDocumentsDirectory();

  // 開啟 Isar DB，並傳入所有需要的 schema（由 build_runner 產生）
  // 注意：schemas 參數需為 collection schema 列表（ProductSchema 等）
  late final Isar isar;
  try {
    isar = await Isar.open(
      [
        ProductSchema,
        CartItemSchema,
        OrderSchema,
        UserSettingsSchema,
      ],
      directory: dir.path,
    );
  } catch (e, st) {
    // 若 Isar 開啟失敗，印出錯誤以供診斷
    // 常見原因：未產生 *.g.dart、schema 名稱拼錯、build_runner 尚未執行
    debugPrint('Failed to open Isar: $e');
    debugPrint('$st');
    rethrow;
  }

  // 啟動 App 並把 isar 傳入（DatabaseService 會使用它）
  runApp(AccessibleShopApp(isar: isar));
}

class AccessibleShopApp extends StatelessWidget {
  final Isar isar;

  const AccessibleShopApp({super.key, required this.isar});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // DatabaseService 負責 Isar 操作與 ChangeNotifier 事件通知
        ChangeNotifierProvider<DatabaseService>(
          create: (_) => DatabaseService(isar),
        ),
        // 若有其他全域 state，也在這裡加入 Provider 或其它 state 管理器
      ],
      child: MaterialApp(
        title: 'Accessible Shop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // 為了無障礙，可考慮 later 提供多種 theme 與高對比模式
          primarySwatch: Colors.teal,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),

        // 初始頁面
        initialRoute: '/',

        // 固定 route 表
        // 若某些 page 需要接收參數（例：商品 id），請改用 onGenerateRoute 處理帶參路由
        routes: {
          '/': (context) => HomePage(),                // 確保已正確 import 並定義 HomePage
          '/product': (context) => ProductDetailPage(),// 若需要 productId，改用 onGenerateRoute 傳參
          '/cart': (context) => CartPage(),
          '/checkout': (context) => CheckoutPage(),
          '/orders': (context) => OrderHistoryPage(),
          '/settings': (context) => SettingsPage(),
        },

        // onGenerateRoute: 建議用法（範例：若 product page 需要 id）
        // 當你要以 Navigator.pushNamed(context, '/product', arguments: 123) 的方式呼叫時，
        // 可在這裡把 arguments 取出並傳給對應的頁面建構子。
        onGenerateRoute: (settings) {
          // 範例處理：'/product' 並帶一個 int productId
          if (settings.name == '/product') {
            final args = settings.arguments;
            if (args is int) {
              // 這裡假設 ProductDetailPage 有一個 productId 的命名參數
              return MaterialPageRoute(
                builder: (_) => ProductDetailPage(productId: args),
                settings: settings,
              );
            } else {
              // 未傳參時，回傳一個空白或錯誤頁面（或使用無參構造）
              return MaterialPageRoute(
                builder: (_) => ProductDetailPage(),
                settings: settings,
              );
            }
          }

          // 其它動態路由可以在此處擴充

          // 若不是我們處理的路由，回傳 null 讓 framework 使用 routes map 或 onUnknownRoute
          return null;
        },

        // onUnknownRoute: fallback route（可顯示 404 / 提示頁）
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('頁面不存在')),
              body: const Center(child: Text('找不到該頁面')),
            ),
          );
        },
      ),
    );
  }
}
