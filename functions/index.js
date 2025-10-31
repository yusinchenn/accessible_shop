/**
 * Cloud Functions for Firebase - 錢包功能
 *
 * 安裝指令：
 * 1. cd functions
 * 2. npm install
 *
 * 部署指令：
 * firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * 每日登入獎勵
 *
 * 使用方式（Flutter）：
 * ```dart
 * final callable = FirebaseFunctions.instance.httpsCallable('addDailyReward');
 * final result = await callable.call();
 * final walletBalance = result.data['walletBalance'];
 * final reward = result.data['reward'];
 * ```
 */
exports.addDailyReward = functions.https.onCall(async (data, context) => {
  // 檢查身份驗證
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated.'
    );
  }

  const uid = context.auth.uid;
  const userRef = admin.firestore().collection('users').doc(uid);

  try {
    // 使用 transaction 確保數據一致性
    const result = await admin.firestore().runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'User profile not found.'
        );
      }

      const userData = userDoc.data();
      const lastLogin = userData.lastDailyLogin?.toDate();
      const today = new Date();

      // 重置時間到當天 00:00:00 以便比較
      today.setHours(0, 0, 0, 0);

      let sameDay = false;
      if (lastLogin) {
        const lastLoginDate = new Date(lastLogin);
        lastLoginDate.setHours(0, 0, 0, 0);
        sameDay = lastLoginDate.getTime() === today.getTime();
      }

      if (sameDay) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Already claimed today.'
        );
      }

      // 每日獎勵金額
      const dailyReward = 1.0;
      const currentBalance = userData.walletBalance || 0;
      const newBalance = currentBalance + dailyReward;

      // 更新用戶資料
      transaction.update(userRef, {
        walletBalance: newBalance,
        lastDailyLogin: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        walletBalance: newBalance,
        reward: dailyReward,
      };
    });

    console.log(`User ${uid} claimed daily reward: ${result.reward}`);
    return result;
  } catch (error) {
    console.error('Error in addDailyReward:', error);
    throw error;
  }
});

/**
 * 使用錢包餘額（扣款）
 *
 * 使用方式（Flutter）：
 * ```dart
 * final callable = FirebaseFunctions.instance.httpsCallable('useWalletBalance');
 * final result = await callable.call({'amount': 50.0});
 * final success = result.data['success'];
 * final newBalance = result.data['walletBalance'];
 * ```
 */
exports.useWalletBalance = functions.https.onCall(async (data, context) => {
  // 檢查身份驗證
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated.'
    );
  }

  const uid = context.auth.uid;
  const amount = data.amount;

  // 驗證金額
  if (typeof amount !== 'number' || amount <= 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Amount must be a positive number.'
    );
  }

  const userRef = admin.firestore().collection('users').doc(uid);

  try {
    // 使用 transaction 確保數據一致性
    const result = await admin.firestore().runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'User profile not found.'
        );
      }

      const userData = userDoc.data();
      const currentBalance = userData.walletBalance || 0;

      // 檢查餘額是否足夠
      if (currentBalance < amount) {
        return {
          success: false,
          walletBalance: currentBalance,
          message: 'Insufficient balance',
        };
      }

      const newBalance = currentBalance - amount;

      // 更新用戶資料
      transaction.update(userRef, {
        walletBalance: newBalance,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        walletBalance: newBalance,
        message: 'Payment successful',
      };
    });

    console.log(`User ${uid} used wallet balance: ${amount}, success: ${result.success}`);
    return result;
  } catch (error) {
    console.error('Error in useWalletBalance:', error);
    throw error;
  }
});

/**
 * 管理員功能：增加用戶餘額
 *
 * ⚠️ 此函數應該只允許管理員調用
 * 建議在 Firestore Rules 或 Custom Claims 中設定管理員權限
 */
exports.adminAddBalance = functions.https.onCall(async (data, context) => {
  // 檢查身份驗證
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated.'
    );
  }

  // TODO: 檢查是否為管理員
  // 可以使用 Custom Claims 或檢查特定管理員 UID
  // if (!context.auth.token.admin) {
  //   throw new functions.https.HttpsError(
  //     'permission-denied',
  //     'Only admins can add balance.'
  //   );
  // }

  const targetUserId = data.userId;
  const amount = data.amount;

  // 驗證參數
  if (!targetUserId || typeof amount !== 'number') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'userId and amount are required.'
    );
  }

  const userRef = admin.firestore().collection('users').doc(targetUserId);

  try {
    const result = await admin.firestore().runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Target user not found.'
        );
      }

      const userData = userDoc.data();
      const currentBalance = userData.walletBalance || 0;
      const newBalance = currentBalance + amount;

      transaction.update(userRef, {
        walletBalance: newBalance,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        walletBalance: newBalance,
      };
    });

    console.log(`Admin ${context.auth.uid} added ${amount} to user ${targetUserId}`);
    return result;
  } catch (error) {
    console.error('Error in adminAddBalance:', error);
    throw error;
  }
});
