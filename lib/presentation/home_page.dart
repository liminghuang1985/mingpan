import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/bazi.dart';
import '../core/dayun.dart';
import '../core/wuxing.dart' as wx;
import '../core/responsive.dart';
import '../models/bazi.dart';
import 'detail_page.dart';
import 'mingpan_animated_canvas.dart';
import 'widgets/scroll_picker.dart';

// ==================== State Providers ====================

/// 出生日期
final birthDateProvider = StateProvider<DateTime>((ref) {
  return DateTime(2000, 1, 1);
});

/// 出生小时（0-23）
final birthHourProvider = StateProvider<int>((ref) => 12);

/// 出生分钟（0-59）
final birthMinuteProvider = StateProvider<int>((ref) => 0);

/// 性别
final genderProvider = StateProvider<String>((ref) => '男');

/// 计算结果（null 表示未计算）
final baziResultProvider = StateProvider<Bazi?>((ref) => null);

/// 大运结果
final dayunResultProvider = StateProvider<DayunResult?>((ref) => null);

/// 排盘计算中状态
final isCalculatingProvider = StateProvider<bool>((ref) => false);

/// 命盘动画开关（默认开启）
final animationEnabledProvider = StateProvider<bool>((ref) => true);

// ==================== Home Page ====================

/// 命盘首页
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // Spacing system: _gap=8, _gapMd=16, _gapLg=24, _gapXl=32
  static const _gap = 8.0;
  static const _gapMd = 16.0;
  static const _gapLg = 24.0;
  static const _gapXl = 32.0;

  final GlobalKey _repaintKey = GlobalKey();

  Future<void> _shareMingPan() async {
    // Web HTML renderer 不支持 RenderRepaintBoundary.toImage()
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Web 端请使用浏览器截图功能（如 Ctrl+Shift+S）')),
      );
      return;
    }
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('命盘截图已生成 (${bytes.length ~/ 1024}KB)，可保存或分享'),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: '确定',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('截图失败：$e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final birthDate = ref.watch(birthDateProvider);
    final birthHour = ref.watch(birthHourProvider);
    final birthMinute = ref.watch(birthMinuteProvider);
    final gender = ref.watch(genderProvider);
    final baziResult = ref.watch(baziResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('命盘排盘'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 日期时间选择
            _buildDateSelector(context, ref, birthDate),
            const SizedBox(height: _gapMd),

            // 性别选择
            _buildGenderSelector(context, ref, gender),
            const SizedBox(height: _gapLg),

            // 计算按钮
            FilledButton.icon(
              onPressed: () => _calculate(context, ref, birthDate, birthHour, birthMinute, gender),
              icon: const Icon(Icons.calculate),
              label: const Text('排盘'),
            ),
            const SizedBox(height: _gapLg),

            // 结果展示
            if (ref.watch(isCalculatingProvider)) ...[
              const SizedBox(height: _gapLg),
              const Center(child: CircularProgressIndicator()),
            ] else if (baziResult != null) ...[
              _buildResultCard(context, ref, baziResult),
              const SizedBox(height: _gapLg),
              _buildMingPanCanvas(context, ref, baziResult),
              const SizedBox(height: _gapLg),
              // 截图分享按钮
              OutlinedButton.icon(
                onPressed: _shareMingPan,
                icon: const Icon(Icons.share),
                label: const Text('截图分享'),
              ),
              const SizedBox(height: _gap),
              // 详情按钮
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailPage(
                        bazi: baziResult,
                        dayunResult: ref.watch(dayunResultProvider),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('查看详情'),
              ),
            ] else ...[
              const SizedBox(height: _gapXl * 1.5),
              _buildEmptyState(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: _gapMd),
        padding: const EdgeInsets.all(_gapXl * 1.5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber.shade50,
              Colors.amber.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.amber.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.amber.shade300,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 40,
                color: Colors.amber.shade700,
              ),
            ),
            const SizedBox(height: _gapLg),
            Text(
              '选择日期，点击排盘',
              style: TextStyle(
                color: Colors.amber.shade900,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: _gap),
            Text(
              '八字命盘将显示在此处',
              style: TextStyle(
                color: Colors.amber.shade700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, WidgetRef ref, DateTime date) {
    final hour = ref.watch(birthHourProvider);
    final minute = ref.watch(birthMinuteProvider);
    final currentDateTime = DateTime(date.year, date.month, date.day, hour, minute);
    
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: const Text('出生日期时间'),
        subtitle: Text(
          '${DateFormat('yyyy年MM月dd日').format(date)} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showScrollPickerDialog(context, ref, currentDateTime);
        },
      ),
    );
  }
  
  void _showScrollPickerDialog(BuildContext context, WidgetRef ref, DateTime initialDateTime) {
    DateTime selectedDateTime = initialDateTime;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 顶部栏
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('取消'),
                  ),
                  const Text(
                    '选择出生日期时间',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, selectedDateTime),
                    child: const Text('确定', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 滚动选择器
            Expanded(
              child: DateTimeScrollPicker(
                initialDate: initialDateTime,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                onDateTimeChanged: (DateTime newDateTime) {
                  selectedDateTime = newDateTime;
                },
              ),
            ),
          ],
        ),
      ),
    ).then((result) {
      if (result != null && result is DateTime) {
        ref.read(birthDateProvider.notifier).state = result;
        ref.read(birthHourProvider.notifier).state = result.hour;
        ref.read(birthMinuteProvider.notifier).state = result.minute;
      }
    });
  }

  // 已合并到日期选择器中

  Widget _buildGenderSelector(BuildContext context, WidgetRef ref, String gender) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person),
                SizedBox(width: _gap),
                Text('性别', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: _gapMd),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.male, size: 18),
                        SizedBox(width: _gap),
                        Text('男'),
                      ],
                    ),
                    selected: gender == '男',
                    onSelected: (_) => ref.read(genderProvider.notifier).state = '男',
                  ),
                ),
                const SizedBox(width: _gapMd),
                Expanded(
                  child: ChoiceChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.female, size: 18),
                        SizedBox(width: _gap),
                        Text('女'),
                      ],
                    ),
                    selected: gender == '女',
                    onSelected: (_) => ref.read(genderProvider.notifier).state = '女',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, WidgetRef ref, Bazi bazi) {
    final dayunResult = ref.watch(dayunResultProvider);
    final analysis = wx.analyzeBazi(bazi, gender: bazi.gender);
    final strength = analysis.strength;
    final wuxingScore = analysis.wuxingScore;

    // 日主强弱徽章
    String strengthBadge;
    String strengthEmoji;
    Color strengthColor;
    switch (strength.level) {
      case wx.StrengthLevel.pianQiang:
      case wx.StrengthLevel.qiang:
        strengthBadge = '强';
        strengthEmoji = '💪';
        strengthColor = Colors.red;
      case wx.StrengthLevel.zhongHe:
        strengthBadge = '中和';
        strengthEmoji = '⚖️';
        strengthColor = Colors.amber;
      case wx.StrengthLevel.ruo:
      case wx.StrengthLevel.pianRuo:
        strengthBadge = '弱';
        strengthEmoji = '🧍';
        strengthColor = Colors.blue;
    }

    // 五行旺度
    final total = wuxingScore.total == 0 ? 1 : wuxingScore.total;
    final wuxingBars = [
      ('木', wuxingScore.mu, Colors.green, '🟢'),
      ('火', wuxingScore.huo, Colors.red, '🔴'),
      ('土', wuxingScore.tu, Colors.brown, '🟤'),
      ('金', wuxingScore.jin, Colors.blueGrey, '⬜'),
      ('水', wuxingScore.shui, Colors.cyan, '🔵'),
    ];

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '八字排盘结果',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: _gapMd),
                // 日主强弱徽章
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: strengthColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: strengthColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '$strengthEmoji $strengthBadge',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: strengthColor,
                    ),
                  ),
                ),
                const SizedBox(width: _gap),
                // 五行徽章
                Text(
                  '日主${wx.GAN_WUXING_WUXING[bazi.dayGan]}行',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: _gapMd),
            // 五行旺度条
            Row(
              children: wuxingBars.map((wb) {
                final pct = (wb.$2 / total).clamp(0.0, 1.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Text(wb.$4, style: const TextStyle(fontSize: 10)),
                        const SizedBox(height: _gap),
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.bottomCenter,
                            heightFactor: pct,
                            child: Container(
                              decoration: BoxDecoration(
                                color: wb.$3,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: _gap),
                        Text('${(pct * 100).toInt()}%', style: const TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: _gapMd),
            _buildGanzhiRow('年柱', bazi.yearGanZhi),
            _buildGanzhiRow('月柱', bazi.monthGanZhi),
            _buildGanzhiRow('日柱', bazi.dayGanZhi),
            _buildGanzhiRow('时柱', bazi.hourGanZhi),
            if (dayunResult != null) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '大运：${dayunResult.direction.nameCn}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: _gapMd),
                  Text(
                    '起运：${dayunResult.qiyun.sui}岁${dayunResult.qiyun.yue}月',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGanzhiRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: _gap),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMingPanCanvas(BuildContext context, WidgetRef ref, Bazi bazi) {
    final animationEnabled = ref.watch(animationEnabledProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 使用响应式尺寸
    final size = Responsive.getMingPanSize(context);

    return Center(
      child: Column(
        children: [
          // 动画开关
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                animationEnabled ? '动画旋转中' : '动画已关闭',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 11),
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(width: Responsive.spacing(context, _gap)),
              IconButton(
                icon: Icon(
                  animationEnabled ? Icons.pause_circle : Icons.play_circle,
                  color: animationEnabled ? Colors.amber.shade700 : Colors.grey,
                ),
                iconSize: Responsive.value(context, mobile: 28, tablet: 32, desktop: 36),
                onPressed: () {
                  ref.read(animationEnabledProvider.notifier).state = !animationEnabled;
                },
                tooltip: animationEnabled ? '关闭动画' : '开启动画',
              ),
            ],
          ),
          RepaintBoundary(
            key: _repaintKey,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(Responsive.value(context, mobile: 16, tablet: 20, desktop: 24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(Responsive.spacing(context, _gap)),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: MingPanAnimatedCanvas(
                    bazi: bazi,
                    autoPlay: animationEnabled,
                    dayunResult: ref.watch(dayunResultProvider),
                    isDark: isDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _calculate(
    BuildContext context,
    WidgetRef ref,
    DateTime birthDate,
    int hour,
    int minute,
    String gender,
  ) {
    // 日期校验：1900-2100年范围
    if (birthDate.year < 1900 || birthDate.year > 2100) {
      _showError(context, '日期范围仅支持1900-2100年');
      return;
    }

    // 时间校验
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      _showError(context, '请输入有效的出生时间');
      return;
    }

    ref.read(isCalculatingProvider.notifier).state = true;
    try {
      // 计算八字
      final result = calculateBazi(
        birthDate.year,
        birthDate.month,
        birthDate.day,
        hour,
        minute,
      );

      final bazi = Bazi.fromResult(result, birthDate, gender);
      ref.read(baziResultProvider.notifier).state = bazi;

      // 计算大运
      final dayun = calculateDayun(bazi, birthDate);
      ref.read(dayunResultProvider.notifier).state = dayun;
    } catch (e) {
      _showError(context, '计算出错：${e.toString()}');
    } finally {
      ref.read(isCalculatingProvider.notifier).state = false;
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
