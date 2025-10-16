// lib/pages/orders/order_history_page.dart
//
// 訂單歷史頁 (暫時以空/有資料 flag 示範)

import 'package:flutter/material.dart';
import 'package:accessible_shop/utils/tts_helper.dart';
import 'package:accessible_shop/utils/app_constants.dart';
import 'package:accessible_shop/widgets/global_gesture_wrapper.dart'; // 匯入全域手勢包裝器

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({Key? key}) : super(key: key);

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  // 若未來有自訂返回按鈕，請於返回前加上：
  // await ttsHelper.stop();
  final bool _hasOrders = false; // 開發測試改成 true 可顯示範例

  @override
  void initState() {
    super.initState();
    _speakEnterPage();
  }

  Future<void> _speakEnterPage() async {
    await ttsHelper.speak("進入訂單頁面");
  }

  // 不要在這裡呼叫 ttsHelper.dispose()，全域單例不需釋放

  @override
  Widget build(BuildContext context) {
    return GlobalGestureScaffold(
      backgroundColor: AppColors.background, // 套用背景色
      appBar: AppBar(title: const Text('歷史訂單')),
      body: _hasOrders
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: const [
                ListTile(
                  title: Text('訂單 #20250901', style: AppTextStyles.body),
                  subtitle: Text('2025-09-01'),
                  trailing: Text('\$129.99', style: AppTextStyles.body),
                ),
                Divider(),
                ListTile(
                  title: Text('訂單 #20250815', style: AppTextStyles.body),
                  subtitle: Text('2025-08-15'),
                  trailing: Text('\$79.99', style: AppTextStyles.body),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.list_alt, size: 80, color: AppColors.primary),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    '目前沒有訂單',
                    style: AppTextStyles.subtitle,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    '你的訂單紀錄會出現在這裡。',
                    style: TextStyle(color: AppColors.subtitle),
                  ),
                ],
              ),
            ),
    );
  }
}
