import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// 匯入模型
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/user_settings.dart';
import '../models/order.dart';
import '../models/user_profile.dart';
import '../models/notification.dart';

class DatabaseService extends ChangeNotifier {
  late Future<Isar> _isarFuture;

  DatabaseService() {
    _isarFuture = _initIsar();
  }

  /// 初始化 Isar（非同步，不阻塞 UI）
  Future<Isar> _initIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open([
      ProductSchema,
      CartItemSchema,
      UserSettingsSchema,
      OrderSchema,
      OrderItemSchema,
      UserProfileSchema,
      NotificationModelSchema,
    ], directory: dir.path);
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
  /// 1. 商品名稱完全匹配
  /// 2. 商品名稱包含關鍵字
  /// 3. 描述包含關鍵字
  /// 4. 分類包含關鍵字
  Future<List<Product>> searchProducts(String keyword) async {
    if (keyword.isEmpty) {
      return await getProducts();
    }

    final isar = await _isarFuture;
    final allProducts = await isar.products.where().findAll();

    if (kDebugMode) {
      print('🔍 [DatabaseService] 資料庫總商品數: ${allProducts.length}');
      print('🔍 [DatabaseService] 搜尋關鍵字: "$keyword"');
    }

    final searchKeyword = keyword.toLowerCase().trim();

    // 使用評分系統進行排序
    final scoredProducts = allProducts.map((product) {
      int score = 0;
      final name = product.name.toLowerCase();
      final description = (product.description ?? '').toLowerCase();
      final category = (product.category ?? '').toLowerCase();

      // 商品名稱完全匹配 - 最高分 100
      if (name == searchKeyword) {
        score = 100;
      }
      // 商品名稱開頭匹配 - 90 分
      else if (name.startsWith(searchKeyword)) {
        score = 90;
      }
      // 商品名稱包含關鍵字 - 80 分
      else if (name.contains(searchKeyword)) {
        score = 80;
      }
      // 描述完全匹配 - 70 分
      else if (description == searchKeyword) {
        score = 70;
      }
      // 描述包含關鍵字 - 60 分
      else if (description.contains(searchKeyword)) {
        score = 60;
      }
      // 分類完全匹配 - 50 分
      else if (category == searchKeyword) {
        score = 50;
      }
      // 分類包含關鍵字 - 40 分
      else if (category.contains(searchKeyword)) {
        score = 40;
      }

      // 模糊匹配：檢查是否包含關鍵字的部分字符（至少 2 個字）
      if (score == 0 && searchKeyword.length >= 2) {
        // 檢查名稱中是否包含關鍵字的連續子字串
        for (int i = 0; i <= searchKeyword.length - 2; i++) {
          final substring = searchKeyword.substring(i, i + 2);
          if (name.contains(substring)) {
            score = 20;
            break;
          }
          if (description.contains(substring)) {
            score = 10;
            break;
          }
        }
      }

      return MapEntry(product, score);
    }).where((entry) => entry.value > 0).toList();

    // 按分數排序（高到低）
    scoredProducts.sort((a, b) => b.value.compareTo(a.value));

    if (kDebugMode) {
      print('🔍 [DatabaseService] 找到 ${scoredProducts.length} 筆符合的商品');
      if (scoredProducts.isNotEmpty) {
        print('🔍 [DatabaseService] 前 3 筆結果（含分數）:');
        for (var i = 0; i < scoredProducts.length && i < 3; i++) {
          final entry = scoredProducts[i];
          print('   ${i + 1}. ${entry.key.name} (分數: ${entry.value}, 分類: ${entry.key.category})');
        }
      }
    }

    // 返回排序後的商品列表
    return scoredProducts.map((entry) => entry.key).toList();
  }

  // ==================== 購物車相關方法 ====================

  /// 取得所有購物車項目
  Future<List<CartItem>> getCartItems() async {
    final isar = await _isarFuture;
    return await isar.cartItems.where().findAll();
  }

  /// 加入商品到購物車
  /// 如果相同商品+規格已存在，則增加數量；否則新增項目
  Future<void> addToCart({
    required int productId,
    required String productName,
    required double price,
    required String specification,
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
          ..name = productName
          ..specification = specification
          ..unitPrice = price
          ..quantity = quantity
          ..isSelected = true; // 預設為選取狀態

        await isar.cartItems.put(newItem);
        if (kDebugMode) {
          print('🛒 [DatabaseService] 新增購物車項目: $productName ($specification) x$quantity');
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

    // 建立訂單
    final order = Order()
      ..orderNumber = orderNumber
      ..createdAt = DateTime.now()
      ..status = 'pending'
      ..subtotal = subtotal
      ..discount = discount
      ..shippingFee = shippingFee
      ..total = total
      ..couponId = couponId
      ..couponName = couponName
      ..shippingMethodId = shippingMethodId
      ..shippingMethodName = shippingMethodName
      ..paymentMethodId = paymentMethodId
      ..paymentMethodName = paymentMethodName;

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
        print('📦 [DatabaseService] 建立訂單: $orderNumber, 共 ${cartItems.length} 項商品, 總金額: \$${total.toStringAsFixed(0)}');
      }
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

  // 這裡還可以擴充其他 CRUD 方法...
}
