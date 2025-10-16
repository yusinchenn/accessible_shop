import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:accessible_shop/utils/tts_helper.dart';
import 'package:accessible_shop/utils/app_constants.dart';
import 'package:accessible_shop/providers/auth_provider.dart';
import 'package:accessible_shop/widgets/global_gesture_wrapper.dart'; // 匯入全域手勢包裝器

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({Key? key}) : super(key: key);

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      ttsHelper.speak("進入帳號資訊頁面");
    });
  }

  @override
  void dispose() {
    ttsHelper.speak("離開帳號資訊頁面");
    super.dispose();
  }

  /// 登出確認對話框
  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認登出'),
        content: const Text('確定要登出嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('登出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        ttsHelper.speak("已登出");
        // 登出後會自動導向登入頁面（由 main.dart 的 Consumer 處理）
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return GlobalGestureScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('帳號資訊'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 使用者資訊卡片
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.teal,
                          child: Icon(
                            Icons.person,
                            size: 35,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '使用者資訊',
                                style: AppTextStyles.subtitle.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                authProvider.userEmail ?? '未登入',
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInfoRow('使用者 ID', authProvider.userId ?? '-'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInfoRow('電子郵件', authProvider.userEmail ?? '-'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 登出按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: authProvider.isLoading ? null : _showLogoutDialog,
                icon: authProvider.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.logout),
                label: Text(authProvider.isLoading ? '登出中...' : '登出'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 資訊列
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label：',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body,
          ),
        ),
      ],
    );
  }
}
