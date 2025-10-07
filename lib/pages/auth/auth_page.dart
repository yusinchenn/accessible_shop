import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_constants.dart';

/// 登入/註冊頁面
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool success;
    if (_isLoginMode) {
      success = await authProvider.signIn(email: email, password: password);
    } else {
      success = await authProvider.signUp(email: email, password: password);
    }

    if (!mounted) return;

    if (!success && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage!,
            style: AppTextStyles.body.copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      authProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isLoginMode ? '登入' : '註冊',
          style: AppTextStyles.title.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo 或標題
                  Icon(
                    Icons.shopping_bag,
                    size: 100,
                    color: AppColors.text,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Accessible Shop',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.extraLargeTitle.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),

                  // Email 輸入框
                  TextFormField(
                    controller: _emailController,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      labelText: '電子郵件',
                      labelStyle: AppTextStyles.body.copyWith(
                        color: AppColors.subtitle,
                      ),
                      prefixIcon: Icon(
                        Icons.email,
                        size: 28,
                        color: AppColors.text,
                      ),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.text, width: 2),
                      ),
                      errorStyle: AppTextStyles.small.copyWith(
                        color: Colors.red,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '請輸入電子郵件';
                      }
                      if (!value.contains('@')) {
                        return '請輸入有效的電子郵件';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppSpacing.md),

                  // 密碼輸入框
                  TextFormField(
                    controller: _passwordController,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      labelText: '密碼',
                      labelStyle: AppTextStyles.body.copyWith(
                        color: AppColors.subtitle,
                      ),
                      prefixIcon: Icon(
                        Icons.lock,
                        size: 28,
                        color: AppColors.text,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 28,
                          color: AppColors.text,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.text, width: 2),
                      ),
                      errorStyle: AppTextStyles.small.copyWith(
                        color: Colors.red,
                      ),
                    ),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '請輸入密碼';
                      }
                      if (value.length < 6) {
                        return '密碼至少需要 6 個字元';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // 登入/註冊按鈕
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.text,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: authProvider.isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                _isLoginMode ? '登入' : '註冊',
                                style: AppTextStyles.subtitle.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      );
                    },
                  ),
                  SizedBox(height: AppSpacing.md),

                  // 切換登入/註冊模式
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                        _formKey.currentState?.reset();
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    ),
                    child: Text(
                      _isLoginMode ? '還沒有帳號？立即註冊' : '已有帳號？立即登入',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // 忘記密碼（僅在登入模式顯示）
                  if (_isLoginMode)
                    TextButton(
                      onPressed: () => _showResetPasswordDialog(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      ),
                      child: Text(
                        '忘記密碼？',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.subtitle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 顯示重設密碼對話框
  void _showResetPasswordDialog() {
    final resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          '重設密碼',
          style: AppTextStyles.title,
        ),
        content: TextField(
          controller: resetEmailController,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            labelText: '電子郵件',
            labelStyle: AppTextStyles.body.copyWith(
              color: AppColors.subtitle,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.text, width: 2),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: AppTextStyles.body.copyWith(
                color: AppColors.subtitle,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) return;

              final authProvider = context.read<AuthProvider>();
              final success = await authProvider.sendPasswordResetEmail(email);

              if (!context.mounted) return;
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? '密碼重設郵件已發送' : authProvider.errorMessage!,
                    style: AppTextStyles.body.copyWith(color: Colors.white),
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: Text(
              '發送',
              style: AppTextStyles.body.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
