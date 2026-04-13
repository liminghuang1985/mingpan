/// 流年流月计算
library;

import 'package:mingpan_app/models/bazi.dart';
import 'package:mingpan_app/core/dayun.dart';

/// 流年数据
class Liunian {
  final int year;
  final String ganZhi;
  final int zhiIndex;
  final List<String> chongHeRelations;
  final String jixiong;

  const Liunian({
    required this.year,
    required this.ganZhi,
    required this.zhiIndex,
    this.chongHeRelations = const [],
    this.jixiong = '平',
  });

  String get gan => ganZhi.isNotEmpty ? ganZhi[0] : '';
  String get zhi => ganZhi.length > 1 ? ganZhi[1] : '';
}

/// 流月数据
class LiunianMonth {
  final int month;
  final String ganZhi;
  final String liunianGanZhi;

  const LiunianMonth({
    required this.month,
    required this.ganZhi,
    required this.liunianGanZhi,
  });

  String get gan => ganZhi.isNotEmpty ? ganZhi[0] : '';
  String get zhi => ganZhi.length > 1 ? ganZhi[1] : '';
}

const LIUNIAN_WUXINGJIAZI = [
  '甲子', '乙丑', '丙寅', '丁卯', '戊辰', '己巳', '庚午', '辛未', '壬申', '癸酉',
  '甲戌', '乙亥', '丙子', '丁丑', '戊寅', '己卯', '庚辰', '辛巳', '壬午', '癸未',
  '甲申', '乙酉', '丙戌', '丁亥', '戊子', '己丑', '庚寅', '辛卯', '壬辰', '癸巳',
  '甲午', '乙未', '丙申', '丁酉', '戊戌', '己亥', '庚子', '辛丑', '壬寅', '癸卯',
  '甲辰', '乙巳', '丙午', '丁未', '戊申', '己酉', '庚戌', '辛亥', '壬子', '癸丑',
  '甲寅', '乙卯', '丙辰', '丁巳', '戊午', '己未', '庚申', '辛酉', '壬戌', '癸亥',
];

const _dizhiOrder = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

const _liuchong = {
  '子': '午', '午': '子',
  '丑': '未', '未': '丑',
  '寅': '申', '申': '寅',
  '卯': '酉', '酉': '卯',
  '辰': '戌', '戌': '辰',
  '巳': '亥', '亥': '巳',
};

String getLiunianGanZhi(int year) {
  // 基准：2020年 = 庚子 = LIUNIAN_WUXINGJIAZI[36]（甲子=0, 庚子=36）
  const baseYear = 2020;
  const baseIndex = 36; // 庚子在 LIUNIAN_WUXINGJIAZI 中的正确索引
  final offset = year - baseYear;
  final index = ((baseIndex + offset) % 60 + 60) % 60;
  return LIUNIAN_WUXINGJIAZI[index];
}

String _getLiunianMonthGanZhi(String yearGan, int month) {
  const wuhutun = {
    '甲': '丙', '己': '丙',
    '乙': '戊', '庚': '戊',
    '丙': '庚', '辛': '庚',
    '丁': '壬', '壬': '壬',
    '戊': '甲', '癸': '甲',
  };

  final startGan = wuhutun[yearGan] ?? '丙';
  const tiangan = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
  final startIndex = tiangan.indexOf(startGan);
  final ganIndex = (startIndex + month - 1) % 10;
  final gan = tiangan[ganIndex];
  final zhi = _dizhiOrder[(month + 1) % 12];

  return '$gan$zhi';
}

List<Liunian> getLiunianList(int startYear, int count, {Bazi? bazi}) {
  final liunians = <Liunian>[];

  for (int i = 0; i < count; i++) {
    final year = startYear + i;
    final gz = getLiunianGanZhi(year);
    final zhi = gz[1];
    final relations = <String>[];

    if (bazi != null) {
      for (final z in [bazi.yearZhi, bazi.monthZhi, bazi.dayZhi, bazi.hourZhi]) {
        if (_liuchong[z] == zhi) {
          relations.add('冲$z');
        }
      }
      final he = _checkSanHe(zhi, bazi);
      if (he != null) relations.add('三合${he}局');
    }

    String jixiong = '平';
    if (relations.isNotEmpty) {
      jixiong = relations.any((r) => r.contains('冲')) ? '犯冲' : '合局';
    }

    liunians.add(Liunian(
      year: year,
      ganZhi: gz,
      zhiIndex: _dizhiOrder.indexOf(zhi),
      chongHeRelations: relations,
      jixiong: jixiong,
    ));
  }

  return liunians;
}

String? _checkSanHe(String liunianZhi, Bazi bazi) {
  final allZhi = [bazi.yearZhi, bazi.monthZhi, bazi.dayZhi, bazi.hourZhi, liunianZhi];

  if (allZhi.contains('申') && allZhi.contains('子') && allZhi.contains('辰')) return '水';
  if (allZhi.contains('亥') && allZhi.contains('卯') && allZhi.contains('未')) return '木';
  if (allZhi.contains('寅') && allZhi.contains('午') && allZhi.contains('戌')) return '火';
  if (allZhi.contains('巳') && allZhi.contains('酉') && allZhi.contains('丑')) return '金';

  return null;
}

class LiunianDetail {
  final Liunian liunian;
  final List<LiunianMonth> months;
  final String summary;

  const LiunianDetail({
    required this.liunian,
    required this.months,
    this.summary = '',
  });
}

LiunianDetail getLiunianDetail(int liunianYear, Bazi bazi, {Dayun? dayun}) {
  final liunianGz = getLiunianGanZhi(liunianYear);
  final zhi = liunianGz[1];
  final relations = <String>[];

  for (final z in [bazi.yearZhi, bazi.monthZhi, bazi.dayZhi, bazi.hourZhi]) {
    if (_liuchong[z] == zhi) {
      relations.add('冲$z');
    }
  }
  final he = _checkSanHe(zhi, bazi);
  if (he != null) relations.add('三合${he}局');

  final months = <LiunianMonth>[];
  // 流月天干应以「流年天干」为起算点，而非命主年柱天干
  final liunianGan = liunianGz.isNotEmpty ? liunianGz[0] : bazi.yearGan;
  for (int m = 1; m <= 12; m++) {
    months.add(LiunianMonth(
      month: m,
      ganZhi: _getLiunianMonthGanZhi(liunianGan, m),
      liunianGanZhi: liunianGz,
    ));
  }

  final summary = _getLiunianSummary(liunianYear, bazi, relations);

  return LiunianDetail(
    liunian: Liunian(
      year: liunianYear,
      ganZhi: liunianGz,
      zhiIndex: _dizhiOrder.indexOf(zhi),
      chongHeRelations: relations,
    ),
    months: months,
    summary: summary,
  );
}

String _getLiunianSummary(int year, Bazi bazi, List<String> relations) {
  final gz = getLiunianGanZhi(year);
  String summary = '$year年$gz，';
  if (relations.isNotEmpty) {
    summary += relations.join('、');
  } else {
    summary += '五行平和';
  }
  return summary;
}

bool isChong(String zhi1, String zhi2) {
  return _liuchong[zhi1] == zhi2 || _liuchong[zhi2] == zhi1;
}
