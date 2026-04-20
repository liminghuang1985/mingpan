import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/bazi.dart';
import '../core/dayun.dart';
import '../core/wuxing.dart' as wx;
import '../models/bazi.dart';
import 'detail_page.dart';
import 'mingpan_animated_canvas.dart';
import 'widgets/scroll_picker.dart';

// ==================== State Providers ====================

final birthDateProvider = StateProvider<DateTime>((ref) => DateTime(2000, 1, 1));
final birthHourProvider = StateProvider<int>((ref) => 12);
final birthMinuteProvider = StateProvider<int>((ref) => 0);
final genderProvider = StateProvider<String>((ref) => '男');
final baziResultProvider = StateProvider<Bazi?>((ref) => null);
final dayunResultProvider = StateProvider<DayunResult?>((ref) => null);
final isCalculatingProvider = StateProvider<bool>((ref) => false);
final animationEnabledProvider = StateProvider<bool>((ref) => true);
final currentTabProvider = StateProvider<int>((ref) => 0);

// ==================== 主入口：底部导航 Scaffold ====================

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(currentTabProvider);
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: const [
          _HomeTab(),
          _MingPanTab(),
          DetailPageBody(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => ref.read(currentTabProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: '命盘'),
          NavigationDestination(icon: Icon(Icons.info_outline), selectedIcon: Icon(Icons.info), label: '详情'),
        ],
      ),
    );
  }
}

// ==================== 第一页：首页（输入）====================

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  final GlobalKey _repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final birthDate = ref.watch(birthDateProvider);
    final birthHour = ref.watch(birthHourProvider);
    final birthMinute = ref.watch(birthMinuteProvider);
    final gender = ref.watch(genderProvider);
    final baziResult = ref.watch(baziResultProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景图
        Image.asset(
          'assets/images/bg_page1.jpg',
          fit: BoxFit.cover,
        ),
        // 底部渐变遮罩，让底部文字更清晰
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.5),
              ],
            ),
          ),
        ),
        // 内容
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // 标题
                Center(
                  child: Text(
                    '命盘排盘',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 8),
                      ],
                      letterSpacing: 6,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // 日期时间选择 - 直接浮在背景上
                _buildInputRow(context, ref, birthDate, birthHour, birthMinute),
                const SizedBox(height: 20),
                // 性别选择
                _buildGenderRow(ref, gender),
                const SizedBox(height: 32),
                // 排盘按钮
                _buildPaiPanButton(context, ref, birthDate, birthHour, birthMinute, gender, baziResult),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputRow(BuildContext context, WidgetRef ref, DateTime birthDate, int hour, int minute) {
    final hourStr = hour.toString().padLeft(2, '0');
    final minStr = minute.toString().padLeft(2, '0');

    return Row(
      children: [
        Expanded(child: _buildDateTile(ref, birthDate)),
        const SizedBox(width: 16),
        Expanded(child: _buildTimeTile(ref, hour, minStr)),
      ],
    );
  }

  Widget _buildDateTile(WidgetRef ref, DateTime date) {
    return _GlassTile(
      onTap: () => _showDatePicker(ref, date),
      icon: Icons.calendar_today,
      label: '出生日期',
      value: DateFormat('yyyy年MM月dd日').format(date),
    );
  }

  Widget _buildTimeTile(WidgetRef ref, int hour, String minute) {
    return _GlassTile(
      onTap: () => _showDatePicker(ref, ref.read(birthDateProvider)),
      icon: Icons.access_time,
      label: '出生时间',
      value: '${hour.toString().padLeft(2, '0')}:$minute',
    );
  }

  Widget _buildGenderRow(WidgetRef ref, String gender) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildGenderChip(ref, '男', Icons.male, gender == '男'),
        const SizedBox(width: 24),
        _buildGenderChip(ref, '女', Icons.female, gender == '女'),
      ],
    );
  }

  Widget _buildGenderChip(WidgetRef ref, String label, IconData icon, bool selected) {
    return GestureDetector(
      onTap: () => ref.read(genderProvider.notifier).state = label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? Colors.amber.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? Colors.amber : Colors.white.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? Colors.amber : Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.amber : Colors.white70,
                fontSize: 16,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaiPanButton(
    BuildContext context,
    WidgetRef ref,
    DateTime birthDate,
    int hour,
    int minute,
    String gender,
    Bazi? baziResult,
  ) {
    return GestureDetector(
      onTap: () => _calculateAndNavigate(context, ref, birthDate, hour, minute, gender),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade600, Colors.amber.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              '排  盘',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker(WidgetRef ref, DateTime initial) {
    final now = DateTime.now();
    final currentDateTime = DateTime(
      ref.read(birthDateProvider).year,
      ref.read(birthDateProvider).month,
      ref.read(birthDateProvider).day,
      ref.read(birthHourProvider),
      ref.read(birthMinuteProvider),
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xDD1a1a2e),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.white70))),
                  const Text('选择出生日期时间', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () => Navigator.pop(ctx, currentDateTime), child: const Text('确定', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: DateTimeScrollPicker(
                initialDate: currentDateTime,
                firstDate: DateTime(1900),
                lastDate: now,
                onDateTimeChanged: (dt) {
                  ref.read(birthDateProvider.notifier).state = dt;
                  ref.read(birthHourProvider.notifier).state = dt.hour;
                  ref.read(birthMinuteProvider.notifier).state = dt.minute;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _calculateAndNavigate(
    BuildContext context,
    WidgetRef ref,
    DateTime birthDate,
    int hour,
    int minute,
    String gender,
  ) async {
    ref.read(isCalculatingProvider.notifier).state = true;
    await Future.delayed(const Duration(milliseconds: 300));
    final bazi = Bazi.fromResult(
      calculateBazi(birthDate.year, birthDate.month, birthDate.day, hour, minute),
      birthDate,
      gender,
    );
    final dayunResult = calculateDayun(bazi, birthDate);
    ref.read(baziResultProvider.notifier).state = bazi;
    ref.read(dayunResultProvider.notifier).state = dayunResult;
    ref.read(isCalculatingProvider.notifier).state = false;
    ref.read(currentTabProvider.notifier).state = 1;
  }
}

// ==================== 磨砂玻璃瓦片组件 ====================

class _GlassTile extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final String value;

  const _GlassTile({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.amber.shade300, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 第二页：命盘展示 ====================

class _MingPanTab extends ConsumerWidget {
  const _MingPanTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bazi = ref.watch(baziResultProvider);
    final dayunResult = ref.watch(dayunResultProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景图
        Image.asset(
          'assets/images/bg_page2.jpg',
          fit: BoxFit.cover,
        ),
        // 半透明遮罩
        Container(color: Colors.black.withValues(alpha: 0.35)),
        // 内容
        SafeArea(
          child: Column(
            children: [
              // 八字头部
              if (bazi != null) _buildBaziHeader(bazi, wx.analyzeBazi(bazi, gender: bazi.gender)),
              if (bazi == null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_outlined, size: 64, color: Colors.white.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(
                          '暂无命盘数据',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBaziHeader(Bazi bazi, wx.BaziAnalysis analysis) {
    final strength = analysis.strength;
    Color strengthColor;
    String strengthLabel;
    if (strength.level == wx.StrengthLevel.qiang || strength.level == wx.StrengthLevel.pianQiang) {
      strengthColor = Colors.redAccent;
      strengthLabel = '强';
    } else if (strength.level == wx.StrengthLevel.zhongHe) {
      strengthColor = Colors.amber;
      strengthLabel = '中和';
    } else {
      strengthColor = Colors.cyanAccent;
      strengthLabel = '弱';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGanZhiText('年', bazi.yearGanZhi, Colors.indigoAccent),
              _buildGanZhiText('月', bazi.monthGanZhi, Colors.tealAccent),
              _buildGanZhiText('日', bazi.dayGanZhi, Colors.deepOrangeAccent),
              _buildGanZhiText('时', bazi.hourGanZhi, Colors.purpleAccent),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '日主${bazi.dayGan} · ${wx.GAN_WUXING_WUXING[bazi.dayGan]}行  $strengthLabel',
              style: TextStyle(color: strengthColor, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGanZhiText(String label, String gz, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          gz,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4)],
          ),
        ),
      ],
    );
  }
}

// ==================== 详情页（第三页）====================

class DetailPageBody extends ConsumerWidget {
  const DetailPageBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bazi = ref.watch(baziResultProvider);
    final dayunResult = ref.watch(dayunResultProvider);

    if (bazi == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg_page3.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.35)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 64, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text(
                  '暂无命盘数据',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/bg_page3.jpg', fit: BoxFit.cover),
        Container(color: Colors.black.withValues(alpha: 0.35)),
        SafeArea(
          child: DetailPage(bazi: bazi, dayunResult: dayunResult),
        ),
      ],
    );
  }
}
