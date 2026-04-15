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

// ==================== 第一页：首页（输入） ====================

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
          'assets/images/home_bg.jpg',
          fit: BoxFit.cover,
        ),
        // 半透明遮罩，让文字和按钮更清晰
        Container(color: Colors.black.withValues(alpha: 0.3)),
        // 内容
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const Spacer(),
                // 日期时间选择区
                _buildInputCard(context, ref, birthDate, birthHour, birthMinute, gender),
                const SizedBox(height: 20),
                // 排盘按钮
                _buildPaiPanButton(context, ref, birthDate, birthHour, birthMinute, gender, baziResult),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard(BuildContext context, WidgetRef ref, DateTime birthDate, int hour, int minute, String gender) {
    final hourStr = hour.toString().padLeft(2, '0');
    final minStr = minute.toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
            offset: Offset.zero,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 标题
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.amber.shade300, size: 22),
                    const SizedBox(width: 8),
                    Text('命盘排盘', style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                    )),
                  ],
                ),
                const SizedBox(height: 20),
                // 日期 + 时间 左右分栏
                Row(
                  children: [
                    Expanded(child: _buildDateTile(ref, birthDate)),
                    Container(width: 1, height: 50, color: Colors.white.withValues(alpha: 0.2), margin: const EdgeInsets.symmetric(horizontal: 12)),
                    Expanded(child: _buildTimeTile(ref, hour, minStr)),
                  ],
                ),
                const SizedBox(height: 16),
                // 性别选择
                _buildGenderRow(ref, gender),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTile(WidgetRef ref, DateTime date) {
    return InkWell(
      onTap: () => _showDatePicker(ref, date),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(Icons.calendar_today, color: Colors.amber.shade300, size: 20),
            const SizedBox(height: 6),
            Text('出生日期', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text(DateFormat('yyyy年MM月dd日').format(date),
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile(WidgetRef ref, int hour, String minute) {
    return InkWell(
      onTap: () => _showDatePicker(ref, ref.read(birthDateProvider)),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(Icons.access_time, color: Colors.amber.shade300, size: 20),
            const SizedBox(height: 6),
            Text('出生时间', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text('${hour.toString().padLeft(2, '0')}:$minute',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderRow(WidgetRef ref, String gender) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildGenderChip(ref, '男', Icons.male, gender == '男'),
        const SizedBox(width: 16),
        _buildGenderChip(ref, '女', Icons.female, gender == '女'),
      ],
    );
  }

  Widget _buildGenderChip(WidgetRef ref, String label, IconData icon, bool selected) {
    return GestureDetector(
      onTap: () => ref.read(genderProvider.notifier).state = label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.amber.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? Colors.amber : Colors.white.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.amber : Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: selected ? Colors.amber : Colors.white70,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPaiPanButton(BuildContext context, WidgetRef ref, DateTime birthDate, int hour, int minute, String gender, Bazi? baziResult) {
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
            Text('排  盘', style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            )),
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

  Future<void> _calculateAndNavigate(BuildContext context, WidgetRef ref, DateTime birthDate, int hour, int minute, String gender) async {
    ref.read(isCalculatingProvider.notifier).state = true;

    await Future.delayed(const Duration(milliseconds: 300));

    final bazi = Bazi.fromResult(calculateBazi(birthDate.year, birthDate.month, birthDate.day, hour, minute), birthDate, gender);
    final dayunResult = calculateDayun(bazi, birthDate);

    ref.read(baziResultProvider.notifier).state = bazi;
    ref.read(dayunResultProvider.notifier).state = dayunResult;
    ref.read(isCalculatingProvider.notifier).state = false;

    // 跳到命盘页
    ref.read(currentTabProvider.notifier).state = 1;
  }
}

// ==================== 第二页：命盘展示 ====================

class _MingPanTab extends ConsumerWidget {
  const _MingPanTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bazi = ref.watch(baziResultProvider);
    final dayunResult = ref.watch(dayunResultProvider);

    if (bazi == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_outlined, size: 64, color: Colors.white30),
            SizedBox(height: 16),
            Text('暂无命盘数据', style: TextStyle(color: Colors.white54, fontSize: 16)),
            SizedBox(height: 8),
            Text('请先在首页进行排盘', style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
      );
    }

    final analysis = wx.analyzeBazi(bazi, gender: bazi.gender);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 八字结果头部
            _buildBaziHeader(bazi, analysis),
            const Divider(color: Colors.white12),
            // 命盘动画
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: MingPanAnimatedCanvas(
                  bazi: bazi,
                  autoPlay: true,
                  dayunResult: dayunResult,
                  isDark: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBaziHeader(Bazi bazi, wx.BaziAnalysis analysis) {
    final strength = analysis.strength;
    Color strengthColor;
    String strengthLabel;
    if (strength.level == wx.StrengthLevel.qiang || strength.level == wx.StrengthLevel.pianQiang) {
      strengthColor = Colors.redAccent; strengthLabel = '强';
    } else if (strength.level == wx.StrengthLevel.zhongHe) {
      strengthColor = Colors.amber; strengthLabel = '中和';
    } else {
      strengthColor = Colors.cyanAccent; strengthLabel = '弱';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGanZhiPill('年', bazi.yearGanZhi, Colors.indigoAccent),
              _buildGanZhiPill('月', bazi.monthGanZhi, Colors.tealAccent),
              _buildGanZhiPill('日', bazi.dayGanZhi, Colors.deepOrangeAccent),
              _buildGanZhiPill('时', bazi.hourGanZhi, Colors.purpleAccent),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: strengthColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: strengthColor.withValues(alpha: 0.5)),
                ),
                child: Text('日主${bazi.dayGan} · ${wx.GAN_WUXING_WUXING[bazi.dayGan]}行  $strengthLabel',
                  style: TextStyle(color: strengthColor, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGanZhiPill(String label, String gz, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(gz, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.white30),
            SizedBox(height: 16),
            Text('暂无命盘数据', style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      );
    }

    return DetailPage(bazi: bazi, dayunResult: dayunResult);
  }
}
