// lib/utils/app_constants.dart
//
// 全域常數與樣式設定範本
//
// 你可以在這裡集中管理 app 會用到的顏色、字體大小、間距、動畫時長等常數，
// 方便全專案統一調整與維護。
//
// 使用方式：
//   import 'package:accessible_shop/utils/app_constants.dart';
//   Text('標題', style: AppTextStyles.title)
//   SizedBox(height: AppSpacing.lg)

import 'package:flutter/material.dart';

/// 顏色常數
class AppColors {
  static const primary_1 = Color(0xFFFFF8F0);
  static const secondery_1 = Color(0xFF6ea4bb);
  static const accent_1 = Color(0xFFbc6546);
  static const background_1 = Color(0xFFbf9e71);
  static const text_1 = Color(0xFF3b3425);
  static const subtitle_1 = Color(0xFF707070);
  static const blockBackground_1 = Color(0xFFbed7d1);
  static const cardBackground_1 = Color(0xFFFFF8F0);
  static const botton_1 = Color(0xFF3b3425);
  static const bottonText_1 = Color(0xFFFFF8F0);

  static const primary_2 = Color(0xFFbf9e71);
  static const secondery_2 = Color(0xFF6ea4bb);
  static const accent_2 = Color(0xFFbc6546);
  static const background_2 = Color(0xFFFFF8F0);
  static const text_2 = Color(0xFF3b3425);
  static const subtitle_2 = Color(0xFF707070);
  static const blockBackground_2 = Color(0xFFbed7d1);
  static const botton_2 = Color(0xFFbf9e71);
  static const bottonText_2 = Color(0xFFFFF8F0);

  static const aiBackground = Color(0xFFDFE9F1);
}

/// 字體大小常數 (針對年長者優化，字體加大)
class AppFontSizes {
  static const double extraLarge = 32; // 特大標題
  static const double title = 28; // 標題 (原 24 -> 28)
  static const double subtitle = 24; // 副標題 (原 18 -> 24)
  static const double body = 20; // 內文 (原 16 -> 20)
  static const double small = 18; // 小字 (原 13 -> 18)
  // ...可自行擴充
}

/// 間距常數 (針對年長者優化，增加間距)
class AppSpacing {
  static const double xs = 6; // 原 4 -> 6
  static const double sm = 12; // 原 8 -> 12
  static const double md = 20; // 原 16 -> 20
  static const double lg = 28; // 原 24 -> 28
  static const double xl = 40; // 原 32 -> 40
  // ...可自行擴充
}

/// 動畫時長
class AppDurations {
  static const Duration short = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 600);
  static const Duration long = Duration(milliseconds: 900);
}

// 你可以依需求再加上圓角、陰影、icon size...等常數
class AppBorders {
  // 輸入框
  static const double inputBorderRadius = 12.0;
  // 按鈕
  static const double buttonBorderRadius = 24.0;
}

/// 文字樣式常數 (使用 AppFontSizes 和 AppColors)
class AppTextStyles {
  // 特大標題
  static const TextStyle extraLargeTitle = TextStyle(
    fontSize: AppFontSizes.extraLarge,
    fontWeight: FontWeight.bold,
    color: AppColors.text_1,
  );

  // 標題
  static const TextStyle title = TextStyle(
    fontSize: AppFontSizes.title,
    fontWeight: FontWeight.bold,
    color: AppColors.text_1,
  );

  // 副標題
  static const TextStyle subtitle = TextStyle(
    fontSize: AppFontSizes.subtitle,
    fontWeight: FontWeight.w500,
    color: AppColors.subtitle_1,
  );

  // 內文
  static const TextStyle body = TextStyle(
    fontSize: AppFontSizes.body,
    fontWeight: FontWeight.normal,
    color: AppColors.text_1,
  );

  // 小字
  static const TextStyle small = TextStyle(
    fontSize: AppFontSizes.small,
    fontWeight: FontWeight.normal,
    color: AppColors.subtitle_1,
  );
}

/// 統一的顏色別名 (預設使用第一組配色方案)
/// 如需切換配色方案，請修改這裡的映射
extension AppColorsAlias on AppColors {
  // 主要顏色
  static const Color primary = AppColors.primary_1;
  static const Color accent = AppColors.accent_1;
  static const Color background = AppColors.background_1;

  // 文字顏色
  static const Color text = AppColors.text_1;
  static const Color subtitle = AppColors.subtitle_1;

  // 卡片顏色
  static const Color cardBackground = AppColors.cardBackground_1;
  static const Color cardText = AppColors.text_1;
  static const Color cardSubtitle = AppColors.subtitle_1;

  // 按鈕顏色
  static const Color button = AppColors.botton_1;
  static const Color buttonText = AppColors.bottonText_1;

  // 分隔線顏色
  static const Color divider = AppColors.subtitle_1;
}
