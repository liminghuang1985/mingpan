import 'package:flutter/material.dart';

/// 响应式布局工具类
/// 
/// 提供屏幕断点检测和自适应布局辅助
class Responsive {
  /// 手机端断点
  static const double mobileBreakpoint = 600;
  
  /// 平板断点
  static const double tabletBreakpoint = 900;
  
  /// 桌面端断点
  static const double desktopBreakpoint = 1200;
  
  /// 判断是否为手机端
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }
  
  /// 判断是否为平板端
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }
  
  /// 判断是否为桌面端
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }
  
  /// 获取响应式值
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }
  
  /// 获取安全的最大宽度（避免在大屏幕上过宽）
  static double getMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return 1200;
    }
    return width;
  }
  
  /// 获取命盘大小（根据屏幕尺寸自适应）
  static double getMingPanSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    
    if (shortestSide < 360) {
      return shortestSide * 0.85;
    } else if (shortestSide < 600) {
      return shortestSide * 0.88;
    } else if (shortestSide < 900) {
      return shortestSide * 0.70;
    } else {
      return 600; // 最大600
    }
  }
  
  /// 获取自适应字体大小
  static double fontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return baseSize;
    } else if (width < desktopBreakpoint) {
      return baseSize * 1.1;
    } else {
      return baseSize * 1.2;
    }
  }
  
  /// 获取自适应间距
  static double spacing(BuildContext context, double baseSpacing) {
    return value(
      context,
      mobile: baseSpacing,
      tablet: baseSpacing * 1.2,
      desktop: baseSpacing * 1.5,
    );
  }
  
  /// 获取网格列数
  static int getGridColumns(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 3}) {
    return value(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

/// 响应式布局构建器
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) mobile;
  final Widget Function(BuildContext context, BoxConstraints constraints)? tablet;
  final Widget Function(BuildContext context, BoxConstraints constraints)? desktop;
  
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Responsive.desktopBreakpoint) {
          return (desktop ?? tablet ?? mobile)(context, constraints);
        } else if (constraints.maxWidth >= Responsive.mobileBreakpoint) {
          return (tablet ?? mobile)(context, constraints);
        } else {
          return mobile(context, constraints);
        }
      },
    );
  }
}

/// 安全区域包装器（避免刘海/底部导航栏遮挡）
class SafeAreaWrapper extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  
  const SafeAreaWrapper({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}

/// 中心约束容器（限制最大宽度，居中显示）
class CenteredConstrainedBox extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;
  
  const CenteredConstrainedBox({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding = EdgeInsets.zero,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
