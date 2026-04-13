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
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

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
      appBar: AppBar(
        title: const Text('命盘详情'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBaziOverview(),
            const SizedBox(height: 8),
            ExpansionTile(
              leading: const Icon(Icons.view_agenda, size: 20),
              title: const Text('年柱 · 月柱', style: TextStyle(fontWeight: FontWeight.bold)),
              children: [
                _buildGanzhiRow('年柱', bazi.yearGanZhi, Colors.indigo),
                _buildGanzhiRow('月柱', bazi.monthGanZhi, Colors.teal),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.view_agenda_outlined, size: 20),
              title: const Text('日柱 · 时柱', style: TextStyle(fontWeight: FontWeight.bold)),
              children: [
                _buildGanzhiRow('日柱', bazi.dayGanZhi, Colors.deepOrange),
                _buildGanzhiRow('时柱', bazi.hourGanZhi, Colors.purple),
              ],
            ),
            if (dayunResult != null) ...[
              ExpansionTile(
                leading: const Icon(Icons.timeline, size: 20),
                title: const Text('大运时间线', style: TextStyle(fontWeight: FontWeight.bold)),
                initiallyExpanded: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: DayunTimeline(
                      dayunResult: dayunResult!,
                      currentYear: DateTime.now().year,
                      onDayunTap: (dayun) {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: DayunDetailCard(
                                dayun: dayun,
                                isCurrentDayun: _getDayunForYear(DateTime.now().year)?.index == dayun.index,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            ExpansionTile(
              leading: const Icon(Icons.pie_chart, size: 20),
              title: const Text('五行能量分析', style: TextStyle(fontWeight: FontWeight.bold)),
              initiallyExpanded: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: WuxingEnergyChart(analysis: analysis),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              leading: const Icon(Icons.layers, size: 20),
              title: const Text('地支藏干', style: TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildCangganContent(analysis),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              leading: const Icon(Icons.star, size: 20),
              title: const Text('十神分析', style: TextStyle(fontWeight: FontWeight.bold)),
              initiallyExpanded: false,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ShishenAnalysisCard(analysis: analysis),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              leading: const Icon(Icons.calendar_today, size: 20),
              title: const Text('流年轮播', style: TextStyle(fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 8),
            ExpansionTile(
              leading: const Icon(Icons.grid_on, size: 20),
              title: const Text('流年网格（12年）', style: TextStyle(fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 四柱总览
  // ─────────────────────────────────────────────────────────────

  Widget _buildBaziOverview() {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('四柱八字',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildGanzhiRow('年柱', bazi.yearGanZhi, Colors.indigo),
            _buildGanzhiRow('月柱', bazi.monthGanZhi, Colors.teal),
            _buildGanzhiRow('日柱', bazi.dayGanZhi, Colors.deepOrange),
            _buildGanzhiRow('时柱', bazi.hourGanZhi, Colors.purple),
            const SizedBox(height: 8),
            Text(
              '日主${bazi.dayGan}，${wx.GAN_WUXING_WUXING[bazi.dayGan]}行',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGanzhiRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 14))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 五行
  // ─────────────────────────────────────────────────────────────

  Widget _buildWuxingContent(wx.BaziAnalysis analysis) {
    final score = analysis.wuxingScore;
    final total = score.total == 0 ? 1 : score.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStrengthBadge(analysis.strength.level),
            const Spacer(),
            Text(
              '日主旺度：${analysis.strength.score}分 (${analysis.strength.level.nameCn})',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildWuxingBar('木', score.mu, total, Colors.green),
        _buildWuxingBar('火', score.huo, total, Colors.red),
        _buildWuxingBar('土', score.tu, total, Colors.brown),
        _buildWuxingBar('金', score.jin, total, Colors.blueGrey),
        _buildWuxingBar('水', score.shui, total, Colors.cyan),
        if (analysis.strength.yueLingBonus != null) ...[
          const SizedBox(height: 8),
          Text(analysis.strength.yueLingBonus!,
              style: TextStyle(color: Colors.amber.shade800, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildWuxingBar(String label, int value, int total, Color color) {
    final pct = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 24, child: Text(label, style: const TextStyle(fontSize: 14))),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text('$value',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthBadge(wx.StrengthLevel level) {
    Color color;
    switch (level) {
      case wx.StrengthLevel.pianQiang:
      case wx.StrengthLevel.qiang:
        color = Colors.red;
      case wx.StrengthLevel.zhongHe:
        color = Colors.amber;
      case wx.StrengthLevel.ruo:
      case wx.StrengthLevel.pianRuo:
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(level.nameCn,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
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
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 14))),
          Expanded(
            child: Text(detail,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 十神
  // ─────────────────────────────────────────────────────────────

  Widget _buildShishenContent(wx.BaziAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildShishenRow('年柱（祖辈）', analysis.shishenMap['年柱'] ?? ''),
        _buildShishenRow('月柱（父母/手足）', analysis.shishenMap['月柱'] ?? ''),
        _buildShishenRow('日主', '本身'),
        _buildShishenRow('时柱（子嗣/晚年）', analysis.shishenMap['时柱'] ?? ''),
      ],
    );
  }

  Widget _buildShishenRow(String label, String value) {
    final color = _getShishenColor(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(value,
                style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Color _getShishenColor(String ss) {
    switch (ss) {
      case '比肩':
      case '劫财':
        return Colors.grey;
      case '食神':
      case '伤官':
        return Colors.purple;
      case '偏财':
      case '正财':
        return Colors.orange;
      case '七杀':
      case '正官':
        return Colors.blue;
      case '偏印':
      case '正印':
        return Colors.green;
      default:
        return Colors.black87;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 流年（支持年份切换）
  // ─────────────────────────────────────────────────────────────

  Widget _buildLiunianContent() {
    final liunianDetail = getLiunianDetail(
      _selectedYear,
      bazi,
      dayun: _getDayunForYear(_selectedYear),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 年份切换行
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _selectedYear--),
              tooltip: '上一年',
            ),
            GestureDetector(
              onTap: () async {
                final picked = await showDialog<int>(
                  context: context,
                  builder: (ctx) => _YearPickerDialog(initialYear: _selectedYear),
                );
                if (picked != null) setState(() => _selectedYear = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Text(
                      '$_selectedYear年 ${liunianDetail.liunian.ganZhi}',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit, size: 14, color: Colors.amber.shade700),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => _selectedYear++),
              tooltip: '下一年',
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 流年摘要
        Text(liunianDetail.summary,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
        if (liunianDetail.liunian.chongHeRelations.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            children: liunianDetail.liunian.chongHeRelations.map((r) {
              return Chip(
                label: Text(r, style: const TextStyle(fontSize: 11)),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.red.shade50,
              );
            }).toList(),
          ),
        ],
        const Divider(height: 20),
        // 所处大运
        if (_getDayunForYear(_selectedYear) != null) ...[
          Row(
            children: [
              Text('所处大运：',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getDayunForYear(_selectedYear)!.ganZhi,
                  style: TextStyle(
                      color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '（${_getDayunForYear(_selectedYear)!.startAge}'
                '～${_getDayunForYear(_selectedYear)!.endAge}岁）',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        // 流月
        const Text('流月', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: liunianDetail.months
              .map((m) => _LiunianMonthChip(month: m))
              .toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 辅助 Widgets
// ─────────────────────────────────────────────────────────────

/// 大运 Chip（高亮当前大运）
class _DayunChip extends StatelessWidget {
  final Dayun dayun;
  final bool isActive;
  const _DayunChip({required this.dayun, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue.shade100 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.blue.shade500 : Colors.blue.shade200,
          width: isActive ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Text(dayun.ganZhi,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontSize: 14)),
          Text('${dayun.startAge}-${dayun.endAge}岁',
              style: TextStyle(fontSize: 10, color: Colors.blue.shade600)),
          Text('${dayun.startYear}年起',
              style: TextStyle(fontSize: 9, color: Colors.blue.shade400)),
        ],
      ),
    );
  }
}

/// 流月 Chip
class _LiunianMonthChip extends StatelessWidget {
  final LiunianMonth month;
  const _LiunianMonthChip({required this.month});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text('${month.month}月',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(month.ganZhi,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}

/// 年份选择对话框
class _YearPickerDialog extends StatefulWidget {
  final int initialYear;
  const _YearPickerDialog({required this.initialYear});

  @override
  State<_YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialYear}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择年份'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: '年份',
          hintText: '如：2025',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final year = int.tryParse(_controller.text.trim());
            if (year != null && year >= 1900 && year <= 2100) {
              Navigator.pop(context, year);
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
