/// 五行分析
library;

import '../models/bazi.dart';

/// 天干对应的五行
const GAN_WUXING_WUXING = {
  '甲': '木', '乙': '木',
  '丙': '火', '丁': '火',
  '戊': '土', '己': '土',
  '庚': '金', '辛': '金',
  '壬': '水', '癸': '水',
};

/// 地支藏干
const ZHI_CANGGAN = {
  '子': ['癸'],
  '丑': ['己', '癸', '辛'],
  '寅': ['甲', '丙', '戊'],
  '卯': ['乙'],
  '辰': ['戊', '乙', '癸'],
  '巳': ['丙', '庚', '戊'],
  '午': ['丁', '己'],
  '未': ['己', '丁', '乙'],
  '申': ['庚', '壬', '戊'],
  '酉': ['辛'],
  '戌': ['戊', '辛', '丁', '乙'],
  '亥': ['壬', '甲'],
};

String getZhiBenqi(String zhi) {
  final cg = ZHI_CANGGAN[zhi];
  return cg != null && cg.isNotEmpty ? cg[0] : '';
}

String? getZhiZhongqi(String zhi) {
  final cg = ZHI_CANGGAN[zhi];
  return cg != null && cg.length > 1 ? cg[1] : null;
}

String? getZhiYuqi(String zhi) {
  final cg = ZHI_CANGGAN[zhi];
  return cg != null && cg.length > 2 ? cg[2] : null;
}

String getZhiCangganDisplay(String zhi) {
  final cg = ZHI_CANGGAN[zhi];
  if (cg == null || cg.isEmpty) return '';
  final parts = <String>[];
  for (int i = 0; i < cg.length; i++) {
    final label = i == 0 ? '本' : (i == 1 ? '中' : '余');
    parts.add('${cg[i]}($label)');
  }
  return parts.join(' ');
}

/// 十神类型
enum ShishenType {
  bijian, jiecai, shishen, shangguan,
  piancai, zhengcai, qisha, zhengguan,
  pianyin, zhengyin,
}

extension ShishenTypeExt on ShishenType {
  String get nameCn {
    switch (this) {
      case ShishenType.bijian: return '比肩';
      case ShishenType.jiecai: return '劫财';
      case ShishenType.shishen: return '食神';
      case ShishenType.shangguan: return '伤官';
      case ShishenType.piancai: return '偏财';
      case ShishenType.zhengcai: return '正财';
      case ShishenType.qisha: return '七杀';
      case ShishenType.zhengguan: return '正官';
      case ShishenType.pianyin: return '偏印';
      case ShishenType.zhengyin: return '正印';
    }
  }
}

const _tiangan = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];

bool _sheng(String w1, String w2) {
  return w1 == '木' && w2 == '火' ||
      w1 == '火' && w2 == '土' ||
      w1 == '土' && w2 == '金' ||
      w1 == '金' && w2 == '水' ||
      w1 == '水' && w2 == '木';
}

bool _ke(String w1, String w2) {
  return w1 == '木' && w2 == '土' ||
      w1 == '土' && w2 == '水' ||
      w1 == '水' && w2 == '火' ||
      w1 == '火' && w2 == '金' ||
      w1 == '金' && w2 == '木';
}

ShishenType? getShishen(String gan, String comparedGan, {String gender = '男'}) {
  final g1 = gan.length > 1 ? gan[0] : gan;
  final g2 = comparedGan.length > 1 ? comparedGan[0] : comparedGan;

  if (g1 == g2) {
    return gender == '男' ? ShishenType.bijian : ShishenType.jiecai;
  }

  final w1 = GAN_WUXING_WUXING[g1] ?? '';
  final w2 = GAN_WUXING_WUXING[g2] ?? '';

  final i1 = _tiangan.indexOf(g1);
  final i2 = _tiangan.indexOf(g2);
  final sameGender = (i1 % 2) == (i2 % 2);

  if (_sheng(w1, w2)) {
    return sameGender ? ShishenType.shishen : ShishenType.shangguan;
  }
  if (_ke(w1, w2)) {
    return sameGender ? ShishenType.piancai : ShishenType.zhengcai;
  }
  if (_sheng(w2, w1)) {
    return sameGender ? ShishenType.pianyin : ShishenType.zhengyin;
  }
  if (_ke(w2, w1)) {
    return sameGender ? ShishenType.qisha : ShishenType.zhengguan;
  }
  return null;
}

String getShishenName(String dayGan, String otherGan, {String gender = '男'}) {
  final ss = getShishen(dayGan, otherGan, gender: gender);
  return ss != null ? ss.nameCn : '';
}

/// 五行分数
class WuxingScore {
  final int mu;
  final int huo;
  final int tu;
  final int jin;
  final int shui;

  const WuxingScore({this.mu = 0, this.huo = 0, this.tu = 0, this.jin = 0, this.shui = 0});

  int get total => mu + huo + tu + jin + shui;

  Map<String, int> toMap() => {'木': mu, '火': huo, '土': tu, '金': jin, '水': shui};

  @override
  String toString() => '木:$mu 火:$huo 土:$tu 金:$jin 水:$shui';
}

WuxingScore calcWuxingScore(Bazi bazi) {
  int mu = 0, huo = 0, tu = 0, jin = 0, shui = 0;

  void add(String gan, int score) {
    final wx = GAN_WUXING_WUXING[gan] ?? '';
    switch (wx) {
      case '木': mu += score;
      case '火': huo += score;
      case '土': tu += score;
      case '金': jin += score;
      case '水': shui += score;
    }
  }

  for (final g in [bazi.yearGan, bazi.monthGan, bazi.dayGan, bazi.hourGan]) {
    add(g, 2);
  }

  void addCanggan(String zhi) {
    final cg = ZHI_CANGGAN[zhi];
    if (cg == null) return;
    if (cg.isNotEmpty) add(cg[0], 3);
    if (cg.length > 1) add(cg[1], 2);
    if (cg.length > 2) add(cg[2], 1);
  }

  for (final z in [bazi.yearZhi, bazi.monthZhi, bazi.dayZhi, bazi.hourZhi]) {
    addCanggan(z);
  }

  return WuxingScore(mu: mu, huo: huo, tu: tu, jin: jin, shui: shui);
}

enum StrengthLevel { pianRuo, ruo, zhongHe, qiang, pianQiang }

extension StrengthLevelExt on StrengthLevel {
  String get nameCn {
    switch (this) {
      case StrengthLevel.pianRuo: return '偏弱';
      case StrengthLevel.ruo: return '弱';
      case StrengthLevel.zhongHe: return '中和';
      case StrengthLevel.qiang: return '强';
      case StrengthLevel.pianQiang: return '偏强';
    }
  }
}

class DayMasterStrength {
  final int score;
  final StrengthLevel level;
  final String summary;
  final String? yueLingBonus;

  const DayMasterStrength({
    required this.score,
    required this.level,
    required this.summary,
    this.yueLingBonus,
  });
}

DayMasterStrength calcDayMasterStrength(Bazi bazi) {
  final raw = _calcRawScore(bazi);
  final yueLingWX = getYuelingWuxing(bazi.monthZhi);

  int adjusted = raw;
  String? yueLingBonus;
  final dayWX = GAN_WUXING_WUXING[bazi.dayGan] ?? '';

  if (yueLingWX == dayWX) {
    adjusted += 4;
    yueLingBonus = '月令$yueLingWX当令，+4分';
  } else if (_sheng(dayWX, yueLingWX)) {
    adjusted -= 2;
    yueLingBonus = '月令$yueLingWX泄气，-2分';
  } else if (_ke(dayWX, yueLingWX)) {
    adjusted -= 1;
    yueLingBonus = '月令$yueLingWX耗力，-1分';
  } else if (_sheng(yueLingWX, dayWX)) {
    adjusted += 2;
    yueLingBonus = '月令$yueLingWX得令，+2分';
  }

  StrengthLevel level;
  String summary;

  if (adjusted >= 12) {
    level = StrengthLevel.pianQiang;
    summary = '日主${bazi.dayGan}偏强';
  } else if (adjusted >= 8) {
    level = StrengthLevel.qiang;
    summary = '日主${bazi.dayGan}强';
  } else if (adjusted >= 4) {
    level = StrengthLevel.zhongHe;
    summary = '日主${bazi.dayGan}中和';
  } else if (adjusted >= -2) {
    level = StrengthLevel.ruo;
    summary = '日主${bazi.dayGan}偏弱';
  } else {
    level = StrengthLevel.pianRuo;
    summary = '日主${bazi.dayGan}过弱';
  }

  return DayMasterStrength(
    score: adjusted,
    level: level,
    summary: summary,
    yueLingBonus: yueLingBonus,
  );
}

int _calcRawScore(Bazi bazi) {
  int total = 0;
  final dayWX = GAN_WUXING_WUXING[bazi.dayGan] ?? '';

  for (final g in [bazi.yearGan, bazi.monthGan, bazi.dayGan, bazi.hourGan]) {
    if (GAN_WUXING_WUXING[g] == dayWX) total += 2;
  }

  for (final z in [bazi.yearZhi, bazi.monthZhi, bazi.dayZhi, bazi.hourZhi]) {
    final cg = ZHI_CANGGAN[z];
    if (cg == null) continue;
    for (final c in cg) {
      if (GAN_WUXING_WUXING[c] == dayWX) total += 1;
    }
  }

  return total;
}

String getYuelingWuxing(String zhi) {
  const m = {
    '寅': '木', '卯': '木',
    '巳': '火', '午': '火',
    '申': '金', '酉': '金',
    '亥': '水', '子': '水',
    '辰': '土', '丑': '土', '戌': '土', '未': '土',
  };
  return m[zhi] ?? '土';
}

class BaziAnalysis {
  final WuxingScore wuxingScore;
  final DayMasterStrength strength;
  final Map<String, String> cangganDetails;
  final Map<String, String> shishenMap;
  final List<String> advantages;
  final List<String> disadvantages;

  const BaziAnalysis({
    required this.wuxingScore,
    required this.strength,
    required this.cangganDetails,
    required this.shishenMap,
    this.advantages = const [],
    this.disadvantages = const [],
  });
}

BaziAnalysis analyzeBazi(Bazi bazi, {String gender = '男'}) {
  final score = calcWuxingScore(bazi);
  final strength = calcDayMasterStrength(bazi);

  final cangganDetails = <String, String>{};
  for (final z in [bazi.yearZhi, bazi.monthZhi, bazi.dayZhi, bazi.hourZhi]) {
    cangganDetails[z] = getZhiCangganDisplay(z);
  }

  final shishenMap = <String, String>{};
  shishenMap['年柱'] = getShishenName(bazi.dayGan, bazi.yearGan, gender: gender);
  shishenMap['月柱'] = getShishenName(bazi.dayGan, bazi.monthGan, gender: gender);
  shishenMap['日柱'] = '日主';
  shishenMap['时柱'] = getShishenName(bazi.dayGan, bazi.hourGan, gender: gender);

  final advantages = <String>[];
  final disadvantages = <String>[];

  if (strength.level == StrengthLevel.qiang || strength.level == StrengthLevel.pianQiang) {
    advantages.add('日主旺，得令或得势');
  }
  if (strength.level == StrengthLevel.ruo || strength.level == StrengthLevel.pianRuo) {
    disadvantages.add('日主弱，失令或失势');
  }

  final m = score.toMap();
  for (final e in m.entries) {
    if (e.value == 0) {
      disadvantages.add('五行缺${e.key}');
    }
  }

  return BaziAnalysis(
    wuxingScore: score,
    strength: strength,
    cangganDetails: cangganDetails,
    shishenMap: shishenMap,
    advantages: advantages,
    disadvantages: disadvantages,
  );
}
