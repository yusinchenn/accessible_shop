import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore 服務
/// 負責處理用戶資料與錢包餘額的 Firebase 存取
///
/// ⚠️ 注意：此版本不使用 Cloud Functions（免費方案適用）
/// 安全性依賴 Firestore Transaction 和 Security Rules
class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== 用戶資料相關方法 ====================

  /// 取得用戶資料 (即時讀取)
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        if (kDebugMode) {
          print('👤 [FirestoreService] 讀取用戶資料: $userId');
        }
        return doc.data();
      } else {
        if (kDebugMode) {
          print('👤 [FirestoreService] 用戶資料不存在: $userId');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FirestoreService] 讀取用戶資料失敗: $e');
      }
      rethrow;
    }
  }

  /// 監聽用戶資料變更 (即時監聽)
  Stream<Map<String, dynamic>?> watchUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data();
      }
      return null;
    });
  }

  /// 建立或更新用戶資料
  Future<void> saveUserProfile({
    required String userId,
    String? displayName,
    String? email,
    DateTime? birthday,
    String? phoneNumber,
  }) async {
    try {
      final docRef = _firestore.collection('users').doc(userId);
      final doc = await docRef.get();

      if (!doc.exists) {
        // 建立新用戶資料
        await docRef.set({
          'userId': userId,
          'displayName': displayName,
          'email': email,
          'birthday': birthday?.toIso8601String(),
          'phoneNumber': phoneNumber,
          'walletBalance': 0.0,
          'membershipLevel': 'regular',
          'membershipPoints': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) {
          print('👤 [FirestoreService] 建立用戶資料: $userId');
        }
      } else {
        // 更新現有用戶資料（只更新提供的欄位）
        final updateData = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (displayName != null) updateData['displayName'] = displayName;
        if (email != null) updateData['email'] = email;
        if (birthday != null) updateData['birthday'] = birthday.toIso8601String();
        if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;

        await docRef.update(updateData);

        if (kDebugMode) {
          print('👤 [FirestoreService] 更新用戶資料: $userId');
        }
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FirestoreService] 儲存用戶資料失敗: $e');
      }
      rethrow;
    }
  }

  // ==================== 錢包相關方法 ====================

  /// 取得錢包餘額
  Future<double> getWalletBalance(String userId) async {
    try {
      final userData = await getUserProfile(userId);
      return (userData?['walletBalance'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FirestoreService] 取得錢包餘額失敗: $e');
      }
      return 0.0;
    }
  }

  /// 檢查今天是否已領取每日獎勵
  Future<bool> hasClaimedDailyReward(String userId) async {
    try {
      final userData = await getUserProfile(userId);

      if (userData == null || userData['lastDailyLogin'] == null) {
        return false;
      }

      final lastLogin = (userData['lastDailyLogin'] as Timestamp).toDate();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastLoginDate = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);

      return lastLoginDate.isAtSameMomentAs(today);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FirestoreService] 檢查每日獎勵狀態失敗: $e');
      }
      return false;
    }
  }

  /// 領取每日獎勵（簡化版：直接在客戶端操作）
  /// ⚠️ 注意：這個版本沒有 Cloud Functions 的伺服器端驗證
  /// 安全性依賴 Firestore Security Rules
  /// 回傳值：獎勵金額（0 表示今天已領取過或失敗）
  Future<double> claimDailyReward(String userId) async {
    try {
      final docRef = _firestore.collection('users').doc(userId);

      // 使用 Transaction 確保數據一致性
      return await _firestore.runTransaction<double>((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          if (kDebugMode) {
            print('❌ [FirestoreService] 用戶資料不存在');
          }
          return 0.0;
        }

        final userData = snapshot.data()!;
        final lastLogin = userData['lastDailyLogin'] as Timestamp?;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // 檢查今天是否已經領取過
        if (lastLogin != null) {
          final lastLoginDate = lastLogin.toDate();
          final lastLoginDay = DateTime(
            lastLoginDate.year,
            lastLoginDate.month,
            lastLoginDate.day,
          );

          if (lastLoginDay.isAtSameMomentAs(today)) {
            if (kDebugMode) {
              print('💰 [FirestoreService] 今天已經領取過每日獎勵');
            }
            return 0.0;
          }
        }

        // 每日獎勵金額
        const double dailyReward = 1.0;
        final currentBalance = (userData['walletBalance'] as num?)?.toDouble() ?? 0.0;
        final newBalance = currentBalance + dailyReward;

        // 更新用戶資料
        transaction.update(docRef, {
          'walletBalance': newBalance,
          'lastDailyLogin': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) {
          print('💰 [FirestoreService] 領取每日獎勵成功: +$dailyReward 元，新餘額: $newBalance');
        }

        notifyListeners();
        return dailyReward;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FirestoreService] 領取每日獎勵失敗: $e');
      }
      rethrow;
    }
  }

  /// 使用錢包餘額（扣款）- 簡化版：直接在客戶端操作
  /// ⚠️ 注意：這個版本沒有 Cloud Functions 的伺服器端驗證
  /// 安全性依賴 Firestore Security Rules
  /// 回傳值：是否成功
  Future<bool> useWalletBalance(String userId, double amount) async {
    try {
      if (amount <= 0) {
        if (kDebugMode) {
          print('💰 [FirestoreService] 扣款金額必須大於 0');
        }
        return false;
      }

      final docRef = _firestore.collection('users').doc(userId);

      // 使用 Transaction 確保數據一致性
      return await _firestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          if (kDebugMode) {
            print('❌ [FirestoreService] 用戶資料不存在');
          }
          return false;
        }

        final userData = snapshot.data()!;
        final currentBalance = (userData['walletBalance'] as num?)?.toDouble() ?? 0.0;

        // 檢查餘額是否足夠
        if (currentBalance < amount) {
          if (kDebugMode) {
            print('💰 [FirestoreService] 錢包餘額不足: 當前 $currentBalance，需要 $amount');
          }
          return false;
        }

        final newBalance = currentBalance - amount;

        // 更新用戶資料
        transaction.update(docRef, {
          'walletBalance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) {
          print('💰 [FirestoreService] 使用錢包餘額成功: -$amount 元，剩餘: $newBalance');
        }

        notifyListeners();
        return true;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FirestoreService] 使用錢包餘額失敗: $e');
      }
      return false;
    }
  }

  /// 監聽錢包餘額變更
  Stream<double> watchWalletBalance(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return (doc.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    });
  }

  // ==================== 開發工具 ====================

  /// 重置錢包餘額（僅供開發測試）
  /// ⚠️ 生產環境應該移除或透過 Cloud Functions 執行
  Future<void> resetWalletBalance(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'walletBalance': 0.0,
        'lastDailyLogin': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('💰 [FirestoreService] 已重置錢包餘額');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FirestoreService] 重置錢包餘額失敗: $e');
      }
      rethrow;
    }
  }
}
