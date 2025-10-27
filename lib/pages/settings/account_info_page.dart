import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:accessible_shop/utils/tts_helper.dart';
import 'package:accessible_shop/utils/app_constants.dart';
import 'package:accessible_shop/providers/auth_provider.dart';
import 'package:accessible_shop/services/database_service.dart';
import 'package:accessible_shop/models/user_profile.dart';
import 'package:accessible_shop/widgets/global_gesture_wrapper.dart';
import 'package:accessible_shop/services/accessibility_service.dart';
import 'package:intl/intl.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();

  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime? _selectedBirthday;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    Future.delayed(Duration.zero, () {
      // 只在自訂模式播放語音
      if (accessibilityService.shouldUseCustomTTS) {
        ttsHelper.speak("進入帳號資訊頁面");
      }
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// 載入使用者資料
  Future<void> _loadUserProfile() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final databaseService = context.read<DatabaseService>();
    final profile = await databaseService.getUserProfile(userId);

    if (profile != null) {
      setState(() {
        _userProfile = profile;
        _displayNameController.text = profile.displayName ?? '';
        _phoneController.text = profile.phoneNumber ?? '';
        _selectedBirthday = profile.birthday;
        _isLoading = false;
      });
    } else {
      // 如果沒有資料，建立初始資料
      final email = authProvider.userEmail;
      final newProfile = await databaseService.saveUserProfile(
        userId: userId,
        email: email,
      );

      setState(() {
        _userProfile = newProfile;
        _isLoading = false;
      });
    }
  }

  /// 儲存使用者資料
  Future<void> _saveUserProfile() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      final databaseService = context.read<DatabaseService>();
      await databaseService.saveUserProfile(
        userId: userId,
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
        email: authProvider.userEmail,
        birthday: _selectedBirthday,
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      if (mounted) {
        // 只在自訂模式播放語音
        if (accessibilityService.shouldUseCustomTTS) {
          ttsHelper.speak("已儲存");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('資料已儲存', style: TextStyle(fontSize: 18)),
            duration: Duration(seconds: 2),
          ),
        );

        // 重新載入資料
        await _loadUserProfile();
      }
    } catch (e) {
      if (mounted) {
        // 只在自訂模式播放語音
        if (accessibilityService.shouldUseCustomTTS) {
          ttsHelper.speak("儲存失敗");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('儲存失敗：$e', style: const TextStyle(fontSize: 18)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// 選擇生日
  Future<void> _selectBirthday() async {
    final initialDate = _selectedBirthday ?? DateTime(2000, 1, 1);
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('zh', 'TW'),
      builder: (context, child) {
        // 使用 MediaQuery 來調整字體大小，避免遮蔽 MaterialLocalizations
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.2),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedBirthday = pickedDate;
      });

      // 只在自訂模式播放語音
      if (accessibilityService.shouldUseCustomTTS) {
        final formattedDate = DateFormat('yyyy年M月d日').format(pickedDate);
        ttsHelper.speak("已選擇生日：$formattedDate");
      }
    }
  }

  /// 導航到錢包頁面
  Future<void> _navigateToWallet() async {
    await Navigator.pushNamed(context, '/wallet');
    // 從錢包頁面返回後重新載入資料，以更新餘額顯示
    await _loadUserProfile();
  }

  /// 登出確認對話框
  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認登出', style: TextStyle(fontSize: 24)),
        content: const Text('確定要登出嗎？', style: TextStyle(fontSize: 20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消', style: TextStyle(fontSize: 20)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('登出', style: TextStyle(color: Colors.red, fontSize: 20)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        // 只在自訂模式播放語音
        if (accessibilityService.shouldUseCustomTTS) {
          ttsHelper.speak("已登出");
        }
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
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 帳號資訊區塊
                  _buildSectionTitle('帳號資訊'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoCard([
                    _buildReadOnlyField('帳號 (Email)', authProvider.userEmail ?? '-'),
                    const SizedBox(height: AppSpacing.md),
                    _buildEditableField(
                      '使用者名稱',
                      _displayNameController,
                      '請輸入您的名稱',
                      Icons.person,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildBirthdayField(),
                    const SizedBox(height: AppSpacing.md),
                    _buildEditableField(
                      '手機號碼',
                      _phoneController,
                      '請輸入手機號碼',
                      Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildPasswordButton(),
                  ]),

                  const SizedBox(height: AppSpacing.lg),

                  // 儲存按鈕
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveUserProfile,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save, size: 24),
                      label: Text(
                        _isSaving ? '儲存中...' : '儲存資料',
                        style: const TextStyle(fontSize: 20),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 帳號功能區塊
                  _buildSectionTitle('帳號功能'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoCard([
                    _buildFunctionEntry(
                      '會員等級',
                      Icons.stars,
                      _userProfile?.membershipLevel?.toUpperCase() ?? 'REGULAR',
                      null, // 功能尚未實作
                    ),
                    const Divider(height: AppSpacing.lg),
                    _buildFunctionEntry(
                      '我的錢包',
                      Icons.account_balance_wallet,
                      '\$${_userProfile?.walletBalance?.toStringAsFixed(0) ?? '0'}',
                      _navigateToWallet, // 導航到錢包頁面
                    ),
                  ]),

                  const SizedBox(height: AppSpacing.xl),

                  // 登出按鈕
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: authProvider.isLoading ? null : _showLogoutDialog,
                      icon: authProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.logout, size: 24),
                      label: Text(
                        authProvider.isLoading ? '登出中...' : '登出',
                        style: const TextStyle(fontSize: 20),
                      ),
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

  /// 建立區段標題
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Text(
        title,
        style: AppTextStyles.subtitle.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.text,
        ),
      ),
    );
  }

  /// 建立資訊卡片
  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  /// 建立唯讀欄位
  Widget _buildReadOnlyField(String label, String value) {
    return GestureDetector(
      onTap: () {
        // 只在自訂模式播放語音
        if (accessibilityService.shouldUseCustomTTS) {
          ttsHelper.speak('$label：$value');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: AppColors.subtitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.email, size: 20, color: Colors.grey),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 建立可編輯欄位
  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: AppColors.subtitle,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(color: Colors.grey),
            prefixIcon: Icon(icon, size: 24),
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.divider, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.sm,
            ),
          ),
          onTap: () {
            // 只在自訂模式播放語音
            if (accessibilityService.shouldUseCustomTTS) {
              ttsHelper.speak('$label輸入框');
            }
          },
        ),
      ],
    );
  }

  /// 建立生日選擇欄位
  Widget _buildBirthdayField() {
    final displayText = _selectedBirthday != null
        ? DateFormat('yyyy-MM-dd').format(_selectedBirthday!)
        : '請選擇生日';

    return GestureDetector(
      onTap: () {
        // 單擊播報
        if (accessibilityService.shouldUseCustomTTS) {
          ttsHelper.speak('生日：$displayText');
        }
      },
      onDoubleTap: _selectBirthday, // 雙擊開啟選擇器
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '生日',
            style: AppTextStyles.body.copyWith(
              color: AppColors.subtitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cake,
                  size: 24,
                  color: _selectedBirthday != null ? AppColors.text : Colors.grey,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    displayText,
                    style: AppTextStyles.body.copyWith(
                      color: _selectedBirthday != null ? AppColors.text : Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 建立更改密碼按鈕
  Widget _buildPasswordButton() {
    return GestureDetector(
      onTap: () {
        // 單擊播報
        if (accessibilityService.shouldUseCustomTTS) {
          ttsHelper.speak('更改密碼');
        }
      },
      onDoubleTap: () {
        // 雙擊顯示提示（功能尚未實作）
        if (accessibilityService.shouldUseCustomTTS) {
          ttsHelper.speak('此功能尚未實作');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('此功能尚未實作', style: TextStyle(fontSize: 18)),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '更改密碼',
                style: AppTextStyles.body,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  /// 建立功能入口
  Widget _buildFunctionEntry(
    String title,
    IconData icon,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: () {
        // 單擊播報
        if (accessibilityService.shouldUseCustomTTS) {
          ttsHelper.speak('$title：$subtitle');
        }
      },
      onDoubleTap: onTap ?? () {
        // 雙擊顯示提示（功能尚未實作）
        if (accessibilityService.shouldUseCustomTTS) {
          ttsHelper.speak('此功能尚未實作');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('此功能尚未實作', style: TextStyle(fontSize: 18)),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 28, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.subtitle,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
