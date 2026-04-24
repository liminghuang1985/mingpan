import 'package:flutter/material.dart';
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

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: ref.read(currentTabProvider));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(currentTabProvider);
    // 同步 PageView 到正确页面（外部改变 tab 时）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients && _pageController.page?.round() != tab) {
        _pageController.jumpToPage(tab);
      }
    });
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => ref.read(currentTabProvider.notifier).state = i,
        children: const [
          _HomeTab(),
          _MingPanTab(),
          DetailPageBody(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) {
          ref.read(currentTabProvider.notifier).state = i;
          _pageController.animateToPage(
            i,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
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
        Image.asset('assets/images/bg_page3.jpg', fit: BoxFit.cover),
        // 底部渐变遮罩
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
        // 内容
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // 日期和时间标签行
                Row(
                  children: const [
                    Expanded(
                      child: Text(
                        '出生日期',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '出生时间',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // 日期和时间左右并排（去掉玻璃框，只留文字悬浮）
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showDatePicker(ref, birthDate),
                        child: Text(
                          '${DateFormat('yyyy年MM月dd日').format(birthDate)}  ▼',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showTimePicker(ref),
                        child: Text(
                          '${birthHour.toString().padLeft(2, '0')}:${birthMinute.toString().padLeft(2, '0')}  ▼',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildGenderRow(WidgetRef ref, String gender) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildGenderChip(ref, '男', Icons.male, gender == '男', Colors.amber),
        const SizedBox(width: 24),
        _buildGenderChip(ref, '女', Icons.female, gender == '女', Colors.purple),
      ],
    );
  }

  Widget _buildGenderChip(WidgetRef ref, String label, IconData icon, bool selected, Color selectedColor) {
    return GestureDetector(
      onTap: () => ref.read(genderProvider.notifier).state = label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? selectedColor : Colors.white.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? selectedColor : Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? selectedColor : Colors.white70,
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

  // 单独日期选择器
  void _showDatePicker(WidgetRef ref, DateTime initial) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.65,
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
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('取消', style: TextStyle(color: Colors.white70)),
                  ),
                  const Text('选择出生日期', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('确定', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: _DateOnlyPicker(
                initialDate: initial,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                onDateChanged: (date) {
                  ref.read(birthDateProvider.notifier).state = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    ref.read(birthHourProvider),
                    ref.read(birthMinuteProvider),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 单独时间选择器
  void _showTimePicker(WidgetRef ref) {
    final currentHour = ref.read(birthHourProvider);
    final currentMinute = ref.read(birthMinuteProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.5,
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
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('取消', style: TextStyle(color: Colors.white70)),
                  ),
                  const Text('选择出生时间', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      // 实时读取最新的 provider 值（用户可能滚动了滚轮）
                      ref.read(birthHourProvider.notifier).state = ref.read(birthHourProvider);
                      ref.read(birthMinuteProvider.notifier).state = ref.read(birthMinuteProvider);
                      Navigator.pop(ctx);
                    },
                    child: const Text('确定', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: _TimeOnlyPicker(
                initialHour: currentHour,
                initialMinute: currentMinute,
                onTimeChanged: (h, m) {
                  ref.read(birthHourProvider.notifier).state = h;
                  ref.read(birthMinuteProvider.notifier).state = m;
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
    // 切换到第二页（通过 MainScaffold 状态触发 jumpToPage）
    ref.read(currentTabProvider.notifier).state = 1;
  }
}

// ==================== 日期选择器（仅日期）====================

class _DateOnlyPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateChanged;

  const _DateOnlyPicker({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
  });

  @override
  State<_DateOnlyPicker> createState() => _DateOnlyPickerState();
}

class _DateOnlyPickerState extends State<_DateOnlyPicker> {
  late int _year;
  late int _month;
  late int _day;

  late final FixedExtentScrollController _yearController;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _dayController;

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
    _day = widget.initialDate.day;
    _yearController = FixedExtentScrollController(
      initialItem: _year - widget.firstDate.year,
    );
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  void _onYearChanged(int year) {
    final maxDay = DateTime(year, _month, 0).day;
    setState(() {
      _year = year;
      if (_day > maxDay) {
        _day = maxDay;
        _dayController.jumpToItem(_day - 1);
      }
    });
    widget.onDateChanged(DateTime(_year, _month, _day));
  }

  void _onMonthChanged(int month) {
    final maxDay = DateTime(_year, month, 0).day;
    setState(() {
      _month = month;
      if (_day > maxDay) {
        _day = maxDay;
        _dayController.jumpToItem(_day - 1);
      }
    });
    widget.onDateChanged(DateTime(_year, _month, _day));
  }

  void _onDayChanged(int day) {
    setState(() => _day = day);
    widget.onDateChanged(DateTime(_year, _month, _day));
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(
      widget.lastDate.year - widget.firstDate.year + 1,
      (i) => widget.firstDate.year + i,
    );
    final months = List.generate(12, (i) => i + 1);
    final daysInMonth = DateTime(_year, _month, 0).day;
    final days = List.generate(daysInMonth, (i) => i + 1);

    return Row(
      children: [
        Expanded(
          child: _WheelPickerColumn(
            items: years,
            selected: _year,
            label: '年',
            controller: _yearController,
            onChanged: _onYearChanged,
          ),
        ),
        Expanded(
          child: _WheelPickerColumn(
            items: months,
            selected: _month,
            label: '月',
            controller: _monthController,
            onChanged: _onMonthChanged,
          ),
        ),
        Expanded(
          child: _WheelPickerColumn(
            items: days,
            selected: _day,
            label: '日',
            controller: _dayController,
            onChanged: _onDayChanged,
          ),
        ),
      ],
    );
  }
}

// ==================== 时间选择器（仅时间）====================

class _TimeOnlyPicker extends StatefulWidget {
  final int initialHour;
  final int initialMinute;
  final void Function(int hour, int minute) onTimeChanged;

  const _TimeOnlyPicker({
    required this.initialHour,
    required this.initialMinute,
    required this.onTimeChanged,
  });

  @override
  State<_TimeOnlyPicker> createState() => _TimeOnlyPickerState();
}

class _TimeOnlyPickerState extends State<_TimeOnlyPicker> {
  late int _hour;
  late int _minute;

  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialHour;
    _minute = widget.initialMinute;
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _onHourChanged(int index) {
    setState(() => _hour = index);
    widget.onTimeChanged(_hour, _minute);
  }

  void _onMinuteChanged(int index) {
    setState(() => _minute = index);
    widget.onTimeChanged(_hour, _minute);
  }

  @override
  Widget build(BuildContext context) {
    final hours = List.generate(24, (i) => i);
    final minutes = List.generate(60, (i) => i);

    return Row(
      children: [
        Expanded(
          child: _WheelPickerColumn(
            items: hours,
            selected: _hour,
            label: '时',
            controller: _hourController,
            onChanged: _onHourChanged,
          ),
        ),
        Expanded(
          child: _WheelPickerColumn(
            items: minutes,
            selected: _minute,
            label: '分',
            controller: _minuteController,
            onChanged: _onMinuteChanged,
          ),
        ),
      ],
    );
  }
}

// ==================== 滚轮列组件 ====================

class _WheelPickerColumn extends StatelessWidget {
  final List<int> items;
  final int selected;
  final String label;
  final FixedExtentScrollController controller;
  final void Function(int value) onChanged;

  const _WheelPickerColumn({
    required this.items,
    required this.selected,
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIndex = items.indexOf(selected.clamp(items.first, items.last));
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
        ),
        Expanded(
          child: ListWheelScrollView.useDelegate(
            itemExtent: 40,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) => onChanged(items[index]),
            controller: FixedExtentScrollController(initialItem: selectedIndex.clamp(0, items.length - 1)),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: items.length,
              builder: (ctx, i) {
                final isSelected = i == selectedIndex;
                return Center(
                  child: Text(
                    items[i] >= 100
                        ? items[i].toString()
                        : items[i].toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: isSelected ? Colors.amber : Colors.white.withValues(alpha: 0.7),
                      fontSize: isSelected ? 22 : 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
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
        child: Row(
          children: [
            Icon(icon, color: Colors.amber.shade300, size: 22),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
        // 内容 - 八字头部居中偏下
        SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 1),
              // 八字头部
              if (bazi != null) _buildBaziHeader(bazi, wx.analyzeBazi(bazi, gender: bazi.gender)),
              if (bazi == null)
                Column(
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
              const Spacer(flex: 2),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          Image.asset('assets/images/bg_page1.jpg', fit: BoxFit.cover),
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
        Image.asset('assets/images/bg_page1.jpg', fit: BoxFit.cover),
        Container(color: Colors.black.withValues(alpha: 0.35)),
        SafeArea(
          child: DetailPage(bazi: bazi, dayunResult: dayunResult),
        ),
      ],
    );
  }
}
