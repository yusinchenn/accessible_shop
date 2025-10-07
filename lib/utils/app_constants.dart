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
  static const primary = Color(0xFFD4A574); // 主色 - 杏色
  static const accent = Color(0xFFF5DEB3); // 強調色 - 淺杏色
  static const background = Color(0xFFD4A574); // 背景色 - 杏色
  static const text = Color(0xFF3A3A3A); // 主要文字色 - 深灰
  static const subtitle = Color(0xFF707070); // 副標文字色 - 中灰
  static const cardBackground = Color(0xFFFFF8F0); // 卡片背景 - 淡杏色
  static const divider = Color(0xFFE0E0E0); // 分隔線 - 淺灰
  // ...可自行擴充
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

/// 文字樣式 (針對年長者優化，增加行距和字重)
class AppTextStyles {
  static const extraLargeTitle = TextStyle(
    fontSize: AppFontSizes.extraLarge,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
    height: 1.4, // 增加行距
  );
  static const title = TextStyle(
    fontSize: AppFontSizes.title,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
    height: 1.4, // 增加行距
  );
  static const subtitle = TextStyle(
    fontSize: AppFontSizes.subtitle,
    fontWeight: FontWeight.w600, // 加粗副標題
    color: AppColors.subtitle,
    height: 1.4,
  );
  static const body = TextStyle(
    fontSize: AppFontSizes.body,
    color: AppColors.text,
    height: 1.5, // 增加行距提升可讀性
  );
  static const small = TextStyle(
    fontSize: AppFontSizes.small,
    color: AppColors.subtitle,
    height: 1.4,
  );
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
  static const short = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 300);
  static const long = Duration(milliseconds: 600);
}

// 你可以依需求再加上圓角、陰影、icon size...等常數
