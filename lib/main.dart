import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 匯入頁面
import 'pages/home/home_page.dart';
import 'pages/product/product_detail_page.dart';
import 'pages/cart/cart_page.dart';
import 'pages/checkout/checkout_page.dart';
import 'pages/orders/order_history_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/search/search_page.dart';

// 匯入服務
import 'services/database_service.dart';

// 匯入購物車 Provider
import 'pages/cart/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AccessibleShopApp());
}

class AccessibleShopApp extends StatelessWidget {
  const AccessibleShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// DatabaseService 在背景初始化 Isar
        ChangeNotifierProvider(create: (_) => DatabaseService()),

        /// 購物車資料
        ChangeNotifierProvider(create: (_) => ShoppingCartData()),
      ],
      child: MaterialApp(
        title: 'Accessible Shop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),

        /// 首頁
        home: const HomePage(),

        /// 路由註冊
        routes: {
          '/product': (context) => const ProductDetailPage(),
          '/cart': (context) => const ShoppingCartPage(),
          '/checkout': (context) => const CheckoutPage(),
          '/orders': (context) => const OrderHistoryPage(),
          '/settings': (context) => const SettingsPage(),
          '/search': (context) => const SearchPage(),
        },
      ),
    );
  }
}
