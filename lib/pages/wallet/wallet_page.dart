import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:accessible_shop/utils/tts_helper.dart';
import 'package:accessible_shop/utils/app_constants.dart';
import 'package:accessible_shop/providers/auth_provider.dart';
import 'package:accessible_shop/services/database_service.dart';
import 'package:accessible_shop/models/user_profile.dart';
import 'package:accessible_shop/widgets/global_gesture_wrapper.dart';
import 'package:accessible_shop/services/accessibility_service.dart';
import 'package:accessible_shop/widgets/accessible_gesture_wrapper.dart';
import 'package:intl/intl.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isClaiming = false;
  bool _hasClaimedToday = false;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
    Future.delayed(Duration.zero, () {
      // 只在自訂模式播放語音
      if (accessibilityService.shouldUseCustomTTS) {
        ttsHelper.speak("進入錢包頁面");
      }
    });
  }

  /// 載入錢包資料
  Future<void> _loadWalletData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final databaseService = context.read<DatabaseService>();
    final profile = await databaseService.getUserProfile(userId);
    final hasClaimed = await databaseService.hasClaimedDailyReward(userId);

    if (mounted) {
      setState(() {
        _userProfile = profile;
        _hasClaimedToday = hasClaimed;
        _isLoading = false;
      });
    }
  }

  /// 領取每日獎勵
  Future<void> _claimDailyReward() async {
    if (_isClaiming || _hasClaimedToday) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    if (userId == null) return;

    setState(() => _isClaiming = true);

    try {
      final databaseService = context.read<DatabaseService>();
      final reward = await databaseService.claimDailyReward(userId);

      if (reward > 0) {
        // 重新載入資料
        await _loadWalletData();

        if (mounted) {
          // 只在自訂模式播放語音
          if (accessibilityService.shouldUseCustomTTS) {
            ttsHelper.speak("領取成功，獲得 ${reward.toStringAsFixed(0)} 元");
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '領取成功！獲得 \$${reward.toStringAsFixed(0)} 元',
                style: const TextStyle(fontSize: 18),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          // 只在自訂模式播放語音
          if (accessibilityService.shouldUseCustomTTS) {
            ttsHelper.speak("今天已經領取過了");
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('今天已經領取過了', style: TextStyle(fontSize: 18)),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // 只在自訂模式播放語音
        if (accessibilityService.shouldUseCustomTTS) {
          ttsHelper.speak("領取失敗");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('領取失敗：$e', style: const TextStyle(fontSize: 18)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background_2,
      appBar: AppBar(
        title: const Text('我的錢包'),
        backgroundColor: AppColors.background_2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 錢包餘額卡片
                  _buildBalanceCard(),
                  const SizedBox(height: AppSpacing.lg),

                  // 每日登入獎勵區塊
                  _buildDailyRewardSection(),
                  const SizedBox(height: AppSpacing.lg),

                  // 使用說明
                  _buildInstructionsSection(),
                ],
              ),
            ),
    );
  }

  /// 建立餘額卡片
  Widget _buildBalanceCard() {
    final balance = _userProfile?.walletBalance ?? 0.0;

    return AccessibleGestureWrapper(
      label: '當前錢包餘額 ${balance.toStringAsFixed(0)} 元',
      onTap: () {},
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary_2,
                AppColors.primary_2.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    '錢包餘額',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppFontSizes.subtitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '\$${balance.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                '可用於購物折抵',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: AppFontSizes.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 建立每日獎勵區塊
  Widget _buildDailyRewardSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard, color: AppColors.primary_2, size: 28),
                const SizedBox(width: AppSpacing.sm),
                const Text('每日登入獎勵', style: AppTextStyles.subtitle),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('每天登入可領取 1 元獎勵', style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.sm),
            if (_userProfile?.lastDailyRewardDate != null)
              Text(
                '上次領取時間：${DateFormat('yyyy-MM-dd HH:mm').format(_userProfile!.lastDailyRewardDate!)}',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.subtitle_2,
                  fontSize: AppFontSizes.small,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: AccessibleGestureWrapper(
                label: _hasClaimedToday ? '今天已領取' : '領取今日獎勵',
                description: _hasClaimedToday ? '今天已經領取過了' : '點擊領取 1 元獎勵',
                enabled: !_hasClaimedToday && !_isClaiming,
                onTap: _hasClaimedToday || _isClaiming
                    ? null
                    : _claimDailyReward,
                child: ElevatedButton.icon(
                  onPressed: _hasClaimedToday || _isClaiming
                      ? null
                      : _claimDailyReward,
                  icon: _isClaiming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          _hasClaimedToday
                              ? Icons.check_circle
                              : Icons.card_giftcard,
                          size: 24,
                        ),
                  label: Text(
                    _isClaiming
                        ? '領取中...'
                        : _hasClaimedToday
                        ? '今天已領取'
                        : '領取今日獎勵',
                    style: const TextStyle(fontSize: 20),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasClaimedToday
                        ? Colors.grey
                        : AppColors.primary_2,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 建立使用說明區塊
  Widget _buildInstructionsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary_2, size: 28),
                const SizedBox(width: AppSpacing.sm),
                const Text('使用說明', style: AppTextStyles.subtitle),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildInstructionItem('每日登入可獲得 1 元獎勵'),
            _buildInstructionItem('獎勵每天只能領取一次'),
            _buildInstructionItem('錢包餘額可在結帳時折抵訂單金額'),
            _buildInstructionItem('折抵金額不可超過訂單總金額'),
          ],
        ),
      ),
    );
  }

  /// 建立說明項目
  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
