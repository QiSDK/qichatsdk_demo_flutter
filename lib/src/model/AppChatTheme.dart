//
//  AppChatTheme.dart
//  qichat_ui_sdk
//
//  聊天页主题配置:渐变背景 + 统一按钮着色 (与 iOS ChatTheme 对齐)
//

import 'dart:math';
import 'package:flutter/material.dart';

enum AppChatGradientDirection {
  topToBottom,
  bottomToTop,
  leftToRight,
  rightToLeft,
  topLeftToBottomRight,
  topRightToBottomLeft,
}

class AppChatTheme {
  /// 渐变起始颜色
  final Color gradientStartColor;

  /// 渐变结束颜色
  final Color gradientEndColor;

  /// 渐变方向
  final AppChatGradientDirection gradientDirection;

  /// 统一按钮 / 图标着色
  final Color tintColor;

  /// 左侧 (客服) 气泡背景色
  final Color leftBubbleColor;

  /// 左侧 (客服) 气泡文字色
  final Color leftBubbleTextColor;

  /// 右侧 (用户) 气泡背景色
  final Color rightBubbleColor;

  /// 右侧 (用户) 气泡文字色
  final Color rightBubbleTextColor;

  AppChatTheme({
    required this.gradientStartColor,
    required this.gradientEndColor,
    this.gradientDirection = AppChatGradientDirection.topToBottom,
    required this.tintColor,
    Color? leftBubbleColor,
    Color? leftBubbleTextColor,
    Color? rightBubbleColor,
    Color? rightBubbleTextColor,
  })  : leftBubbleColor =
            leftBubbleColor ?? const Color(0xFFFFFFFF).withOpacity(0.88),
        leftBubbleTextColor =
            leftBubbleTextColor ?? const Color(0xFF1A1A1A),
        rightBubbleColor =
            rightBubbleColor ?? tintColor.withOpacity(0.92),
        rightBubbleTextColor = rightBubbleTextColor ?? Colors.white;

  Alignment get gradientBegin {
    switch (gradientDirection) {
      case AppChatGradientDirection.topToBottom:
        return Alignment.topCenter;
      case AppChatGradientDirection.bottomToTop:
        return Alignment.bottomCenter;
      case AppChatGradientDirection.leftToRight:
        return Alignment.centerLeft;
      case AppChatGradientDirection.rightToLeft:
        return Alignment.centerRight;
      case AppChatGradientDirection.topLeftToBottomRight:
        return Alignment.topLeft;
      case AppChatGradientDirection.topRightToBottomLeft:
        return Alignment.topRight;
    }
  }

  Alignment get gradientEnd {
    switch (gradientDirection) {
      case AppChatGradientDirection.topToBottom:
        return Alignment.bottomCenter;
      case AppChatGradientDirection.bottomToTop:
        return Alignment.topCenter;
      case AppChatGradientDirection.leftToRight:
        return Alignment.centerRight;
      case AppChatGradientDirection.rightToLeft:
        return Alignment.centerLeft;
      case AppChatGradientDirection.topLeftToBottomRight:
        return Alignment.bottomRight;
      case AppChatGradientDirection.topRightToBottomLeft:
        return Alignment.bottomLeft;
    }
  }

  LinearGradient get linearGradient => LinearGradient(
        begin: gradientBegin,
        end: gradientEnd,
        colors: [gradientStartColor, gradientEndColor],
      );

  /// SDK 内置默认主题
  static final AppChatTheme defaultTheme = AppChatTheme(
    gradientStartColor: const Color.fromRGBO(242, 247, 255, 1.0),
    gradientEndColor: const Color.fromRGBO(204, 224, 255, 1.0),
    gradientDirection: AppChatGradientDirection.topToBottom,
    tintColor: const Color.fromRGBO(69, 137, 246, 1.0),
  );

  // MARK: - 精选主题预设

  /// 随机获取一个精选主题
  static AppChatTheme random() {
    if (presets.isEmpty) return defaultTheme;
    return presets[Random().nextInt(presets.length)];
  }

  /// 10 套精选主题 (与 iOS 对齐)
  static final List<AppChatTheme> presets = [
    // 1. 晴空蓝 (默认蓝系,清爽专业)
    AppChatTheme(
      gradientStartColor: const Color.fromRGBO(240, 247, 255, 1.0),
      gradientEndColor: const Color.fromRGBO(199, 224, 255, 1.0),
      gradientDirection: AppChatGradientDirection.bottomToTop,
      tintColor: const Color.fromRGBO(69, 137, 246, 1.0),
      leftBubbleColor: const Color.fromRGBO(240, 247, 255, 0.3),
      leftBubbleTextColor: const Color.fromRGBO(38, 38, 38, 1.0),
    ),
    // 2. 薄暮紫 (优雅渐变紫)
    AppChatTheme(
      gradientStartColor: const Color.fromRGBO(245, 237, 250, 1.0),
      gradientEndColor: const Color.fromRGBO(209, 184, 235, 1.0),
      tintColor: const Color.fromRGBO(128, 90, 210, 1.0),
      leftBubbleColor: const Color.fromRGBO(245, 237, 250, 0.3),
      leftBubbleTextColor: const Color.fromRGBO(38, 38, 38, 1.0),
    ),
    // 3. 蜜桃粉 (温暖柔和)
    AppChatTheme(
      gradientStartColor: const Color.fromRGBO(255, 245, 242, 1.0),
      gradientEndColor: const Color.fromRGBO(255, 217, 209, 1.0),
      gradientDirection: AppChatGradientDirection.bottomToTop,
      tintColor: const Color.fromRGBO(235, 105, 110, 1.0),
      leftBubbleColor: const Color.fromRGBO(255, 245, 242, 0.3),
      leftBubbleTextColor: const Color.fromRGBO(38, 38, 38, 1.0),
    ),
    // 4. 抹茶绿 (清新自然)
    AppChatTheme(
      gradientStartColor: const Color.fromRGBO(242, 250, 237, 1.0),
      gradientEndColor: const Color.fromRGBO(209, 237, 194, 1.0),
      tintColor: const Color.fromRGBO(76, 175, 80, 1.0),
      leftBubbleColor: const Color.fromRGBO(242, 250, 237, 0.3),
      leftBubbleTextColor: const Color.fromRGBO(38, 38, 38, 1.0),
    ),
    // 5. 日落橙 (活力暖色)
    AppChatTheme(
      gradientStartColor: const Color.fromRGBO(255, 247, 235, 1.0),
      gradientEndColor: const Color.fromRGBO(255, 224, 184, 1.0),
      gradientDirection: AppChatGradientDirection.bottomToTop,
      tintColor: const Color.fromRGBO(255, 152, 0, 1.0),
      leftBubbleColor: const Color.fromRGBO(255, 247, 235, 0.3),
      leftBubbleTextColor: const Color.fromRGBO(38, 38, 38, 1.0),
    ),
    // 6. 星空靛 (深邃高级感)
    AppChatTheme(
      gradientStartColor: const Color.fromRGBO(224, 230, 247, 1.0),
      gradientEndColor: const Color.fromRGBO(158, 173, 224, 1.0),
      tintColor: const Color.fromRGBO(63, 81, 181, 1.0),
      leftBubbleColor: const Color.fromRGBO(224, 230, 247, 0.3),
      leftBubbleTextColor: const Color.fromRGBO(38, 38, 38, 1.0),
    ),
    // 7. 暗夜紫 (深色优雅,高端质感)
    AppChatTheme(
      gradientStartColor: const Color.fromRGBO(199, 38, 107, 1.0),
      gradientEndColor: const Color.fromRGBO(31, 15, 61, 1.0),
      gradientDirection: AppChatGradientDirection.bottomToTop,
      tintColor: const Color.fromRGBO(148, 107, 242, 1.0),
      leftBubbleColor: const Color.fromRGBO(199, 38, 107, 0.3),
      leftBubbleTextColor: const Color.fromRGBO(230, 230, 230, 1.0),
      rightBubbleColor: const Color.fromRGBO(128, 89, 224, 0.92),
      rightBubbleTextColor: const Color.fromRGBO(255, 255, 255, 0.95),
    ),
    // 8. 极简灰 (纯色背景,干净利落)
    AppChatTheme(
      gradientStartColor: const Color.fromRGBO(246, 247, 250, 1.0),
      gradientEndColor: const Color.fromRGBO(246, 247, 250, 1.0),
      tintColor: const Color.fromRGBO(55, 120, 244, 1.0),
      leftBubbleColor: const Color.fromRGBO(255, 255, 255, 0.92),
      leftBubbleTextColor: const Color.fromRGBO(38, 38, 38, 1.0),
      rightBubbleColor: const Color.fromRGBO(55, 120, 244, 0.92),
      rightBubbleTextColor: const Color.fromRGBO(255, 255, 255, 0.95),
    ),
    // 9. 幻夜紫 (深紫渐变,神秘高级)
    AppChatTheme(
      gradientStartColor: const Color.fromRGBO(165, 150, 187, 1.0),
      gradientEndColor: const Color.fromRGBO(31, 31, 76, 1.0),
      gradientDirection: AppChatGradientDirection.bottomToTop,
      tintColor: const Color.fromRGBO(155, 120, 240, 1.0),
      leftBubbleColor: const Color.fromRGBO(165, 150, 187, 0.3),
      leftBubbleTextColor: const Color.fromRGBO(230, 230, 230, 1.0),
      rightBubbleColor: const Color.fromRGBO(120, 85, 210, 0.90),
      rightBubbleTextColor: const Color.fromRGBO(255, 255, 255, 0.95),
    ),
    // 10. 晨雾白 (极淡渐变,干净柔和)
    AppChatTheme(
      gradientStartColor: const Color.fromRGBO(252, 250, 252, 1.0),
      gradientEndColor: const Color.fromRGBO(220, 232, 244, 1.0),
      gradientDirection: AppChatGradientDirection.topLeftToBottomRight,
      tintColor: const Color.fromRGBO(120, 140, 210, 1.0),
      leftBubbleColor: const Color.fromRGBO(255, 255, 255, 0.55),
      leftBubbleTextColor: const Color.fromRGBO(46, 46, 46, 1.0),
    ),
  ];
}
