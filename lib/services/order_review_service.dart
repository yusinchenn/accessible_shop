import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../models/product.dart';
import '../models/product_review.dart';
import 'database_service.dart';

/// 訂單商品評論服務
class OrderReviewService {
  final DatabaseService _db;

  OrderReviewService(this._db);

  /// 評論有效期限（30天）
  static const int reviewValidDays = 30;

  /// 檢查訂單商品是否可以評論
  /// 規則：訂單完成後30天內可以評論
  Future<bool> canReviewOrder(int orderId) async {
    final isar = await _db.isar;
    final order = await isar.orders.get(orderId);

    if (order == null) return false;

    // 訂單必須是已完成狀態
    if (order.mainStatus != OrderMainStatus.completed) {
      return false;
    }

    // 獲取訂單完成時間
    final timestamps = await isar.orderStatusTimestamps
        .filter()
        .orderIdEqualTo(orderId)
        .findFirst();

    if (timestamps?.completedAt == null) return false;

    // 檢查是否在30天內
    final now = DateTime.now();
    final daysSinceCompleted = now.difference(timestamps!.completedAt!).inDays;

    return daysSinceCompleted <= reviewValidDays;
  }

  /// 檢查特定商品是否已經評論過
  Future<bool> hasReviewedProduct(int orderId, int productId) async {
    final isar = await _db.isar;
    final review = await isar.productReviews
        .filter()
        .orderIdEqualTo(orderId)
        .and()
        .productIdEqualTo(productId)
        .findFirst();

    return review != null;
  }

  /// 獲取訂單商品的現有評論
  Future<ProductReview?> getProductReview(int orderId, int productId) async {
    final isar = await _db.isar;
    return await isar.productReviews
        .filter()
        .orderIdEqualTo(orderId)
        .and()
        .productIdEqualTo(productId)
        .findFirst();
  }

  /// 獲取訂單中的所有商品
  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final isar = await _db.isar;
    final items = await isar.orderItems
        .filter()
        .orderIdEqualTo(orderId)
        .findAll();

    return items;
  }

  /// 創建商品評論
  /// orderId: 訂單 ID，必填
  /// productId: 商品 ID，必填
  /// rating: 評分 (1.0 - 5.0)，必填
  /// comment: 評論內容，選填
  Future<bool> createProductReview({
    required int orderId,
    required int productId,
    required double rating,
    String? comment,
    String userName = '匿名用戶',
  }) async {
    try {
      // 驗證評分範圍
      if (rating < 1.0 || rating > 5.0) {
        if (kDebugMode) {
          print('❌ [OrderReviewService] 評分必須在 1.0 - 5.0 之間');
        }
        return false;
      }

      final isar = await _db.isar;

      // 創建評論
      final review = ProductReview()
        ..orderId = orderId
        ..productId = productId
        ..userName = userName
        ..rating = rating
        ..comment = comment ?? ''
        ..createdAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.productReviews.put(review);
      });

      // 更新商品的平均評分和評論數
      await _updateProductRating(productId);

      if (kDebugMode) {
        print('✅ [OrderReviewService] 成功發布商品評論: 訂單ID $orderId, 商品ID $productId, 評分 $rating');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [OrderReviewService] 發布評論失敗: $e');
      }
      return false;
    }
  }

  /// 更新商品評論
  /// reviewId: 評論 ID
  /// rating: 新的評分 (1.0 - 5.0)
  /// comment: 新的評論內容
  Future<bool> updateProductReview({
    required int reviewId,
    required double rating,
    String? comment,
  }) async {
    try {
      // 驗證評分範圍
      if (rating < 1.0 || rating > 5.0) {
        if (kDebugMode) {
          print('❌ [OrderReviewService] 評分必須在 1.0 - 5.0 之間');
        }
        return false;
      }

      final isar = await _db.isar;
      final review = await isar.productReviews.get(reviewId);

      if (review == null) {
        if (kDebugMode) {
          print('❌ [OrderReviewService] 找不到評論 ID: $reviewId');
        }
        return false;
      }

      // 更新評論
      review.rating = rating;
      review.comment = comment ?? '';
      review.updatedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.productReviews.put(review);
      });

      // 更新商品的平均評分和評論數
      await _updateProductRating(review.productId);

      if (kDebugMode) {
        print('✅ [OrderReviewService] 成功更新商品評論: 評論ID $reviewId, 評分 $rating');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [OrderReviewService] 更新評論失敗: $e');
      }
      return false;
    }
  }

  /// 更新商品的平均評分和評論數
  Future<void> _updateProductRating(int productId) async {
    final isar = await _db.isar;
    final product = await isar.products.get(productId);

    if (product == null) return;

    // 獲取該商品的所有評論
    final reviews = await isar.productReviews
        .filter()
        .productIdEqualTo(productId)
        .findAll();

    if (reviews.isEmpty) return;

    // 計算平均評分
    final totalRating = reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
    final averageRating = totalRating / reviews.length;

    // 更新商品資訊
    await isar.writeTxn(() async {
      product.averageRating = averageRating;
      product.reviewCount = reviews.length;
      await isar.products.put(product);
    });

    if (kDebugMode) {
      print('✅ [OrderReviewService] 更新商品評分: 商品ID $productId, 平均評分 $averageRating, 評論數 ${reviews.length}');
    }
  }

  /// 獲取訂單的剩餘評論天數
  Future<int?> getRemainingDaysToReview(int orderId) async {
    final isar = await _db.isar;
    final order = await isar.orders.get(orderId);

    if (order == null || order.mainStatus != OrderMainStatus.completed) {
      return null;
    }

    final timestamps = await isar.orderStatusTimestamps
        .filter()
        .orderIdEqualTo(orderId)
        .findFirst();

    if (timestamps?.completedAt == null) return null;

    final now = DateTime.now();
    final daysSinceCompleted = now.difference(timestamps!.completedAt!).inDays;
    final remainingDays = reviewValidDays - daysSinceCompleted;

    return remainingDays > 0 ? remainingDays : 0;
  }
}
