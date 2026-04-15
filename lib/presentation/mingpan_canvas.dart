import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/bazi.dart';

/// 命盘画布组件
/// 用 CustomPainter 绘制基础命盘（5层环形）
class MingPanCanvas extends StatelessWidget {
  final Bazi bazi;
  final bool isDark;

  const MingPanCanvas({super.key, required this.bazi, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '命盘图：年柱${bazi.yearGanZhi}，月柱${bazi.monthGanZhi}，日柱${bazi.dayGanZhi}，时柱${bazi.hourGanZhi}，日主${bazi.dayGan}五行属${_getWuxing(bazi.dayGan)}',
      child: CustomPaint(
        painter: _MingPanPainter(bazi: bazi, isDark: isDark),
        child: const SizedBox.expand(),
      ),
    );
  }

  String _getWuxing(String gan) {
    final Map<String, String> map = {
      '甲': '木', '乙': '木',
      '丙': '火', '丁': '火',
      '戊': '土', '己': '土',
      '庚': '金', '辛': '金',
      '壬': '水', '癸': '水',
    };
    return map[gan] ?? '';
  }
}

/// 命盘画家
///
/// 命盘结构（从外到内5层）：
/// - 第1层：年柱（大运/宫位）
/// - 第2层：月柱（地支+藏干）
/// - 第3层：日柱（天干+地支）
/// - 第4层：时柱（天干+地支）
/// - 第5层：五行分析/十神
class _MingPanPainter extends CustomPainter {
  final Bazi bazi;
  final bool isDark;

  _MingPanPainter({required this.bazi, this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 - 8;

    // 5层环形，从外向内
    final layer5Radius = maxRadius;           // 最外层
    final layer4Radius = maxRadius * 0.80;    // 第4层
    final layer3Radius = maxRadius * 0.62;     // 第3层
    final layer2Radius = maxRadius * 0.46;     // 第2层
    final layer1Radius = maxRadius * 0.32;     // 最内层（日主）

    // 颜色方案
    final bgPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 绘制背景圆（最外圈为空白区域）
    bgPaint.color = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFFFF8E1); // 深海军蓝背景 / 米黄色背景
    canvas.drawCircle(center, layer5Radius, bgPaint);

    // 地支位置（12个宫位）
    final zhiAngles = _getZhiAngles();

    // 绘制12宫位框
    _draw12Gongs(canvas, center, layer5Radius, layer4Radius, zhiAngles, strokePaint);

    // 绘制地支文字（12宫位名称）
    _drawDiZhi(canvas, center, layer4Radius, zhiAngles);

    // 绘制天干（内圈4层）
    _drawTianGan(canvas, center, layer3Radius, layer2Radius, layer1Radius);

    // 绘制中心（日主五行）
    _drawCenter(canvas, center, layer1Radius);

    // 绘制四柱标注
    _drawSiZhu(canvas, center, layer5Radius, layer3Radius, zhiAngles);

    // 绘制藏干（8个非四正宫位）
    _drawCangGan(canvas, center, layer4Radius, layer3Radius, zhiAngles);

    // 绘制分隔线
    strokePaint.color = isDark ? const Color(0xFF2C3E50) : Colors.brown.shade300;
    canvas.drawCircle(center, layer5Radius, strokePaint);
    canvas.drawCircle(center, layer4Radius, strokePaint);
    canvas.drawCircle(center, layer3Radius, strokePaint);
    canvas.drawCircle(center, layer2Radius, strokePaint);
    canvas.drawCircle(center, layer1Radius, strokePaint);
  }

  /// 获取12地支的角度（从子位开始，子位在顶部）
  /// 子=0°（顶部），逆时针排列
  Map<String, double> _getZhiAngles() {
    final List<String> zhiOrder = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
    final Map<String, double> angles = {};
    for (int i = 0; i < zhiOrder.length; i++) {
      // 从顶部开始，逆时针，每个地支间隔30度
      // 子在顶部(270度位置，或-90度)，但我们从子开始按顺序
      // 角度：子=0(顶部), 丑=30, 寅=60...
      angles[zhiOrder[i]] = (i * 30.0) * math.pi / 180.0 - math.pi / 2;
    }
    return angles;
  }

  /// 绘制12宫位框
  void _draw12Gongs(
    Canvas canvas,
    Offset center,
    double outerR,
    double innerR,
    Map<String, double> angles,
    Paint strokePaint,
  ) {
    final List<String> zhiOrder = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

    strokePaint.color = isDark ? const Color(0xFF34495E) : Colors.brown.shade400;

    for (int i = 0; i < 12; i++) {
      final angle1 = angles[zhiOrder[i]]!;
      final angle2 = angles[zhiOrder[(i + 1) % 12]]!;

      final path = Path()
        ..moveTo(
          center.dx + outerR * math.cos(angle1),
          center.dy + outerR * math.sin(angle1),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: outerR),
          angle1,
          angle2 - angle1,
          false,
        )
        ..lineTo(
          center.dx + innerR * math.cos(angle2),
          center.dy + innerR * math.sin(angle2),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerR),
          angle2,
          angle1 - angle2,
          false,
        )
        ..close();

      canvas.drawPath(path, strokePaint);
    }
  }

  /// 绘制地支文字
  void _drawDiZhi(
    Canvas canvas,
    Offset center,
    double radius,
    Map<String, double> angles,
  ) {
    // 地支颜色映射
    // 地支颜色映射（暗色模式：子午蓝、寅卯木绿、申酉金、辰戌丑未土各有深浅层次）
    final Map<String, Color> zhiColor = isDark
        ? {
            '子': const Color(0xFF64B5F6), // 阳水 - 浅蓝
            '丑': const Color(0xFFA1887F), // 阴土 - 土褐
            '寅': const Color(0xFF4CAF50), // 阳木 - 深绿
            '卯': const Color(0xFF66BB6A), // 阴木 - 浅绿
            '辰': const Color(0xFF8D6E63), // 阳土 - 深棕
            '巳': const Color(0xFFEF5350), // 阴火 - 深红
            '午': const Color(0xFFE53935), // 阳火 - 亮红
            '未': const Color(0xFFBCAAA4), // 阴土 - 浅土
            '申': const Color(0xFF90A4AE), // 阳金 - 蓝灰
            '酉': const Color(0xFFB0BEC5), // 阴金 - 浅灰
            '戌': const Color(0xFFD7CCC8), // 阳土 - 淡土
            '亥': const Color(0xFF42A5F5), // 阴水 - 天蓝
          }
        : {
            '子': Colors.blue.shade700,
            '丑': Colors.brown.shade600,
            '寅': Colors.green.shade700,
            '卯': Colors.green.shade500,
            '辰': Colors.brown.shade500,
            '巳': Colors.red.shade700,
            '午': Colors.red.shade600,
            '未': Colors.brown.shade400,
            '申': Colors.grey.shade700,
            '酉': Colors.grey.shade600,
            '戌': Colors.brown.shade300,
            '亥': Colors.blue.shade500,
          };

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (final entry in angles.entries) {
      final zhi = entry.key;
      final angle = entry.value;
      final color = zhiColor[zhi] ?? Colors.black87;

      // 文字位置（在外圈偏中位置）
      final textRadius = radius * 0.91;
      final x = center.dx + textRadius * math.cos(angle);
      final y = center.dy + textRadius * math.sin(angle);

      textPainter.text = TextSpan(
        text: zhi,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  /// 绘制天干（4层）
  void _drawTianGan(
    Canvas canvas,
    Offset center,
    double layer3R,
    double layer2R,
    double layer1R,
  ) {
    // 四柱对应的天干
    // 年柱->外层，月柱->第2层，日柱->第3层，时柱->第4层
    final yearGan = bazi.yearGan;
    final monthGan = bazi.monthGan;
    final dayGan = bazi.dayGan;
    final hourGan = bazi.hourGan;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // 日干在最中心层
    _drawGanAtRadius(
      canvas, center, layer1R * 0.7, dayGan,
      Colors.deepOrange.shade800, 18, textPainter,
    );

    // 时干在layer2
    _drawGanAtRadius(
      canvas, center, layer2R * 0.85, hourGan,
      Colors.purple.shade700, 16, textPainter,
    );

    // 月干在layer3
    _drawGanAtRadius(
      canvas, center, layer3R * 0.82, monthGan,
      Colors.teal.shade700, 16, textPainter,
    );

    // 年干在最外层（四柱位置）
    _drawYearGanAtZhi(canvas, center, layer3R, layer2R, yearGan, bazi.yearZhi, textPainter);
  }

  void _drawGanAtRadius(
    Canvas canvas,
    Offset center,
    double radius,
    String gan,
    Color color,
    double fontSize,
    TextPainter textPainter,
  ) {
    // 天干画在顶部（子位）正对面，即午位（180度）
    final angle = -math.pi / 2; // 顶部

    final x = center.dx + radius * math.cos(angle);
    final y = center.dy + radius * math.sin(angle);

    textPainter.text = TextSpan(
      text: gan,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

  /// 在地支位置绘制年干
  void _drawYearGanAtZhi(
    Canvas canvas,
    Offset center,
    double layer3R,
    double layer2R,
    String gan,
    String yearZhi,
    TextPainter textPainter,
  ) {
    // 年干画在年支对应的地支位置
    final angle = _getZhiAngles()[yearZhi]!;

    final midR = (layer3R + layer2R) / 2;
    final x = center.dx + midR * math.cos(angle);
    final y = center.dy + midR * math.sin(angle);

    textPainter.text = TextSpan(
      text: gan,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.indigo.shade800,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

  /// 绘制中心（日主五行）
  void _drawCenter(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // 中心圆
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF2D1F0F) : const Color(0xFFFFE0B2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final borderPaint = Paint()
      ..color = isDark ? Colors.orange.shade400 : Colors.orange.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);

    // 日干文字
    textPainter.text = TextSpan(
      text: bazi.dayGan,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.deepOrange.shade200 : Colors.deepOrange.shade800,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 - 6),
    );

    // 五行
    final wuxing = _getWuxing(bazi.dayGan);
    textPainter.text = TextSpan(
      text: wuxing,
      style: TextStyle(
        fontSize: 10,
        color: isDark ? const Color(0xFFFFCC80) : Colors.brown.shade700,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + 4),
    );
  }

  /// 绘制四柱标注
  void _drawSiZhu(
    Canvas canvas,
    Offset center,
    double outerR,
    double innerR,
    Map<String, double> angles,
  ) {
    // 四柱文字放在各宫位中间
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // 年柱（子位顶部）
    _drawSiZhuLabel(
      canvas, center, angles['子']!, outerR, innerR,
      bazi.yearGanZhi, isDark ? Colors.indigo.shade300 : Colors.indigo.shade800, textPainter,
    );

    // 月柱（卯位左侧）
    _drawSiZhuLabel(
      canvas, center, angles['卯']!, outerR, innerR,
      bazi.monthGanZhi, isDark ? Colors.teal.shade300 : Colors.teal.shade700, textPainter,
    );

    // 日柱（午位底部）
    _drawSiZhuLabel(
      canvas, center, angles['午']!, outerR, innerR,
      bazi.dayGanZhi, isDark ? Colors.deepOrange.shade200 : Colors.deepOrange.shade800, textPainter,
    );

    // 时柱（酉位右侧）
    _drawSiZhuLabel(
      canvas, center, angles['酉']!, outerR, innerR,
      bazi.hourGanZhi, isDark ? Colors.purple.shade300 : Colors.purple.shade700, textPainter,
    );
  }

  void _drawSiZhuLabel(
    Canvas canvas,
    Offset center,
    double angle,
    double outerR,
    double innerR,
    String text,
    Color color,
    TextPainter textPainter,
  ) {
    final midR = (outerR + innerR) / 2;

    final x = center.dx + midR * math.cos(angle);
    final y = center.dy + midR * math.sin(angle);

    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

  /// 绘制藏干（8个非四正宫位）
  void _drawCangGan(
    Canvas canvas,
    Offset center,
    double outerR,
    double innerR,
    Map<String, double> angles,
  ) {
    // 藏干映射
    final Map<String, List<String>> cangGanMap = {
      '丑': ['己', '癸', '辛'],
      '寅': ['甲', '丙', '戊'],
      '辰': ['戊', '乙', '癸'],
      '巳': ['丙', '庚', '戊'],
      '未': ['己', '丁', '乙'],
      '申': ['庚', '壬', '戊'],
      '戌': ['戊', '辛', '丁'],
      '亥': ['壬', '甲'],
    };

    // 藏干颜色（暗色模式：辅助信息层级，比地支更柔更暗）
    final Map<String, Color> cangGanColor = isDark
        ? {
            '甲': const Color(0xFF81C784), // 阳木 - 柔绿
            '乙': const Color(0xFFA5D6A7), // 阴木 - 浅柔绿
            '丙': const Color(0xFFFF8A65), // 阳火 - 珊瑚橙
            '丁': const Color(0xFFFF7043), // 阴火 - 深珊瑚
            '戊': const Color(0xFFBCAAA4), // 阳土 - 浅土
            '己': const Color(0xFFA1887F), // 阴土 - 土褐
            '庚': const Color(0xFFB0BEC5), // 阳金 - 银灰
            '辛': const Color(0xFF90A4AE), // 阴金 - 蓝灰
            '壬': const Color(0xFF64B5F6), // 阳水 - 天蓝
            '癸': const Color(0xFF42A5F5), // 阴水 - 深海蓝
          }
        : {
            '甲': Colors.green.shade700,
            '乙': Colors.green.shade500,
            '丙': Colors.red.shade700,
            '丁': Colors.red.shade600,
            '戊': Colors.brown.shade500,
            '己': Colors.brown.shade600,
            '庚': Colors.grey.shade700,
            '辛': Colors.grey.shade600,
            '壬': Colors.blue.shade500,
            '癸': Colors.blue.shade700,
          };

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final midR = (outerR + innerR) / 2;

    for (final entry in cangGanMap.entries) {
      final zhi = entry.key;
      final ganList = entry.value;
      final angle = angles[zhi]!;

      // 多个藏干垂直排列
      final ganCount = ganList.length;
      for (int i = 0; i < ganCount; i++) {
        final gan = ganList[i];
        // 藏干之间稍微偏移角度
        final angleOffset = (i - (ganCount - 1) / 2) * 0.08;
        final r = midR + (i - (ganCount - 1) / 2) * 12;

        final x = center.dx + r * math.cos(angle + angleOffset);
        final y = center.dy + r * math.sin(angle + angleOffset);

        textPainter.text = TextSpan(
          text: gan,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: cangGanColor[gan] ?? Colors.grey,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
      }
    }
  }

  /// 获取天干五行
  String _getWuxing(String gan) {
    final Map<String, String> map = {
      '甲': '木', '乙': '木',
      '丙': '火', '丁': '火',
      '戊': '土', '己': '土',
      '庚': '金', '辛': '金',
      '壬': '水', '癸': '水',
    };
    return map[gan] ?? '';
  }

  @override
  bool shouldRepaint(covariant _MingPanPainter oldDelegate) {
    return oldDelegate.bazi != bazi || oldDelegate.isDark != isDark;
  }
}
