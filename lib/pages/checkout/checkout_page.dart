import 'package:flutter/material.dart';
import '../../utils/app_constants.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // 套用背景色
      appBar: AppBar(title: const Text("💳 結帳")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: const Text(
            "這裡是結帳頁面",
            style: AppTextStyles.subtitle,
          ),
        ),
      ),
    );
  }
}
