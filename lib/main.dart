import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

// 匯入頁面
import 'pages/home/home_page.dart';
import 'widgets/splash_screen.dart';
import 'widgets/connectivity_wrapper.dart';
import 'widgets/waiting_for_network_screen.dart';
import 'pages/product/product_detail_page.dart';
import 'pages/store/store_page.dart';
import 'pages/cart/cart_page.dart';
import 'pages/checkout/checkout_page.dart';
import 'pages/orders/order_history_page.dart';
import 'pages/orders/order_detail_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/search/search_page.dart';
import 'pages/search/search_input_page.dart';
import 'pages/auth/accessible_auth_page.dart';
import 'pages/dev/dev_tools_page.dart';
import 'pages/gesture_demo_page.dart';
import 'pages/short_videos/short_videos_page.dart';
import 'pages/notifications/notifications_page.dart';
import 'pages/comparison/comparison_page.dart';
import 'pages/wallet/wallet_page.dart';
import 'pages/messages/messages_page.dart';
import 'pages/messages/chat_page.dart';

// 匯入服務
import 'services/database_service.dart';
import 'services/firestore_service.dart';
import 'services/order_automation_service.dart';
import 'services/notification_service.dart';
import 'services/daily_reward_scheduler.dart';
import 'services/connectivity_service.dart';

// 匯入 Providers
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/comparison_provider.dart';

// 匯入常數
import 'utils/app_constants.dart';
import 'utils/connectivity_navigator_observer.dart';

// 全域 RouteObserver，用於監聽頁面狀態變化
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// 全域 ConnectivityNavigatorObserver，用於在頁面切換時檢查網路
final ConnectivityNavigatorObserver connectivityNavigatorObserver =
    ConnectivityNavigatorObserver();

void main() async {
  // 確保 Flutter binding 已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 載入環境變數
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // 如果載入失敗，僅在 debug 模式下印出警告
    debugPrint('⚠️ [Main] 無法載入 .env 檔案: $e');
    debugPrint('   請確保專案根目錄有 .env 檔案，並設置 DEEPSEEK_API_KEY');
  }

  // 初始化通知服務
  try {
    await notificationService.initialize();
    debugPrint('✅ [Main] 通知服務初始化成功');
  } catch (e) {
    debugPrint('⚠️ [Main] 通知服務初始化失敗: $e');
  }

  // 初始化網路連線監聽服務
  try {
    await connectivityService.initialize();
    debugPrint('✅ [Main] 網路連線服務初始化成功');
  } catch (e) {
    debugPrint('⚠️ [Main] 網路連線服務初始化失敗: $e');
  }

  runApp(const AccessibleShopApp());
}

class AccessibleShopApp extends StatelessWidget {
  const AccessibleShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 直接返回 FirebaseInitializer，避免雙層 MaterialApp
    // 實際的 MaterialApp 在 AppRouter 中定義
    return const FirebaseInitializer();
  }
}

/// Firebase 初始化包裝器
class FirebaseInitializer extends StatefulWidget {
  const FirebaseInitializer({super.key});

  @override
  State<FirebaseInitializer> createState() => _FirebaseInitializerState();
}

class _FirebaseInitializerState extends State<FirebaseInitializer> {
  Future<FirebaseApp>? _initialization;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isConnected = true;
  bool _hasCheckedInitialConnection = false;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeFirebase();
    _listenToConnectivity();
  }

  Future<FirebaseApp> _initializeFirebase() async {
    await Future.delayed(const Duration(milliseconds: 1000)); // 確保啟動畫面顯示（延長至 1 秒）
    return await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  /// 監聽網路連線狀態
  void _listenToConnectivity() {
    _connectivitySubscription =
        connectivityService.connectionStatus.listen((bool isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
          _hasCheckedInitialConnection = true;
        });
        debugPrint('🌐 [FirebaseInitializer] 網路狀態: ${isConnected ? "已連線" : "已斷線"}');
      }
    });

    // 立即檢查初始連線狀態
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_hasCheckedInitialConnection) {
        setState(() {
          _isConnected = connectivityService.isConnected;
          _hasCheckedInitialConnection = true;
        });
        debugPrint('🔍 [FirebaseInitializer] 初始網路狀態: $_isConnected');
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initialization,
      builder: (context, snapshot) {
        // 錯誤處理
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background_2,
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 80, color: Colors.red),
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      '初始化失敗',
                      style: AppTextStyles.title.copyWith(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      '${snapshot.error}',
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _initialization = _initializeFirebase();
                        });
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('重試', style: AppTextStyles.body),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.text_2,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 初始化完成
        if (snapshot.connectionState == ConnectionState.done) {
          // 檢查網路連線狀態
          if (_hasCheckedInitialConnection && !_isConnected) {
            // 如果沒有網路，顯示等待網路畫面
            debugPrint('❌ [FirebaseInitializer] 無網路連線，顯示等待畫面');
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: WaitingForNetworkScreen(
                onConnected: () {
                  debugPrint('✅ [FirebaseInitializer] 網路已恢復');
                  // 網路恢復時重新渲染
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
            );
          }

          // 有網路，繼續正常流程
          return MultiProvider(
            providers: [
              /// 身份驗證
              ChangeNotifierProvider(create: (_) => AuthProvider()),

              /// DatabaseService 在背景初始化 Isar
              ChangeNotifierProvider(create: (_) => DatabaseService()),

              /// FirestoreService 處理 Firebase Firestore 資料
              ChangeNotifierProvider(create: (_) => FirestoreService()),

              /// 訂單自動化服務 (依賴 DatabaseService)
              ProxyProvider<DatabaseService, OrderAutomationService>(
                create: (context) {
                  final db = Provider.of<DatabaseService>(
                    context,
                    listen: false,
                  );
                  final service = OrderAutomationService(db);
                  // 初始化自動化服務（掃描現有訂單）
                  service.initialize();
                  return service;
                },
                update: (context, dbService, previous) =>
                    previous ?? OrderAutomationService(dbService),
                dispose: (context, service) => service.dispose(),
              ),

              /// 購物車資料 (依賴 DatabaseService)
              ChangeNotifierProxyProvider<DatabaseService, ShoppingCartData>(
                create: (context) => ShoppingCartData(
                  Provider.of<DatabaseService>(context, listen: false),
                ),
                update: (context, dbService, previous) =>
                    previous ?? ShoppingCartData(dbService),
              ),

              /// 商品比較 (依賴 DatabaseService)
              ChangeNotifierProxyProvider<DatabaseService, ComparisonProvider>(
                create: (context) {
                  final provider = ComparisonProvider();
                  final db = Provider.of<DatabaseService>(
                    context,
                    listen: false,
                  );
                  provider.initComparisonService(db);
                  return provider;
                },
                update: (context, dbService, previous) {
                  if (previous != null) {
                    previous.initComparisonService(dbService);
                    return previous;
                  }
                  final provider = ComparisonProvider();
                  provider.initComparisonService(dbService);
                  return provider;
                },
              ),
            ],
            child: const AppRouter(),
          );
        }

        // 載入中 - 使用新的 SplashScreen
        return const SplashScreen();
      },
    );
  }
}

/// App 路由器
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  /// 構建受保護的路由（需要登入才能訪問）
  Widget _buildProtectedRoute(BuildContext context, Widget page) {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      debugPrint('[路由守衛] 未登入，導向登入頁面');
      // 未登入時，導向登入頁面
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/auth', (route) => false);
        }
      });
      return const AccessibleAuthPage();
    }
    return page;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accessible Shop',
      debugShowCheckedModeBanner: false,
      // 添加路由觀察器
      navigatorObservers: [
        routeObserver,
        connectivityNavigatorObserver, // 網路檢查觀察器
      ],
      // 添加本地化支援
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'TW'), // 繁體中文
        Locale('en', 'US'), // 英文
      ],
      locale: const Locale('zh', 'TW'), // 預設語言
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0), // 固定為 1.0，完全忽略系統字體大小
          ),
          child: ConnectivityWrapper(
            child: child!,
          ),
        );
      },
      theme: ThemeData(
        primaryColor: AppColors.primary_2,
        scaffoldBackgroundColor: AppColors.background_2,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary_2,
          primary: AppColors.primary_2,
          secondary: AppColors.accent_2,
        ),
        textTheme: GoogleFonts.notoSansTcTextTheme(
          const TextTheme(
            displayLarge: AppTextStyles.extraLargeTitle,
            titleLarge: AppTextStyles.title,
            titleMedium: AppTextStyles.subtitle,
            bodyLarge: AppTextStyles.body,
            bodyMedium: AppTextStyles.small,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary_2,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.notoSansTc(
            textStyle: AppTextStyles.title.copyWith(color: Colors.white),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBackground_1,
          elevation: 2,
        ),
        dividerTheme: DividerThemeData(color: AppColors.text_2, thickness: 1),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      /// 根據登入狀態決定首頁
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isAuthenticated) {
            // 用戶已登入，初始化每日獎勵調度器
            WidgetsBinding.instance.addPostFrameCallback((_) {
              dailyRewardScheduler.initialize(authProvider.userId);
            });
            return const HomePage();
          }
          return const AccessibleAuthPage();
        },
      ),

      /// 路由註冊（所有路由都受保護，需要登入）
      routes: {
        '/auth': (context) => const AccessibleAuthPage(),
        '/home': (context) => _buildProtectedRoute(context, const HomePage()),
        '/product': (context) =>
            _buildProtectedRoute(context, const ProductDetailPage()),
        '/product_detail': (context) =>
            _buildProtectedRoute(context, const ProductDetailPage()),
        '/cart': (context) =>
            _buildProtectedRoute(context, const ShoppingCartPage()),
        '/comparison': (context) =>
            _buildProtectedRoute(context, const ComparisonPage()),
        '/checkout': (context) =>
            _buildProtectedRoute(context, const CheckoutPage()),
        '/orders': (context) =>
            _buildProtectedRoute(context, const OrderHistoryPage()),
        '/order-detail': (context) =>
            _buildProtectedRoute(context, const OrderDetailPage()),
        '/settings': (context) =>
            _buildProtectedRoute(context, const SettingsPage()),
        '/search': (context) =>
            _buildProtectedRoute(context, const SearchPage()),
        '/search_input': (context) =>
            _buildProtectedRoute(context, const SearchInputPage()),
        '/dev-tools': (context) =>
            _buildProtectedRoute(context, const DevToolsPage()),
        '/gesture-demo': (context) =>
            _buildProtectedRoute(context, const GestureDemoPage()),
        '/short_videos': (context) =>
            _buildProtectedRoute(context, const ShortVideosPage()),
        '/notifications': (context) =>
            _buildProtectedRoute(context, const NotificationsPage()),
        '/wallet': (context) =>
            _buildProtectedRoute(context, const WalletPage()),
        '/messages': (context) =>
            _buildProtectedRoute(context, const MessagesPage()),
        '/chat': (context) =>
            _buildProtectedRoute(context, const ChatPage()),
      },

      /// 動態路由（需要參數的頁面）
      onGenerateRoute: (settings) {
        // 商家頁面路由
        if (settings.name == '/store') {
          final storeId = settings.arguments as int?;
          if (storeId != null) {
            return MaterialPageRoute(
              builder: (context) =>
                  _buildProtectedRoute(context, StorePage(storeId: storeId)),
              settings: settings,
            );
          }
        }
        return null;
      },
    );
  }
}
