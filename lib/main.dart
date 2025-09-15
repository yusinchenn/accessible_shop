import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 匯入頁面
import 'pages/home/home_page.dart';
import 'pages/product/product_detail_page.dart';
import 'pages/cart/cart_page.dart';
import 'pages/checkout/checkout_page.dart';
import 'pages/orders/order_history_page.dart';
import 'pages/settings/settings_page.dart';

// 匯入服務
import 'services/database_service.dart';

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
      ],
      child: MaterialApp(
        title: 'Accessible Shop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),

        /// 🔑 首頁立即可見，不會被 Isar 初始化卡住
        home: const HomePage(),

        /// 🔑 路由註冊
        routes: {
          '/product': (context) => const ProductDetailPage(),
          '/cart': (context) => const CartPage(),
          '/checkout': (context) => const CheckoutPage(),
          '/orders': (context) => const OrderHistoryPage(),
          '/settings': (context) => const SettingsPage(),
        },
      ),
    );
  }
}
