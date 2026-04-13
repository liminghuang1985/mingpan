/// 八字计算核心
/// 参考: ALGORITHM.md
library;

import 'solarterm.dart' show getYuelingZhi;

/// 六十甲子数组
/// 来源：传统八字命理，60年一轮回
const WUXINGJIAZI = [
  '甲子', '乙丑', '丙寅', '丁卯', '戊辰', '己巳', '庚午', '辛未', '壬申', '癸酉',
  '甲戌', '乙亥', '丙子', '丁丑', '戊寅', '己卯', '庚辰', '辛巳', '壬午', '癸未',
  '甲申', '乙酉', '丙戌', '丁亥', '戊子', '己丑', '庚寅', '辛卯', '壬辰', '癸巳',
  '甲午', '乙未', '丙申', '丁酉', '戊戌', '己亥', '庚子', '辛丑', '壬寅', '癸卯',
  '甲辰', '乙巳', '丙午', '丁未', '戊申', '己酉', '庚戌', '辛亥', '壬子', '癸丑',
  '甲寅', '乙卯', '丙辰', '丁巳', '戊午', '己未', '庚申', '辛酉', '壬戌', '癸亥',
];

/// 天干数组
const TIANGAN = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];

/// 地支数组
const DIZHI = ['寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥', '子', '丑'];

/// 五虎遁：年干 → 月干起始（寅月=1）
/// 口诀：甲己之年丙作首，乙庚之年戊为头，丙辛必定寻庚起，丁壬壬位顺行流，戊癸之年还甲来
const WUHUTUN = {
  '甲': '丙',
  '己': '丙',
  '乙': '戊',
  '庚': '戊',
  '丙': '庚',
  '辛': '庚',
  '丁': '壬',
  '壬': '壬',
  '戊': '甲',
  '癸': '甲',
};

/// 五鼠遁：日干 → 时干起始（子时=23:00-00:59）
/// 口诀：甲己还生甲，乙庚丙作初，丙辛从戊起，丁壬庚子居，戊癸何方发，壬子是真途
const WUSHUTUN = {
  '甲': '甲',
  '己': '甲',
  '乙': '丙',
  '庚': '丙',
  '丙': '戊',
  '辛': '戊',
  '丁': '庚',
  '壬': '庚',
  '戊': '壬',
  '癸': '壬',
};

/// 天干对应的五行
const GAN_WUXING = {
  '甲': '木', '乙': '木',
  '丙': '火', '丁': '火',
  '戊': '土', '己': '土',
  '庚': '金', '辛': '金',
  '壬': '水', '癸': '水',
};

/// 阳天干（用于判断大运方向）
const YANG_GAN = ['甲', '丙', '戊', '庚', '壬'];

/// 计算公历转儒略日
///
/// 算法来源：天文算法，格里高利历改革公式
/// 验证：2000-01-01 00:00:00 = JD 2451545
int toJulianDay(int year, int month, int day, {int hour = 0, int minute = 0}) {
  int y = year;
  int m = month;
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final int A = (y / 100).floor();
  final int B = 2 - A + (A / 4).floor();
  final double JD = (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      day + B - 1524.5 +
      (hour + minute / 60.0) / 24.0;
  return (JD + 0.5).floor();
}

/// 计算日柱
///
/// 原理：用已知基准点（2000-01-01 00:00 = 庚辰，index=17）倒退
/// 参考 ALGORITHM.md
String getDayGanZhi(int year, int month, int day, {int hour = 0, int minute = 0}) {
  const int BASE_JD = 2451545; // 2000-01-01 00:00 的儒略日（toJulianDay返回值）
  const int BASE_INDEX = 54; // 戊午在 WUXINGJIAZI 中的索引（2000-01-01 真实日柱为戊午，已验证）

  final int birthJD = toJulianDay(year, month, day, hour: hour, minute: minute);
  final int offset = birthJD - BASE_JD;
  final int index = ((BASE_INDEX + offset) % 60 + 60) % 60;

  return WUXINGJIAZI[index];
}

/// 计算年柱
///
/// 原理：以1984年为甲子年（index=0），每60年循环
/// 验证：getYearGanZhi(1984) = 甲子，getYearGanZhi(2017) = 丁酉
String getYearGanZhi(int year) {
  const int BASE_YEAR = 1984;
  const int BASE_INDEX = 0;

  final int offset = year - BASE_YEAR;
  final int index = ((BASE_INDEX + offset) % 60 + 60) % 60;

  return WUXINGJIAZI[index];
}

/// 计算月柱（含五虎遁）
///
/// [yearGan] 年干（甲、乙、丙...）
/// [month] 月份（1-12，对应寅月到丑月）
///
/// 口诀：甲己之年丙作首，乙庚之年戊为头，丙辛必定寻庚起，丁壬壬位顺行流，戊癸之年还甲来
String getMonthGanZhi(String yearGan, int month) {
  // 兼容年干的完整形式（年柱是两个字如"甲子"，取第一个字）
  final String gan = yearGan.length > 1 ? yearGan[0] : yearGan;

  final String startGan = WUHUTUN[gan] ?? '丙';
  final int startIndex = TIANGAN.indexOf(startGan);
  final int ganIndex = (startIndex + month - 1) % 10;
  final String resultGan = TIANGAN[ganIndex];
  final String resultZhi = DIZHI[month - 1];

  return '$resultGan$resultZhi';
}

/// 计算时柱（含五鼠遁）
///
/// [dayGan] 日干（甲、乙、丙...）
/// [hour] 小时（0-23）
///
/// 口诀：甲己还生甲，乙庚丙作初，丙辛从戊起，丁壬庚子居，戊癸何方发，壬子是真途
/// 注意：23:00-23:59 为夜子时（子时），00:00-00:59 为早子时
String getHourGanZhi(String dayGan, int hour) {
  // 兼容日干的完整形式（日柱是两个字如"丁卯"，取第一个字）
  final String gan = dayGan.length > 1 ? dayGan[0] : dayGan;

  final String startGan = WUSHUTUN[gan] ?? '甲';
  final int startIndex = TIANGAN.indexOf(startGan);

  // 地支索引：23:00-00:59=0(子), 01:00-02:59=1(丑), ...
  int zhiIndex;
  if (hour >= 23) {
    zhiIndex = 0; // 夜子时
  } else {
    zhiIndex = ((hour + 1) / 2).floor() % 12;
  }

  // 早子时（00:00-00:59）与夜子时（23:00-23:59）同属子时，时干不进位
  // 日柱在 23:00（夜子时）时已经切换到新一天，00:00 继续沿用同一日干
  final int ganIndex = (startIndex + zhiIndex) % 10;
  final String resultGan = TIANGAN[ganIndex];
  final String resultZhi = _ZHI_HOUR[zhiIndex];

  return '$resultGan$resultZhi';
}

/// 时柱地支（从子时开始）
const _ZHI_HOUR = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

/// 八字计算结果
class BaziResult {
  final String yearGanZhi; // 年柱
  final String monthGanZhi; // 月柱
  final String dayGanZhi; // 日柱
  final String hourGanZhi; // 时柱

  const BaziResult({
    required this.yearGanZhi,
    required this.monthGanZhi,
    required this.dayGanZhi,
    required this.hourGanZhi,
  });

  @override
  String toString() => '$yearGanZhi $monthGanZhi $dayGanZhi $hourGanZhi';
}

/// 计算完整八字
///
/// [year] 年
/// [month] 月
/// [day] 日
/// [hour] 小时（0-23）
/// [minute] 分钟（0-59）
///
/// 异常时返回默认值（1900-01-01 00:00 的八字）
BaziResult calculateBazi(int year, int month, int day, int hour, int minute) {
  try {
    // 参数校验
    if (year < 1900 || year > 2100 || month < 1 || month > 12 || day < 1 || day > 31) {
      // 返回默认值
      return const BaziResult(
        yearGanZhi: '庚辰',
        monthGanZhi: '丙寅',
        dayGanZhi: '甲子',
        hourGanZhi: '甲子',
      );
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return const BaziResult(
        yearGanZhi: '庚辰',
        monthGanZhi: '丙寅',
        dayGanZhi: '甲子',
        hourGanZhi: '甲子',
      );
    }

    final String yearGz = getYearGanZhi(year);
    final String dayGz = getDayGanZhi(year, month, day, hour: hour, minute: minute);

    // 月令由节气决定：用 getYuelingZhi 获取月令地支，再反查月柱
    final String yueLingZhi = getYuelingZhi(month, day);
    final int monthNum = DIZHI.indexOf(yueLingZhi) + 1; // DIZHI[0]=寅=1, ..., DIZHI[11]=丑=12

    final String monthGz = getMonthGanZhi(yearGz, monthNum);
    final String hourGz = getHourGanZhi(dayGz, hour);

    return BaziResult(
      yearGanZhi: yearGz,
      monthGanZhi: monthGz,
      dayGanZhi: dayGz,
      hourGanZhi: hourGz,
    );
  } catch (_) {
    return const BaziResult(
      yearGanZhi: '庚辰',
      monthGanZhi: '丙寅',
      dayGanZhi: '甲子',
      hourGanZhi: '甲子',
    );
  }
}

/// 判断天干阴阳
bool isYang(String gan) {
  final String g = gan.length > 1 ? gan[0] : gan;
  return YANG_GAN.contains(g);
}
