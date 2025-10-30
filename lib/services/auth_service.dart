import 'package:firebase_auth/firebase_auth.dart';

/// Firebase 身份驗證服務
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 取得當前使用者
  User? get currentUser => _auth.currentUser;

  /// 監聽身份驗證狀態變化
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 使用 Email 和密碼註冊
  Future<UserCredential?> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// 使用 Email 和密碼登入
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// 登出
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// 發送密碼重設郵件
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// 處理 Firebase Auth 例外
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return '密碼強度不足，請使用至少 6 個字元';
      case 'email-already-in-use':
        return '此電子郵件已被註冊';
      case 'invalid-email':
        return '電子郵件格式不正確';
      case 'user-not-found':
        return '找不到此使用者，請確認電子郵件是否正確';
      case 'wrong-password':
        return '密碼錯誤，請重新輸入';
      case 'invalid-credential':
        return '登入資訊不正確，請檢查電子郵件和密碼';
      case 'invalid-verification-code':
        return '驗證碼無效';
      case 'invalid-verification-id':
        return '驗證 ID 無效';
      case 'user-disabled':
        return '此帳號已被停用';
      case 'too-many-requests':
        return '嘗試次數過多，請稍後再試';
      case 'operation-not-allowed':
        return '此登入方式未啟用，請聯繫管理員';
      case 'expired-action-code':
        return '驗證碼已過期，請重新申請';
      case 'invalid-action-code':
        return '驗證碼無效或已使用';
      case 'network-request-failed':
        return '網路連線失敗，請檢查網路狀態';
      case 'requires-recent-login':
        return '此操作需要重新登入';
      default:
        return '登入失敗：${e.message ?? '未知錯誤'}';
    }
  }
}
