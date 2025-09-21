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
  static const primary = Color(0xFF1976D2); // 主色
  static const accent = Color(0xFFFFA726); // 強調色
  static const background = Color(0xFFF5F5F5); // 背景色
  static const text = Color(0xFF222222); // 主要文字色
  static const subtitle = Color(0xFF666666); // 副標文字色
  // ...可自行擴充
}

/// 字體大小常數
class AppFontSizes {
  static const double title = 24;
  static const double subtitle = 18;
  static const double body = 16;
  static const double small = 13;
  // ...可自行擴充
}

/// 文字樣式
class AppTextStyles {
  static const title = TextStyle(
    fontSize: AppFontSizes.title,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );
  static const subtitle = TextStyle(
    fontSize: AppFontSizes.subtitle,
    color: AppColors.subtitle,
  );
  static const body = TextStyle(
    fontSize: AppFontSizes.body,
    color: AppColors.text,
  );
  // ...可自行擴充
}

/// 間距常數
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  // ...可自行擴充
}

/// 動畫時長
class AppDurations {
  static const short = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 300);
  static const long = Duration(milliseconds: 600);
}

// 你可以依需求再加上圓角、陰影、icon size...等常數
