/// 命盘聚合数据模型
library;

import '../core/dayun.dart';
import '../core/liunian.dart' as liunian_core;
import '../core/wuxing.dart' as wx;
import 'bazi.dart';

/// 命盘顶层聚合模型
///
/// 聚合八字、大运、流年、五行分析等所有命盘数据，
/// 作为 UI 层与算法层之间的统一数据载体。
class MingPan {
  /// 八字四柱
  final Bazi bazi;

  /// 大运排盘结果（含起运信息和大运列表）
  final DayunResult? dayunResult;

  /// 五行/十神分析结果
  final wx.BaziAnalysis analysis;

  /// 当前年份起的流年列表（默认14年：前1年到后12年）
  final List<liunian_core.Liunian> liunianList;

  const MingPan({
    required this.bazi,
    required this.analysis,
    this.dayunResult,
    this.liunianList = const [],
  });

  /// 工厂方法：从八字和大运结果构建完整命盘
  factory MingPan.fromBazi(Bazi bazi, {DayunResult? dayunResult}) {
    final analysis = wx.analyzeBazi(bazi, gender: bazi.gender);
    final liunianList = liunian_core.getLiunianList(
      DateTime.now().year - 1,
      14,
      bazi: bazi,
    );
    return MingPan(
      bazi: bazi,
      dayunResult: dayunResult,
      analysis: analysis,
      liunianList: liunianList,
    );
  }

  /// 根据年份找到对应大运
  Dayun? getDayunForYear(int year) {
    if (dayunResult == null) return null;
    for (final d in dayunResult!.dayuns.reversed) {
      if (year >= d.startYear) return d;
    }
    return dayunResult!.dayuns.firstOrNull;
  }

  /// 获取指定年份的流年详情
  liunian_core.LiunianDetail getLiunianDetailForYear(int year) {
    return liunian_core.getLiunianDetail(year, bazi, dayun: getDayunForYear(year));
  }

  @override
  String toString() => 'MingPan(${bazi.toString()})';
}
