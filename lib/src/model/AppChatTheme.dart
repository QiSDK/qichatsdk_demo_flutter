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

/// 气泡阴影配置 (对齐 iOS `ChatTheme.BubbleShadow`)
class BubbleShadow {
  final Color color;
  final double opacity;
  final double radius;
  final Offset offset;

  const BubbleShadow({
    required this.color,
    required this.opacity,
    required this.radius,
    required this.offset,
  });

  List<BoxShadow> toBoxShadows() {
    if (opacity == 0 || radius == 0) return [];
    return [
      BoxShadow(
        color: color.withOpacity(opacity),
        blurRadius: radius,
        offset: offset,
      ),
    ];
  }

  static const BubbleShadow defaultShadow = BubbleShadow(
    color: Colors.black,
    opacity: 0.06,
    radius: 6,
    offset: Offset(0, 2),
  );

  static const BubbleShadow none = BubbleShadow(
    color: Colors.transparent,
    opacity: 0,
    radius: 0,
    offset: Offset.zero,
  );
}

class AppChatTheme {
  /// 渐变起始颜色
  final Color gradientStartColor;

  /// 渐变结束颜色
  final Color gradientEndColor;

  /// 渐变方向
  final AppChatGradientDirection gradientDirection;

  /// 统一按钮 / 图标着色 (返回按钮、发送按钮、附件图标等)
  final Color tintColor;

  /// 左侧 (客服) 气泡背景色, 半透明让渐变背景透出来, 与背景融合
  final Color leftBubbleColor;

  /// 左侧 (客服) 气泡文字色
  final Color leftBubbleTextColor;

  /// 右侧 (用户) 气泡背景色, 默认从 tintColor 派生
  final Color rightBubbleColor;

  /// 右侧 (用户) 气泡文字色
  final Color rightBubbleTextColor;

  /// 气泡阴影
  final BubbleShadow bubbleShadow;

  AppChatTheme({
    required this.gradientStartColor,
    required this.gradientEndColor,
    this.gradientDirection = AppChatGradientDirection.topToBottom,
    required this.tintColor,
    Color? leftBubbleColor,
    Color? leftBubbleTextColor,
    Color? rightBubbleColor,
    Color? rightBubbleTextColor,
    BubbleShadow? bubbleShadow,
  })  : leftBubbleColor =
            leftBubbleColor ?? const Color(0xFFFFFFFF).withOpacity(0.88),
        leftBubbleTextColor =
            leftBubbleTextColor ?? const Color(0xFF1A1A1A),
        rightBubbleColor =
            rightBubbleColor ?? tintColor.withOpacity(0.92),
        rightBubbleTextColor = rightBubbleTextColor ?? Colors.white,
        bubbleShadow = bubbleShadow ?? BubbleShadow.defaultShadow;

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

  /// 11 套精选主题 (与 iOS `ChatTheme.presets` 对齐)
  static final List<AppChatTheme> presets = [
    // 1. 晨雾白 (极淡渐变,干净柔和)
    AppChatTheme(
      gradientStartColor: const Color.fromRGBO(252, 250, 252, 1.0),
      gradientEndColor: const Color.fromRGBO(220, 232, 244, 1.0),
      gradientDirection: AppChatGradientDirection.topLeftToBottomRight,
      tintColor: const Color.fromRGBO(120, 140, 210, 1.0),
      leftBubbleColor: const Color.fromRGBO(255, 255, 255, 0.55),
      leftBubbleTextColor: const Color.fromRGBO(46, 46, 46, 1.0),
    ),
    // 2. 暗夜神殿 (深紫渐变,神秘氛围)
    AppChatTheme(
      gradientStartColor: const Color.fromRGBO(74, 62, 112, 1.0),
      gradientEndColor: const Color.fromRGBO(28, 22, 62, 1.0),
      gradientDirection: AppChatGradientDirection.topToBottom,
      tintColor: const Color.fromRGBO(155, 120, 240, 1.0),
      leftBubbleColor: const Color.fromRGBO(60, 50, 95, 0.72),
      leftBubbleTextColor: const Color.fromRGBO(242, 242, 242, 1.0),
      rightBubbleColor: const Color.fromRGBO(130, 95, 220, 0.92),
      rightBubbleTextColor: const Color.fromRGBO(255, 255, 255, 0.98),
    ),
    // 3. 蜜桃粉 (温暖柔和)
    AppChatTheme(
      gradientStartColor: const Color.fromRGBO(255, 245, 242, 1.0),
      gradientEndColor: const Color.fromRGBO(255, 217, 209, 1.0),
      gradientDirection: AppChatGradientDirection.bottomToTop,
      tintColor: const Color.fromRGBO(235, 105, 110, 1.0),
      leftBubbleColor: const Color.fromRGBO(255, 245, 242, 0.65),
      leftBubbleTextColor: const Color.fromRGBO(38, 38, 38, 1.0),
    ),
    // 4. 抹茶绿 (清新自然)
    AppChatTheme(
      gradientStartColor: const Color.fromRGBO(242, 250, 237, 1.0),
      gradientEndColor: const Color.fromRGBO(209, 237, 194, 1.0),
      tintColor: const Color.fromRGBO(76, 175, 80, 1.0),
      leftBubbleColor: const Color.fromRGBO(242, 250, 237, 0.5),
      leftBubbleTextColor: const Color.fromRGBO(38, 38, 38, 1.0),
    ),
    // 5. 日落橙 (活力暖色)
    AppChatTheme(
      gradientStartColor: const Color.fromRGBO(255, 247, 235, 1.0),
      gradientEndColor: const Color.fromRGBO(255, 224, 184, 1.0),
      gradientDirection: AppChatGradientDirection.bottomToTop,
      tintColor: const Color.fromRGBO(255, 152, 0, 1.0),
      leftBubbleColor: const Color.fromRGBO(255, 247, 235, 0.6),
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
    // 10. 晴空蓝 (默认蓝系,清爽专业)
    AppChatTheme(
      gradientStartColor: const Color.fromRGBO(240, 247, 255, 1.0),
      gradientEndColor: const Color.fromRGBO(199, 224, 255, 1.0),
      gradientDirection: AppChatGradientDirection.bottomToTop,
      tintColor: const Color.fromRGBO(69, 137, 246, 1.0),
      leftBubbleColor: const Color.fromRGBO(240, 247, 255, 0.6),
      leftBubbleTextColor: const Color.fromRGBO(38, 38, 38, 1.0),
    ),
    // 11. 薄暮紫 (优雅渐变紫)
    AppChatTheme(
      gradientStartColor: const Color.fromRGBO(245, 237, 250, 1.0),
      gradientEndColor: const Color.fromRGBO(209, 184, 235, 1.0),
      tintColor: const Color.fromRGBO(128, 90, 210, 1.0),
      leftBubbleColor: const Color.fromRGBO(245, 237, 250, 0.3),
      leftBubbleTextColor: const Color.fromRGBO(38, 38, 38, 1.0),
    ),
  ];
}

/// 实现该 mixin 的 Widget 可接收主题 (对齐 iOS `ChatThemable` 协议)
mixin ChatThemable {
  void applyTheme(AppChatTheme theme);
}
