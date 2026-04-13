/// 八字数据模型
library;

import '../core/bazi.dart';

/// 八字数据模型
///
/// 包含年柱、月柱、日柱、时柱以及相关辅助信息
class Bazi {
  /// 年柱（如"甲子"）
  final String yearGanZhi;

  /// 月柱（如"丙寅"）
  final String monthGanZhi;

  /// 日柱（如"庚辰"）
  final String dayGanZhi;

  /// 时柱（如"壬子"）
  final String hourGanZhi;

  /// 年干（单字，如"甲"）
  String get yearGan => yearGanZhi.isNotEmpty ? yearGanZhi[0] : '';

  /// 年支（单字，如"子"）
  String get yearZhi => yearGanZhi.length > 1 ? yearGanZhi[1] : '';

  /// 月干（单字）
  String get monthGan => monthGanZhi.isNotEmpty ? monthGanZhi[0] : '';

  /// 月支（单字）
  String get monthZhi => monthGanZhi.length > 1 ? monthGanZhi[1] : '';

  /// 日干（单字）
  String get dayGan => dayGanZhi.isNotEmpty ? dayGanZhi[0] : '';

  /// 日支（单字）
  String get dayZhi => dayGanZhi.length > 1 ? dayGanZhi[1] : '';

  /// 时干（单字）
  String get hourGan => hourGanZhi.isNotEmpty ? hourGanZhi[0] : '';

  /// 时支（单字）
  String get hourZhi => hourGanZhi.length > 1 ? hourGanZhi[1] : '';

  /// 出生日期
  final DateTime birthDate;

  /// 性别（男/女）
  final String gender;

  const Bazi({
    required this.yearGanZhi,
    required this.monthGanZhi,
    required this.dayGanZhi,
    required this.hourGanZhi,
    required this.birthDate,
    required this.gender,
  });

  /// 从计算结果创建
  factory Bazi.fromResult(BaziResult result, DateTime birthDate, String gender) {
    return Bazi(
      yearGanZhi: result.yearGanZhi,
      monthGanZhi: result.monthGanZhi,
      dayGanZhi: result.dayGanZhi,
      hourGanZhi: result.hourGanZhi,
      birthDate: birthDate,
      gender: gender,
    );
  }

  @override
  String toString() => '$yearGanZhi $monthGanZhi $dayGanZhi $hourGanZhi';
}
