import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/dayun.dart';
import '../core/liunian.dart';
import '../models/bazi.dart';

/// 命盘动画画布
/// 实现 M2 动画效果：
/// 1. 启动动画（光点扩散 → 环形展开 → 文字浮现）
/// 2. 自转动画（5层环独立旋转）
/// 3. 交互反馈（点击、长按、缩放）
/// 4. 命盘优化（文字朝外、渐变、阴影）
/// M3 增强：
/// 5. 大运环显示当前年龄段
/// 6. 流年高亮
/// 7. 点击大运/流年显示详情
class MingPanAnimatedCanvas extends StatefulWidget {
  final Bazi bazi;
  final bool autoPlay;
  final DayunResult? dayunResult;
  final bool isDark;

  const MingPanAnimatedCanvas({
    super.key,
    required this.bazi,
    this.autoPlay = true,
    this.dayunResult,
    this.isDark = false,
  });

  @override
  State<MingPanAnimatedCanvas> createState() => _MingPanAnimatedCanvasState();
}

class _MingPanAnimatedCanvasState extends State<MingPanAnimatedCanvas>
    with TickerProviderStateMixin {
  late final AnimationController _startupController;
  late final AnimationController _spinController;
  bool _isPaused = false;
  double _scale = 1.0;
  String? _selectedGong;
  
  // 性能优化：缓存上一次的bazi避免不必要的重绘
  Bazi? _lastBazi;

  @override
  void initState() {
    super.initState();
    _startupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );

    if (widget.autoPlay) {
      // 启动动画完成后停止自转
      _startupController.forward().then((_) {
        _spinController.stop();
        _spinController.value = 0; // 定位到用户命盘方位
      });
      _spinController.repeat();
    } else {
      // autoPlay=false 时直接显示完全展开状态
      _startupController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MingPanAnimatedCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoPlay != oldWidget.autoPlay) {
      if (widget.autoPlay) {
        // 切换到开启动画：重置并播放启动动画 + 自转
        _startupController.reset();
        _startupController.forward();
        _spinController.repeat();
      } else {
        // 切换到关闭动画：停止自转，保持完全展开状态
        _startupController.stop();
        _spinController.stop();
        _startupController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _startupController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _spinController.stop();
      } else {
        // 如果启动动画已完成，则不再旋转（保持定位状态）
        if (_startupController.isCompleted) {
          _spinController.value = 0;
        } else {
          _spinController.repeat();
        }
      }
    });
  }

  void _showGongDetail(BuildContext context, String gong, String description) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('【$gong】宫'),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _getGongDescription(String gong) {
    final descriptions = {
      '子': '子水阳宫，正北坎位。智慧之星，主泌尿生殖。',
      '丑': '丑土阴宫，东北艮位。金库所在，主脾脏毛发。',
      '寅': '寅木阳宫，东北艮位。木之长生位，主胆经、手足。',
      '卯': '卯木阴宫，正东震位。木之帝旺位，主肝经、十指。',
      '辰': '辰土阳宫，东南巽位。水之墓库，主胃消化、肩臂。',
      '巳': '巳火阴宫，东南巽位。火之长生位，主心脏、小肠。',
      '午': '午火阳宫，正南离位。火之帝旺位，主眼睛、脑部。',
      '未': '未土阴宫，西南坤位。木之墓库，主脾脏、脊背。',
      '申': '申金阳宫，西南坤位。金之长生位，主大肠、肺。',
      '酉': '酉金阴宫，正西兑位。金之帝旺位，主肺、骨。',
      '戌': '戌土阳宫，西北乾位。火之墓库，主心包、腿足。',
      '亥': '亥水阴宫，西北乾位。水之长生位，主肾、头。',
      '日主': '日主${widget.bazi.dayGan}，五行属${_getWuxing(widget.bazi.dayGan)}。代表本人。',
      '年柱': '年柱：${widget.bazi.yearGanZhi}，主祖辈、根身。',
      '月柱': '月柱：${widget.bazi.monthGanZhi}，主手足、父母。',
      '时柱': '时柱：${widget.bazi.hourGanZhi}，主晚年、子嗣。',
    };
    return descriptions[gong] ?? '无详细描述';
  }

  void _handleTap(TapUpDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final tapPos = details.localPosition;
    final maxRadius = math.min(size.width, size.height) / 2 - 8;

    final layer5Radius = maxRadius;
    final layer3Radius = maxRadius * 0.62;
    final layer2Radius = maxRadius * 0.46;
    final layer1Radius = maxRadius * 0.32;
    final layer4R = maxRadius * 0.80;
    final dayunOuterR = (layer4R + maxRadius) / 2;
    final dayunInnerR = layer4R;
    final liunianR = maxRadius;
    final liunianInnerR = dayunOuterR;

    final dx = tapPos.dx - center.dx;
    final dy = tapPos.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final angle = math.atan2(dy, dx);

    String? tappedGong;
    String description = '';

    // 点击大运环
    if (dist > dayunInnerR && dist <= liunianInnerR) {
      final dayun = _getDayunAtAngle(angle, center, dayunOuterR, dayunInnerR);
      if (dayun != null) {
        setState(() => _selectedGong = '大运${dayun.ganZhi}');
        _showDayunDetail(context, dayun);
        return;
      }
    }

    // 点击流年环
    if (dist > liunianInnerR && dist <= liunianR) {
      _showLiunianDetailAtAngle(context, angle);
      return;
    }

    if (dist <= layer1Radius * 1.2) {
      tappedGong = '日主';
    } else if (dist <= layer2Radius) {
      tappedGong = '时柱';
    } else if (dist <= layer3Radius * 0.8) {
      tappedGong = '月柱';
    } else if (dist <= layer5Radius * 0.75) {
      tappedGong = '年柱';
    } else if (dist <= layer5Radius) {
      final normalizedAngle = (angle + math.pi / 2 + 2 * math.pi) % (2 * math.pi);
      final index = ((normalizedAngle / (2 * math.pi)) * 12).floor() % 12;
      const dizhiList = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
      tappedGong = dizhiList[index];
    }

    if (tappedGong != null) {
      description = _getGongDescription(tappedGong);
      setState(() => _selectedGong = tappedGong);
      _showGongDetail(context, tappedGong, description);
    }
  }

  Dayun? _getDayunAtAngle(double angle, Offset center, double outerR, double innerR) {
    if (widget.dayunResult == null) return null;
    // 将角度映射到地支索引
    final normalizedAngle = (angle + math.pi / 2 + 2 * math.pi) % (2 * math.pi);
    final index = ((normalizedAngle / (2 * math.pi)) * 12).floor() % 12;
    final dayuns = widget.dayunResult!.dayuns;
    if (index < dayuns.length) return dayuns[index];
    return null;
  }

  void _showDayunDetail(BuildContext context, Dayun dayun) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    dayun.ganZhi,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '大运',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: dayun.direction.name == 'shun'
                        ? Colors.blue.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dayun.direction.nameCn,
                    style: TextStyle(
                      fontSize: 12,
                      color: dayun.direction == DayunDirection.shun
                          ? Colors.blue.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow('年龄', '${dayun.startAge} - ${dayun.endAge}岁'),
            const SizedBox(height: 8),
            _buildDetailRow('年份', '${dayun.startYear} - ${dayun.startYear + 9}'),
            const SizedBox(height: 8),
            _buildDetailRow('天干', dayun.gan),
            const SizedBox(height: 8),
            _buildDetailRow('地支', dayun.zhi),
            const SizedBox(height: 8),
            _buildDetailRow('大运五行', _ganWuxingMap[dayun.gan] ?? ''),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  /// 根据角度计算流年年份：以当前年份为中心，12格对应前后6年
  int _getLiunianYearAtIndex(int index) {
    final currentYear = DateTime.now().year;
    // 当前流年地支索引
    final currentGz = getLiunianGanZhi(currentYear);
    final currentZhiIndex = const [
      '子','丑','寅','卯','辰','巳','午','未','申','酉','戌','亥'
    ].indexOf(currentGz.length > 1 ? currentGz[1] : '子');
    // index 在环上是绝对地支位置，找到与当前年份地支最近的那一圈
    final diff = (index - currentZhiIndex + 12) % 12;
    // 让当前年份落在中间偏左：diff 0~5 对应当前+0~+5，6~11 对应当前-6~-1
    final offset = diff <= 5 ? diff : diff - 12;
    return currentYear + offset;
  }

  void _showLiunianDetailAtAngle(BuildContext context, double angle) {
    final normalizedAngle = (angle + math.pi / 2 + 2 * math.pi) % (2 * math.pi);
    final index = ((normalizedAngle / (2 * math.pi)) * 12).floor() % 12;
    final liunianYear = _getLiunianYearAtIndex(index);
    final detail = getLiunianDetail(liunianYear, widget.bazi,
        dayun: _getCurrentDayun(liunianYear));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (_, scrollCtrl) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text(
                      '${detail.liunian.ganZhi}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$liunianYear 年流年',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(detail.summary,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
              if (detail.liunian.chongHeRelations.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: detail.liunian.chongHeRelations.map((r) => Chip(
                    label: Text(r, style: const TextStyle(fontSize: 12)),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.red.shade50,
                  )).toList(),
                ),
              ],
              const Divider(height: 24),
              const Text('流月', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: detail.months.map((m) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Text('${m.month}月',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(m.ganZhi,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    ],
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 根据年份找到对应的大运（命主当时处于哪个大运）
  Dayun? _getCurrentDayun(int year) {
    if (widget.dayunResult == null) return null;
    for (final d in widget.dayunResult!.dayuns.reversed) {
      if (year >= d.startYear) return d;
    }
    return widget.dayunResult!.dayuns.firstOrNull;
  }

  static const _ganWuxingMap = {
    '甲': '木', '乙': '木',
    '丙': '火', '丁': '火',
    '戊': '土', '己': '土',
    '庚': '金', '辛': '金',
    '壬': '水', '癸': '水',
  };

  String _getWuxing(String gan) {
    const map = {
      '甲': '木', '乙': '木',
      '丙': '火', '丁': '火',
      '戊': '土', '己': '土',
      '庚': '金', '辛': '金',
      '壬': '水', '癸': '水',
    };
    return map[gan] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onScaleUpdate: (details) {
            setState(() {
              _scale = (_scale * details.scale).clamp(0.5, 3.0);
            });
          },
          onTapUp: (details) => _handleTap(details, Size(constraints.maxWidth, constraints.maxHeight)),
          onLongPress: _togglePause,
          child: AnimatedBuilder(
            animation: Listenable.merge([_startupController, _spinController]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scale,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _MingPanAnimatedPainter(
                      bazi: widget.bazi,
                      startupProgress: _startupController.value,
                      spinAngle: _spinController.value * 2 * math.pi,
                      selectedGong: _selectedGong,
                      dayunResult: widget.dayunResult,
                      isDark: widget.isDark,
                    ),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// 动画命盘画家
class _MingPanAnimatedPainter extends CustomPainter {
  final Bazi bazi;
  final double startupProgress;
  final double spinAngle;
  final String? selectedGong;
  final DayunResult? dayunResult;
  final bool isDark;

  _MingPanAnimatedPainter({
    required this.bazi,
    required this.startupProgress,
    required this.spinAngle,
    this.selectedGong,
    this.dayunResult,
    this.isDark = false,
  }) {
    // 性能优化：预创建可重用的Paint对象
    _initPaints();
  }
  
  // 缓存Paint对象避免重复创建
  late final Paint _strokePaint;
  late final Paint _fillPaint;
  
  void _initPaints() {
    _strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    _fillPaint = Paint()
      ..style = PaintingStyle.fill;
  }

  // 动画曲线调优：使用不同的缓动函数让动画更有层次感
  double get _centerExpand => _easeOutBack(((startupProgress - 0.1) * 5).clamp(0.0, 1.0));
  double get _dizhiExpand => _easeOutElastic(((startupProgress - 0.22) * 4.5).clamp(0.0, 1.0));
  double get _tianganExpand => _easeOutCubic(((startupProgress - 0.35) * 4).clamp(0.0, 1.0));
  double get _dayunExpand => _easeOutQuad(((startupProgress - 0.48) * 4).clamp(0.0, 1.0));
  double get _liunianExpand => _easeOutQuad(((startupProgress - 0.60) * 4).clamp(0.0, 1.0));
  double get _spinFactor => _easeInOutQuad(((startupProgress - 0.72) * 3.5).clamp(0.0, 1.0));
  double get _textReveal => _easeOutCubic(((startupProgress - 0.85) * 6).clamp(0.0, 1.0));
  double get _lightPoint => _easeOutQuad((startupProgress * 4).clamp(0.0, 1.0));

  // 缓动函数集合
  double _easeOutCubic(double t) => t <= 0 ? 0.0 : (1 - math.pow(1 - t, 3)).toDouble();
  
  double _easeOutQuad(double t) => t <= 0 ? 0.0 : t * (2 - t);
  
  double _easeInOutQuad(double t) {
    if (t <= 0) return 0.0;
    if (t >= 1) return 1.0;
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }
  
  double _easeOutBack(double t) {
    if (t <= 0) return 0.0;
    if (t >= 1) return 1.0;
    const c1 = 1.70158;
    const c3 = c1 + 1;
    return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2);
  }
  
  double _easeOutElastic(double t) {
    if (t <= 0) return 0.0;
    if (t >= 1) return 1.0;
    const c4 = (2 * math.pi) / 3;
    return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) / 2 - 8;
    
    // 绘制木质纹理背景
    _drawWoodenBackground(canvas, center, maxR);

    final layer1R = maxR * 0.32; // 日主
    final layer3R = maxR * 0.62; // 月柱
    final layer4R = maxR * 0.80; // 年柱/地支
    final dayunR = (layer4R + maxR) / 2;
    final liunianR = maxR;

    // === 光点阶段 ===
    if (_lightPoint < 1.0 && _centerExpand <= 0) {
      _drawLightPoint(canvas, center, _lightPoint);
      return;
    }

    // === 中心圆展开 ===
    final curLayer1R = layer1R * _centerExpand;
    if (curLayer1R > 0) {
      _drawCenter(canvas, center, curLayer1R);
    }

    // === 地支环展开 ===
    final curLayer4R = layer4R * _dizhiExpand;
    if (curLayer4R > layer1R) {
      _drawDiZhiRing(canvas, center, curLayer4R, curLayer1R, 0);
    }

    // === 天干环展开 ===
    final curLayer3R = layer3R * _tianganExpand;
    if (curLayer3R > layer1R) {
      _drawTianGanRing(canvas, center, curLayer3R, curLayer1R);
    }

    // === 大运环展开 ===
    final curDayunR = dayunR * _dayunExpand;
    if (curDayunR > layer4R) {
      _drawDayunRing(canvas, center, curDayunR, layer4R);
    }

    // === 流年环展开 ===
    final curLiunianR = liunianR * _liunianExpand;
    if (curLiunianR > curDayunR) {
      _drawLiunianRing(canvas, center, curLiunianR, curDayunR);
    }

    // === 自转动画 ===
    if (_spinFactor > 0) {
      _drawSpinningRings(canvas, center, maxR);
    }

    // === 命格文字浮现 ===
    if (_textReveal > 0) {
      _drawMingGeText(canvas, center, maxR, _textReveal);
    }
  }

  void _drawLightPoint(Canvas canvas, Offset center, double progress) {
    final radius = 8.0 + 60 * _easeOutCubic(progress);
    final opacity = (1 - progress * 0.5).clamp(0.0, 1.0);
    final gradient = RadialGradient(
      colors: isDark
          ? [
              Colors.white.withValues(alpha: opacity),
              Colors.amber.shade200.withValues(alpha: opacity * 0.7),
              Colors.orange.shade300.withValues(alpha: opacity * 0.3),
              Colors.transparent,
            ]
          : [
              Colors.white.withValues(alpha: opacity),
              Colors.amber.withValues(alpha: opacity * 0.7),
              Colors.orange.withValues(alpha: opacity * 0.3),
              Colors.transparent,
            ],
      stops: const [0.0, 0.3, 0.6, 1.0],
    );
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  void _drawCenter(Canvas canvas, Offset center, double radius) {
    // 1. 绘制白色指南针底盘
    final compassBg = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, Colors.grey.shade200],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, compassBg);
    
    // 2. 绘制红色十字线（罗盘刻度）
    final crossPaint = Paint()
      ..color = Colors.red.shade600
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    
    // 垂直线
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.8),
      Offset(center.dx, center.dy + radius * 0.8),
      crossPaint,
    );
    // 水平线
    canvas.drawLine(
      Offset(center.dx - radius * 0.8, center.dy),
      Offset(center.dx + radius * 0.8, center.dy),
      crossPaint,
    );
    
    // 3. 绘制八卦符号环
    _drawBaguaSymbols(canvas, center, radius * 0.72);
    
    // 4. 金属边框
    final border = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFB8860B),
          const Color(0xFFDAA520),
          const Color(0xFFB8860B),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    border.style = PaintingStyle.stroke;
    border.strokeWidth = 4.0;
    canvas.drawCircle(center, radius, border);
    
    // 5. 中心日干文字
    final tp = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center);
    tp.text = TextSpan(
      text: bazi.dayGan,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.deepOrange.shade200 : Colors.deepOrange.shade800,
        shadows: [Shadow(color: isDark ? Colors.black38 : Colors.white54, blurRadius: 4)],
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2 - 5));

    tp.text = TextSpan(
      text: _getWuxing(bazi.dayGan),
      style: TextStyle(fontSize: 12, color: isDark ? Colors.brown.shade300 : Colors.brown.shade700),
    );
    tp.layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + 5));
  }

  void _drawDiZhiRing(Canvas canvas, Offset center, double outerR, double innerR, double rotation) {
    final strokePaint = Paint()
      ..color = Colors.brown.shade400.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const zhiOrder = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
    final angles = <String, double>{};
    for (int i = 0; i < zhiOrder.length; i++) {
      angles[zhiOrder[i]] = (i * 30.0) * math.pi / 180.0 - math.pi / 2;
    }

    for (int i = 0; i < 12; i++) {
      final angle1 = angles[zhiOrder[i]]! + rotation;
      final angle2 = angles[zhiOrder[(i + 1) % 12]]! + rotation;

      final fillPaint = Paint()
        ..color = _gongFillColor(zhiOrder[i]).withValues(alpha: 0.18)
        ..style = PaintingStyle.fill;
      canvas.drawPath(_arcPath(center, outerR, innerR, angle1, angle2), fillPaint);
      canvas.drawPath(_arcPath(center, outerR, innerR, angle1, angle2), strokePaint);
      
      // 绘制径向分隔线（从内圈到外圈）
      final radialPaint = Paint()
        ..color = const Color(0xFF8B4513)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(center.dx + innerR * math.cos(angle1), center.dy + innerR * math.sin(angle1)),
        Offset(center.dx + outerR * math.cos(angle1), center.dy + outerR * math.sin(angle1)),
        radialPaint,
      );
    }

    final tp = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center);
    for (int i = 0; i < 12; i++) {
      final angle = angles[zhiOrder[i]]! + rotation + (15 * math.pi / 180.0);
      tp.text = TextSpan(
        text: zhiOrder[i],
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: _zhiColor(zhiOrder[i]),
          shadows: [Shadow(color: isDark ? Colors.black45 : Colors.black26, blurRadius: 3)],
        ),
      );
      tp.layout();
      _drawTextRadial(canvas, tp, center, (outerR + innerR) / 2, angle);
    }
  }

  void _drawTianGanRing(Canvas canvas, Offset center, double midR, double innerR) {
    final tp = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center);

    // 年干
    tp.text = TextSpan(
      text: bazi.yearGan,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade800,
        shadows: [Shadow(color: isDark ? Colors.black45 : Colors.black26, blurRadius: 3)],
      ),
    );
    tp.layout();
    _drawTextRadial(canvas, tp, center, midR * 0.85, -math.pi / 2, bazi.yearGan);

    // 月干
    tp.text = TextSpan(
      text: bazi.monthGan,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.teal.shade300 : Colors.teal.shade700,
        shadows: [Shadow(color: isDark ? Colors.black45 : Colors.black26, blurRadius: 3)],
      ),
    );
    tp.layout();
    _drawTextRadial(canvas, tp, center, midR * 0.90, -math.pi / 2, bazi.monthGan);

    // 时干
    tp.text = TextSpan(
      text: bazi.hourGan,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.purple.shade300 : Colors.purple.shade700,
        shadows: [Shadow(color: isDark ? Colors.black45 : Colors.black26, blurRadius: 3)],
      ),
    );
    tp.layout();
    _drawTextRadial(canvas, tp, center, midR * 0.90, -math.pi / 2, bazi.hourGan);

    // 四柱标签
    final zhiAngles = _getZhiAngles();
    _drawSiZhu(canvas, center, zhiAngles, midR * 0.72, tp);
  }

  void _drawDayunRing(Canvas canvas, Offset center, double outerR, double innerR) {
    final midR = (outerR + innerR) / 2;

    // 如果有大运数据，绘制当前年龄段高亮
    if (dayunResult != null && dayunResult!.dayuns.isNotEmpty) {
      final currentYear = DateTime.now().year;
      // 找到当前年份对应的大运
      Dayun? currentDayun;
      for (final d in dayunResult!.dayuns) {
        if (currentYear >= d.startYear && currentYear < d.startYear + 10) {
          currentDayun = d;
          break;
        }
      }

      if (currentDayun != null) {
        // 高亮当前大运段（用弧形标记）
        final zhiIndex = _getZhiIndex(currentDayun.zhi);
        final startAngle = zhiIndex * 30.0 * math.pi / 180.0 - math.pi / 2 - 15 * math.pi / 180.0;
        final sweepAngle = 30.0 * math.pi / 180.0;

        final highlightPaint = Paint()
          ..color = Colors.blue.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: outerR),
          startAngle,
          sweepAngle,
          true,
          highlightPaint,
        );

        // 在大运环上标注大运名称
        final tp = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center);
        tp.text = TextSpan(
          text: currentDayun.ganZhi,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
          ),
        );
        tp.layout();
        final angle = startAngle + sweepAngle / 2;
        final x = center.dx + midR * math.cos(angle);
        final y = center.dy + midR * math.sin(angle);
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(angle + math.pi / 2);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }

    final paint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          Colors.blue.withValues(alpha: 0.0),
          Colors.blue.withValues(alpha: 0.10),
          Colors.blue.withValues(alpha: 0.06),
          Colors.blue.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerR))
      ..style = PaintingStyle.stroke
      ..strokeWidth = (outerR - innerR).clamp(0, 20);
    canvas.drawCircle(center, midR, paint);

    final stroke = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, outerR, stroke);
    canvas.drawCircle(center, innerR, stroke);
  }

  void _drawLiunianRing(Canvas canvas, Offset center, double outerR, double innerR) {
    final midR = (outerR + innerR) / 2;

    // 高亮当前流年
    final currentYear = DateTime.now().year;
    // 当前流年的地支在命盘上的位置（按地支环的布局）
    final currentGz = getLiunianGanZhi(currentYear);
    const zhiList = ['子','丑','寅','卯','辰','巳','午','未','申','酉','戌','亥'];
    final currentZhi = currentGz.length > 1 ? currentGz[1] : '子';
    final yearOffset = zhiList.indexOf(currentZhi);
    final liunianAngle = yearOffset * 30.0 * math.pi / 180.0 - math.pi / 2 - 15 * math.pi / 180.0;

    // 绘制当前流年高亮点
    final highlightPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final arcAngle = 30.0 * math.pi / 180.0;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerR),
      liunianAngle - arcAngle / 2,
      arcAngle,
      true,
      highlightPaint,
    );

    // 流年文字标注
    final tp = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center);
    tp.text = TextSpan(
      text: '$currentYear',
      style: TextStyle(
        fontSize: 11,
        color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
        fontWeight: FontWeight.bold,
      ),
    );
    tp.layout();
    final x = center.dx + midR * math.cos(liunianAngle + arcAngle / 2);
    final y = center.dy + midR * math.sin(liunianAngle + arcAngle / 2);
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(liunianAngle + math.pi);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();

    final paint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          Colors.amber.withValues(alpha: 0.0),
          Colors.amber.withValues(alpha: 0.07),
          Colors.amber.withValues(alpha: 0.04),
          Colors.amber.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.2, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerR))
      ..style = PaintingStyle.stroke
      ..strokeWidth = (outerR - innerR).clamp(0, 18);
    canvas.drawCircle(center, midR, paint);

    final stroke = Paint()
      ..color = Colors.amber.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, outerR, stroke);
  }

  void _drawSpinningRings(Canvas canvas, Offset center, double maxR) {
    final f = _spinFactor;
    if (f <= 0) return;

    final layer1R = maxR * 0.32;
    final layer3R = maxR * 0.62;
    final layer4R = maxR * 0.80;
    final dayunR = (layer4R + maxR) / 2;

    // 地支环：中速逆时针旋转（作为主环）
    _drawDiZhiRing(canvas, center, layer4R, layer1R, -spinAngle * 0.3);
    
    // 天干环：慢速顺时针旋转（与地支相反）
    final tianganRotation = spinAngle * 0.15;
    _drawRotatingTianGan(canvas, center, layer3R, tianganRotation);
    
    // 大运环：极慢顺时针旋转
    _drawRotatingDayun(canvas, center, maxR, dayunR, layer4R, spinAngle * 0.08);
    
    // 流年环：最慢逆时针旋转（年轮感）
    _drawRotatingLiunian(canvas, center, maxR, dayunR, -spinAngle * 0.05);

    // 最外层分隔线
    final stroke = Paint()
      ..color = Colors.brown.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, maxR, stroke);
    canvas.drawCircle(center, layer1R, stroke);
  }
  
  void _drawRotatingTianGan(Canvas canvas, Offset center, double radius, double rotation) {
    final tp = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center);
    
    // 绘制旋转的天干环（年干、月干、时干在不同位置）
    final gans = [
      (bazi.yearGan, Colors.indigo.shade800, 0.85),
      (bazi.monthGan, Colors.teal.shade700, 0.90),
      (bazi.hourGan, Colors.purple.shade700, 0.95),
    ];
    
    for (final (gan, color, rFactor) in gans) {
      tp.text = TextSpan(
        text: gan,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: color.withValues(alpha: 0.5),
          shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
      );
      tp.layout();
      final angle = rotation + (-math.pi / 2);
      _drawTextRadial(canvas, tp, center, radius * rFactor, angle);
    }
  }
  
  void _drawRotatingDayun(Canvas canvas, Offset center, double maxR, double dayunR, double innerR, double rotation) {
    // 绘制旋转的大运环光晕
    final paint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          Colors.blue.withValues(alpha: 0.0),
          Colors.blue.withValues(alpha: 0.08),
          Colors.blue.withValues(alpha: 0.04),
          Colors.blue.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.75, 1.0],
        transform: GradientRotation(rotation),
      ).createShader(Rect.fromCircle(center: center, radius: maxR))
      ..style = PaintingStyle.stroke
      ..strokeWidth = (dayunR - innerR).clamp(0, 20);
    canvas.drawCircle(center, (dayunR + innerR) / 2, paint);
  }
  
  void _drawRotatingLiunian(Canvas canvas, Offset center, double maxR, double innerR, double rotation) {
    // 绘制旋转的流年环光晕
    final paint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          Colors.amber.withValues(alpha: 0.0),
          Colors.amber.withValues(alpha: 0.06),
          Colors.amber.withValues(alpha: 0.03),
          Colors.amber.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.2, 0.8, 1.0],
        transform: GradientRotation(rotation),
      ).createShader(Rect.fromCircle(center: center, radius: maxR))
      ..style = PaintingStyle.stroke
      ..strokeWidth = (maxR - innerR).clamp(0, 18);
    canvas.drawCircle(center, (maxR + innerR) / 2, paint);
  }

  void _drawMingGeText(Canvas canvas, Offset center, double maxR, double opacity) {
    final f = _easeOutCubic(opacity);
    final tp = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center);

    final texts = [
      ('年柱：${bazi.yearGanZhi}', Colors.indigo.shade300),
      ('月柱：${bazi.monthGanZhi}', Colors.teal.shade300),
      ('日柱：${bazi.dayGanZhi}', Colors.deepOrange.shade200),
      ('时柱：${bazi.hourGanZhi}', Colors.purple.shade300),
    ];

    double y = center.dy + maxR * 0.52;
    for (final (text, color) in texts) {
      tp.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: f),
          shadows: [Shadow(color: Colors.black.withValues(alpha: f * 0.5), blurRadius: 4)],
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(center.dx - tp.width / 2, y));
      y += 18;
    }
  }

  // ========== 工具方法 ==========

  int _getZhiIndex(String zhi) {
    const zhiOrder = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
    return zhiOrder.indexOf(zhi);
  }

  Map<String, double> _getZhiAngles() {
    const zhiOrder = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
    final angles = <String, double>{};
    for (int i = 0; i < zhiOrder.length; i++) {
      angles[zhiOrder[i]] = (i * 30.0) * math.pi / 180.0 - math.pi / 2;
    }
    return angles;
  }

  Path _arcPath(Offset center, double outerR, double innerR, double angle1, double angle2) {
    return Path()
      ..moveTo(center.dx + outerR * math.cos(angle1), center.dy + outerR * math.sin(angle1))
      ..arcTo(Rect.fromCircle(center: center, radius: outerR), angle1, angle2 - angle1, false)
      ..lineTo(center.dx + innerR * math.cos(angle2), center.dy + innerR * math.sin(angle2))
      ..arcTo(Rect.fromCircle(center: center, radius: innerR), angle2, angle1 - angle2, false)
      ..close();
  }

  Color _zhiColor(String zhi) {
    const map = {
      '子': Color(0xFF1565C0),
      '丑': Color(0xFF5D4037),
      '寅': Color(0xFF2E7D32),
      '卯': Color(0xFF43A047),
      '辰': Color(0xFF5D4037),
      '巳': Color(0xFFC62828),
      '午': Color(0xFFD32F2F),
      '未': Color(0xFF6D4C41),
      '申': Color(0xFF424242),
      '酉': Color(0xFF616161),
      '戌': Color(0xFF795548),
      '亥': Color(0xFF1565C0),
    };
    return map[zhi] ?? Colors.black;
  }

  Color _gongFillColor(String zhi) {
    const map = {
      '子': Color(0xFF0D47A1),
      '丑': Color(0xFF4E342E),
      '寅': Color(0xFF1B5E20),
      '卯': Color(0xFF2E7D32),
      '辰': Color(0xFF3E2723),
      '巳': Color(0xFFB71C1C),
      '午': Color(0xFFC62828),
      '未': Color(0xFF5D4037),
      '申': Color(0xFF37474F),
      '酉': Color(0xFF455A64),
      '戌': Color(0xFF4E342E),
      '亥': Color(0xFF0D47A1),
    };
    return map[zhi] ?? Colors.grey;
  }

  void _drawTextRadial(Canvas canvas, TextPainter tp, Offset center, double radius, double angle, [String? text]) {
    final x = center.dx + radius * math.cos(angle);
    final y = center.dy + radius * math.sin(angle);
    final norm = (angle % (2 * math.pi) + 2 * math.pi) % (2 * math.pi);
    final needsFlip = norm > math.pi / 2 && norm < 3 * math.pi / 2;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle + math.pi / 2);
    if (needsFlip) canvas.rotate(math.pi);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  void _drawSiZhu(Canvas canvas, Offset center, Map<String, double> angles, double midR, TextPainter tp) {
    void draw(String zhi, String gz, Color color) {
      tp.text = TextSpan(
        text: gz,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color,
          shadows: [Shadow(color: isDark ? Colors.black45 : Colors.black26, blurRadius: 3)],
        ),
      );
      tp.layout();
      final angle = angles[zhi]!;
      final x = center.dx + midR * math.cos(angle);
      final y = center.dy + midR * math.sin(angle);
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
    draw('子', bazi.yearGanZhi, Colors.indigo.shade800);
    draw('卯', bazi.monthGanZhi, Colors.teal.shade700);
    draw('午', bazi.dayGanZhi, Colors.deepOrange.shade800);
    draw('酉', bazi.hourGanZhi, Colors.purple.shade700);
  }

  String _getWuxing(String gan) {
    const map = {
      '甲': '木', '乙': '木',
      '丙': '火', '丁': '火',
      '戊': '土', '己': '土',
      '庚': '金', '辛': '金',
      '壬': '水', '癸': '水',
    };
    return map[gan] ?? '';
  }

  // ========== 新增：罗盘风格绘制方法 ==========
  
  /// 绘制木质纹理背景
  void _drawWoodenBackground(Canvas canvas, Offset center, double radius) {
    // 木质底色（暖黄色）
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE8D4A0), // 中心浅黄
          const Color(0xFFD4B77A), // 边缘深黄
        ],
        stops: const [0.3, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bgPaint);
    
    // 添加同心圆纹理
    final texturePaint = Paint()
      ..color = const Color(0x10000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (var i = 1; i <= 20; i++) {
      canvas.drawCircle(center, radius * i / 20, texturePaint);
    }
  }
  
  /// 绘制金属边框
  void _drawMetalBorder(Canvas canvas, Offset center, double radius) {
    // 外圈金属光泽
    final outerBorderPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFB8860B), // 深金色
          const Color(0xFFDAA520), // 金黄色
          const Color(0xFFB8860B), // 深金色
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    outerBorderPaint.style = PaintingStyle.stroke;
    outerBorderPaint.strokeWidth = 6;
    canvas.drawCircle(center, radius - 3, outerBorderPaint);
    
    // 内圈金属阴影
    final innerShadowPaint = Paint()
      ..color = const Color(0x40000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 7, innerShadowPaint);
  }
  
  /// 绘制360度刻度标记
  void _drawDegreeMarks(Canvas canvas, Offset center, double radius) {
    final markPaint = Paint()
      ..color = const Color(0xFF8B4513) // 棕色
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    for (var degree = 0; degree < 360; degree++) {
      final angle = (degree - 90) * math.pi / 180;
      final startRadius = radius - 15;
      
      // 每10度一个长刻度，每5度一个中刻度，其余短刻度
      double markLength;
      if (degree % 10 == 0) {
        markLength = 12;
        markPaint.strokeWidth = 2.0;
        
        // 每30度标注数字
        if (degree % 30 == 0) {
          textPainter.text = TextSpan(
            text: '$degree',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          );
          textPainter.layout();
          final textX = center.dx + (startRadius - 18) * math.cos(angle) - textPainter.width / 2;
          final textY = center.dy + (startRadius - 18) * math.sin(angle) - textPainter.height / 2;
          textPainter.paint(canvas, Offset(textX, textY));
        }
      } else if (degree % 5 == 0) {
        markLength = 8;
        markPaint.strokeWidth = 1.5;
      } else {
        markLength = 5;
        markPaint.strokeWidth = 1.0;
      }
      
      final endRadius = startRadius - markLength;
      final x1 = center.dx + startRadius * math.cos(angle);
      final y1 = center.dy + startRadius * math.sin(angle);
      final x2 = center.dx + endRadius * math.cos(angle);
      final y2 = center.dy + endRadius * math.sin(angle);
      
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), markPaint);
    }
  }
  
  /// 绘制八卦符号
  void _drawBaguaSymbols(Canvas canvas, Offset center, double radius) {
    // 八卦符号：乾☰ 坤☷ 震☳ 巽☴ 坎☵ 离☲ 艮☶ 兑☱
    final bagua = ['☰', '☱', '☲', '☳', '☴', '☵', '☶', '☷'];
    final baguaNames = ['乾', '兑', '离', '震', '巽', '坎', '艮', '坤'];
    
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    for (var i = 0; i < 8; i++) {
      final angle = (i * 45 - 90) * math.pi / 180;
      
      // 绘制八卦符号
      textPainter.text = TextSpan(
        text: bagua[i],
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF000000),
        ),
      );
      textPainter.layout();
      final symbolX = center.dx + radius * math.cos(angle) - textPainter.width / 2;
      final symbolY = center.dy + radius * math.sin(angle) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(symbolX, symbolY));
      
      // 绘制八卦名称
      textPainter.text = TextSpan(
        text: baguaNames[i],
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8B0000), // 深红色
        ),
      );
      textPainter.layout();
      final nameX = center.dx + radius * 0.75 * math.cos(angle) - textPainter.width / 2;
      final nameY = center.dy + radius * 0.75 * math.sin(angle) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(nameX, nameY));
    }
  }
  
  @override
  bool shouldRepaint(covariant _MingPanAnimatedPainter old) {
    // 性能优化：精确判断是否需要重绘
    // 如果只是动画进度变化，总是需要重绘
    if (old.startupProgress != startupProgress || old.spinAngle != spinAngle) {
      return true;
    }
    // 其他属性变化也需要重绘
    return old.bazi.toString() != bazi.toString() ||
        old.selectedGong != selectedGong ||
        old.isDark != isDark ||
        (old.dayunResult?.dayuns.length ?? 0) != (dayunResult?.dayuns.length ?? 0);
  }
}
