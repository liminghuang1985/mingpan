import 'package:flutter/material.dart';
import '../../core/liunian.dart';
import '../../core/dayun.dart';
import '../../models/bazi.dart';
import 'scroll_picker.dart';

/// 辅助函数:根据年份获取流年干支
Liunian _getLiunianForYear(int year) {
  final ganZhi = getLiunianGanZhi(year);
  const zhiOrder = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
  final zhi = ganZhi.length > 1 ? ganZhi[1] : '';
  final zhiIndex = zhiOrder.indexOf(zhi);

  return Liunian(
    year: year,
    ganZhi: ganZhi,
    zhiIndex: zhiIndex,
    chongHeRelations: [],
  );
}

/// 流年轮播卡片
///
/// 展示前后几年的流年信息,支持左右滑动
class LiunianCarousel extends StatefulWidget {
  final Bazi bazi;
  final Dayun? currentDayun;
  final int initialYear;

  const LiunianCarousel({
    super.key,
    required this.bazi,
    this.currentDayun,
    int? initialYear,
  }) : initialYear = initialYear ?? 0;

  @override
  State<LiunianCarousel> createState() => _LiunianCarouselState();
}

class _LiunianCarouselState extends State<LiunianCarousel> {
  late PageController _pageController;
  late int _currentYear;

  @override
  void initState() {
    super.initState();
    _currentYear = widget.initialYear > 0 ? widget.initialYear : DateTime.now().year;
    final baseYear = DateTime.now().year;
    // 初始页面 = 100(中间基准) + 相对偏移,页100=基准年,之后每页±1年
    _pageController = PageController(initialPage: 100 + (_currentYear - baseYear), viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 年份指示器
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              GestureDetector(
                onTap: () => _showYearPickerDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_currentYear年',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.unfold_more,
                        size: 18,
                        color: Colors.amber.shade700,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ],
          ),
        ),

        // 流年卡片轮播
        SizedBox(
          height: 380,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                // 100是基准页,index-100就是相对当前年的偏移
                final currentYear = DateTime.now().year;
                _currentYear = currentYear + (index - 100);
              });
            },
            itemBuilder: (context, index) {
              final currentYear = DateTime.now().year;
              final year = currentYear + (index - 100);
              final detail = getLiunianDetail(year, widget.bazi, dayun: widget.currentDayun);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: LiunianCard(
                  detail: detail,
                  year: year,
                  isCurrentYear: year == currentYear,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showYearPickerDialog(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(200, (i) => currentYear - 100 + i); // 前后100年
    final initialIndex = years.indexOf(_currentYear);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择年份', textAlign: TextAlign.center),
        content: SizedBox(
          height: 220,
          child: ScrollPicker(
            items: years.map((y) => y.toString()).toList(),
            initialIndex: initialIndex >= 0 ? initialIndex : 100,
            onSelectedItemChanged: (index) {
              _currentYear = years[index];
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              // 跳转到目标年份对应的页面
              final targetPage = 100 + (_currentYear - currentYear);
              _pageController.animateToPage(
                targetPage,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 单个流年卡片
class LiunianCard extends StatelessWidget {
  final LiunianDetail detail;
  final int year;
  final bool isCurrentYear;

  const LiunianCard({
    super.key,
    required this.detail,
    required this.year,
    this.isCurrentYear = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isCurrentYear ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrentYear
            ? BorderSide(color: Colors.amber.shade400, width: 3)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isCurrentYear
                ? [Colors.amber.shade50, Colors.amber.shade100]
                : [Colors.grey.shade50, Colors.grey.shade100],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCurrentYear
                            ? [Colors.amber.shade400, Colors.amber.shade600]
                            : [Colors.grey.shade400, Colors.grey.shade600],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      detail.liunian.ganZhi,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$year年流年',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCurrentYear)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '今年',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 流年概要
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  detail.summary,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),

              // 冲合关系
              if (detail.liunian.chongHeRelations.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: detail.liunian.chongHeRelations.map((relation) {
                    final isChong = relation.contains('冲');
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isChong ? Colors.red.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isChong ? Colors.red.shade300 : Colors.blue.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isChong ? Icons.flash_on : Icons.favorite,
                            size: 14,
                            color: isChong ? Colors.red.shade700 : Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            relation,
                            style: TextStyle(
                              fontSize: 12,
                              color: isChong ? Colors.red.shade700 : Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              const Spacer(),

              // 流月简览（固定高度预览，点击展开详情）
              GestureDetector(
                onTap: () => _showMonthDetailSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '流月详情 (${detail.months.length}个月)',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '点击查看',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: Colors.amber.shade700,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 固定高度预览网格（只显示前4个月）
                      SizedBox(
                        height: 44,
                        child: GridView.builder(
                          scrollDirection: Axis.horizontal,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            mainAxisSpacing: 6,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: detail.months.length > 4 ? 4 : detail.months.length,
                          itemBuilder: (context, index) {
                            final month = detail.months[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${month.month}月',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    month.ganZhi,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMonthDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$year年流月详情',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemCount: detail.months.length,
                itemBuilder: (context, index) {
                  final month = detail.months[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${month.month}月',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          month.ganZhi,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 流年网格视图(年历式)
class LiunianGridView extends StatelessWidget {
  final Bazi bazi;
  final Dayun? currentDayun;
  final int startYear;
  final int yearCount;

  const LiunianGridView({
    super.key,
    required this.bazi,
    this.currentDayun,
    int? startYear,
    this.yearCount = 12,
  }) : startYear = startYear ?? 0;

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final baseYear = startYear > 0 ? startYear : currentYear - 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: yearCount,
      itemBuilder: (context, index) {
        final year = baseYear + index;
        final liunian = _getLiunianForYear(year);
        final isCurrentYear = year == currentYear;

        return GestureDetector(
          onTap: () {
            _showLiunianDetail(context, year, bazi, currentDayun);
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isCurrentYear
                    ? [Colors.amber.shade300, Colors.amber.shade500]
                    : [Colors.grey.shade200, Colors.grey.shade300],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isCurrentYear
                  ? [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$year',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCurrentYear ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    liunian.ganZhi,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isCurrentYear ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isCurrentYear)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '今年',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLiunianDetail(BuildContext context, int year, Bazi bazi, Dayun? dayun) {
    final detail = getLiunianDetail(year, bazi, dayun: dayun);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
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
                const SizedBox(height: 20),
                LiunianCard(
                  detail: detail,
                  year: year,
                  isCurrentYear: year == DateTime.now().year,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
