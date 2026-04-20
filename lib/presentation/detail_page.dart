import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dayun.dart';
import '../core/liunian.dart';
import '../core/wuxing.dart' as wx;
import '../models/bazi.dart';
import 'widgets/dayun_timeline.dart';
import 'widgets/liunian_widget.dart';
import 'widgets/wuxing_chart.dart';

/// 命盘详情页
class DetailPage extends ConsumerStatefulWidget {
  final Bazi bazi;
  final DayunResult? dayunResult;

  const DetailPage({
    super.key,
    required this.bazi,
    this.dayunResult,
  });

  @override
  ConsumerState<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends ConsumerState<DetailPage> {
  // Spacing system: _gap=8, _gapMd=16, _gapLg=24, _gapXl=32
  static const _gap = 8.0;
  static const _gapMd = 16.0;
  static const _gapLg = 24.0;
  static const _gapXl = 32.0;

  Bazi get bazi => widget.bazi;
  DayunResult? get dayunResult => widget.dayunResult;

  /// 根据年份找到对应的大运（而非永远取 firstOrNull）
  Dayun? _getDayunForYear(int year) {
    if (dayunResult == null) return null;
    for (final d in dayunResult!.dayuns.reversed) {
      if (year >= d.startYear) return d;
    }
    return dayunResult!.dayuns.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final analysis = wx.analyzeBazi(bazi, gender: bazi.gender);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('命盘详情', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBaziOverview(),
            const SizedBox(height: _gap),
            _buildGlassExpansionTile(
              icon: Icons.view_agenda,
              title: '年柱 · 月柱',
              children: [
                _buildGanzhiRow('年柱', bazi.yearGanZhi),
                _buildGanzhiRow('月柱', bazi.monthGanZhi),
              ],
            ),
            _buildGlassExpansionTile(
              icon: Icons.view_agenda_outlined,
              title: '日柱 · 时柱',
              children: [
                _buildGanzhiRow('日柱', bazi.dayGanZhi),
                _buildGanzhiRow('时柱', bazi.hourGanZhi),
              ],
            ),
            if (dayunResult != null) ...[
              _buildGlassExpansionTile(
                icon: Icons.timeline,
                title: '大运时间线',
                initiallyExpanded: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: DayunTimeline(
                      dayunResult: dayunResult!,
                      currentYear: DateTime.now().year,
                      onDayunTap: (dayun) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (ctx) => Container(
                            decoration: BoxDecoration(
                              color: const Color(0xDD1a1a2e),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            child: DraggableScrollableSheet(
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
                                            color: Colors.white24,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: _gapMd + 4),
                                      DayunDetailCard(
                                        dayun: dayun,
                                        isCurrentDayun: _getDayunForYear(DateTime.now().year)?.index == dayun.index,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _gap),
            ],
            _buildGlassExpansionTile(
              icon: Icons.pie_chart,
              title: '五行能量分析',
              initiallyExpanded: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: WuxingEnergyChart(analysis: analysis),
                ),
              ],
            ),
            const SizedBox(height: _gap),
            _buildGlassExpansionTile(
              icon: Icons.layers,
              title: '地支藏干',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildCangganContent(analysis),
                ),
              ],
            ),
            const SizedBox(height: _gap),
            _buildGlassExpansionTile(
              icon: Icons.star,
              title: '十神分析',
              initiallyExpanded: false,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ShishenAnalysisCard(analysis: analysis),
                ),
              ],
            ),
            const SizedBox(height: _gap),
            _buildGlassExpansionTile(
              icon: Icons.calendar_today,
              title: '流年轮播',
              initiallyExpanded: false,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: LiunianCarousel(
                    bazi: bazi,
                    currentDayun: _getDayunForYear(DateTime.now().year),
                    initialYear: DateTime.now().year,
                  ),
                ),
              ],
            ),
            const SizedBox(height: _gap),
            _buildGlassExpansionTile(
              icon: Icons.grid_on,
              title: '流年网格（12年）',
              initiallyExpanded: false,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: LiunianGridView(
                    bazi: bazi,
                    currentDayun: _getDayunForYear(DateTime.now().year),
                    yearCount: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: _gapLg),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 四柱总览
  // ─────────────────────────────────────────────────────────────

  Widget _buildBaziOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '四柱八字',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: _gapMd),
          _buildGanzhiRow('年柱', bazi.yearGanZhi),
          _buildGanzhiRow('月柱', bazi.monthGanZhi),
          _buildGanzhiRow('日柱', bazi.dayGanZhi),
          _buildGanzhiRow('时柱', bazi.hourGanZhi),
          const SizedBox(height: _gap),
          Text(
            '日主${bazi.dayGan}，${wx.GAN_WUXING_WUXING[bazi.dayGan]}行',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassExpansionTile({
    required IconData icon,
    required String title,
    List<Widget> children = const [],
    bool initiallyExpanded = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.white.withValues(alpha: 0.1),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: Icon(icon, size: 20, color: Colors.amber.shade300),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          childrenPadding: EdgeInsets.zero,
          children: children,
        ),
      ),
    );
  }

  Widget _buildGanzhiRow(String label, String ganZhi) {
    final gan = ganZhi.length >= 1 ? ganZhi[0] : '';
    final color = _wuxingColor(gan);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            ),
          ),
          const SizedBox(width: _gap),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(
              ganZhi,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 地支藏干
  // ─────────────────────────────────────────────────────────────

  Widget _buildCangganContent(wx.BaziAnalysis analysis) {
    final details = analysis.cangganDetails;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCangganRow('年柱${bazi.yearZhi}', details[bazi.yearZhi] ?? ''),
        _buildCangganRow('月柱${bazi.monthZhi}', details[bazi.monthZhi] ?? ''),
        _buildCangganRow('日柱${bazi.dayZhi}', details[bazi.dayZhi] ?? ''),
        _buildCangganRow('时柱${bazi.hourZhi}', details[bazi.hourZhi] ?? ''),
      ],
    );
  }

  Widget _buildCangganRow(String label, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              detail,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 五行颜色映射
// ─────────────────────────────────────────────────────────────

const Map<String, Color> WUXING_COLORS = {
  '木': Color(0xFF4CAF50), // 绿色
  '火': Color(0xFFF44336), // 红色
  '土': Color(0xFF795548), // 棕色
  '金': Color(0xFFFFC107), // 金色
  '水': Color(0xFF2196F3), // 蓝色
};

Color _wuxingColor(String gan) {
  final wuxing = wx.GAN_WUXING_WUXING[gan] ?? '';
  return WUXING_COLORS[wuxing] ?? Colors.grey;
}

// ─────────────────────────────────────────────────────────────
// 辅助 Widgets（顶层类）
// ─────────────────────────────────────────────────────────────


