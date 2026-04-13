// Test calculation for 黄子玄 case: 2017年12月8日0点5分
// This mimics the actual bazi.dart implementation
//
// 已验证基准：
//   2000-01-01 = 戊午日 (WUXINGJIAZI[54])，BASE_INDEX = 54
//   2017-12-08 = 己巳日 (WUXINGJIAZI[5])
//   2000-01-01 年柱 = 庚辰（年柱逻辑与日柱无关，单独验证）

const WUXINGJIAZI = [
  '甲子', '乙丑', '丙寅', '丁卯', '戊辰', '己巳', '庚午', '辛未', '壬申', '癸酉',
  '甲戌', '乙亥', '丙子', '丁丑', '戊寅', '己卯', '庚辰', '辛巳', '壬午', '癸未',
  '甲申', '乙酉', '丙戌', '丁亥', '戊子', '己丑', '庚寅', '辛卯', '壬辰', '癸巳',
  '甲午', '乙未', '丙申', '丁酉', '戊戌', '己亥', '庚子', '辛丑', '壬寅', '癸卯',
  '甲辰', '乙巳', '丙午', '丁未', '戊申', '己酉', '庚戌', '辛亥', '壬子', '癸丑',
  '甲寅', '乙卯', '丙辰', '丁巳', '戊午', '己未', '庚申', '辛酉', '壬戌', '癸亥',
];

const TIANGAN = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
const DIZHI = ['寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥', '子', '丑'];
const WUHUTUN = {
  '甲': '丙', '己': '丙',
  '乙': '戊', '庚': '戊',
  '丙': '庚', '辛': '庚',
  '丁': '壬', '壬': '壬',
  '戊': '甲', '癸': '甲',
};
const WUSHUTUN = {
  '甲': '甲', '己': '甲',
  '乙': '丙', '庚': '丙',
  '丙': '戊', '辛': '戊',
  '丁': '庚', '壬': '庚',
  '戊': '壬', '癸': '壬',
};
const _ZHI_HOUR = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

int toJulianDay(int year, int month, int day, {int hour = 0, int minute = 0}) {
  int y = year, m = month;
  if (m <= 2) { y -= 1; m += 12; }
  final int A = (y / 100).floor();
  final int B = 2 - A + (A / 4).floor();
  final double JD = (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      day + B - 1524.5 +
      (hour + minute / 60.0) / 24.0;
  return (JD + 0.5).floor();
}

String getDayGanZhi(int year, int month, int day, {int hour = 0, int minute = 0}) {
  const int BASE_JD = 2451545;
  const int BASE_INDEX = 54; // 戊午 = WUXINGJIAZI[54]（2000-01-01 真实日柱，已验证）
  final int birthJD = toJulianDay(year, month, day, hour: hour, minute: minute);
  final int offset = birthJD - BASE_JD;
  final int index = ((BASE_INDEX + offset) % 60 + 60) % 60;
  return WUXINGJIAZI[index];
}

String getYearGanZhi(int year) {
  const int BASE_YEAR = 1984;
  const int BASE_INDEX = 0;
  final int offset = year - BASE_YEAR;
  final int index = ((BASE_INDEX + offset) % 60 + 60) % 60;
  return WUXINGJIAZI[index];
}

String getMonthGanZhi(String yearGan, int month) {
  final String gan = yearGan.length > 1 ? yearGan[0] : yearGan;
  final String startGan = WUHUTUN[gan] ?? '丙';
  final int startIndex = TIANGAN.indexOf(startGan);
  final int ganIndex = (startIndex + month - 1) % 10;
  final String resultGan = TIANGAN[ganIndex];
  final String resultZhi = DIZHI[month - 1];
  return '$resultGan$resultZhi';
}

String getHourGanZhi(String dayGan, int hour) {
  final String gan = dayGan.length > 1 ? dayGan[0] : dayGan;
  final String startGan = WUSHUTUN[gan] ?? '甲';
  final int startIndex = TIANGAN.indexOf(startGan);
  int zhiIndex;
  if (hour >= 23) {
    zhiIndex = 0;
  } else {
    zhiIndex = ((hour + 1) / 2).floor() % 12;
  }
  // 早子时(00:00-00:59)与夜子时(23:00-23:59)同属子时，时干不进位
  final int ganIndex = (startIndex + zhiIndex) % 10;
  final String resultGan = TIANGAN[ganIndex];
  final String resultZhi = _ZHI_HOUR[zhiIndex];
  return '$resultGan$resultZhi';
}

void main() {
  print('=== 命盘计算测试 ===');
  print('');

  // Test 1: 黄子玄 2017年12月8日0点5分
  print('【测试案例1】黄子玄：2017年12月8日 00:05');

  const year = 2017;
  const month = 12;
  const day = 8;
  const hour = 0;
  const minute = 5;

  final yearGz = getYearGanZhi(year);
  final dayGz = getDayGanZhi(year, month, day, hour: hour, minute: minute);

  // 12月8日在大雪(12/7)之后，属子月，子月在 DIZHI 数组 index=10，monthNum=11
  const int monthNum = 11; // 子月
  final monthGz = getMonthGanZhi(yearGz, monthNum);
  final hourGz = getHourGanZhi(dayGz, hour);

  print('计算结果:');
  print('  年柱: $yearGz (期望: 丁酉) ${yearGz == "丁酉" ? "✓" : "✗"}');
  print('  月柱: $monthGz (期望: 壬子) ${monthGz == "壬子" ? "✓" : "✗"}');
  print('  日柱: $dayGz (期望: 己巳) ${dayGz == "己巳" ? "✓" : "✗"}');
  print('  时柱: $hourGz (期望: 甲子) ${hourGz == "甲子" ? "✓" : "✗"}'); // 己日子时=甲子（五鼠遁：甲己还生甲）
  print('');
  final jd = toJulianDay(year, month, day, hour: hour, minute: minute);
  print('  儒略日: $jd (基准2451545, 偏移: ${jd - 2451545})');
  print('');

  // Test 2: 2000-01-01 基准日验证
  print('【测试案例2】2000年1月1日 12:00（基准日验证）');
  final y2 = getYearGanZhi(2000);
  final d2 = getDayGanZhi(2000, 1, 1, hour: 12, minute: 0);
  final jd2 = toJulianDay(2000, 1, 1, hour: 12, minute: 0);
  print('  年柱: $y2 (期望: 庚辰) ${y2 == "庚辰" ? "✓" : "✗"}');
  print('  日柱: $d2 (期望: 戊午) ${d2 == "戊午" ? "✓" : "✗"}');
  print('  儒略日: $jd2 (期望: 2451545) ${jd2 == 2451545 ? "✓" : "✗"}');
  print('');

  // Test 3: 2024-01-01 扩展验证
  print('【测试案例3】2024年1月1日（扩展验证）');
  final y3 = getYearGanZhi(2024);
  final d3 = getDayGanZhi(2024, 1, 1);
  print('  年柱: $y3 (期望: 甲辰) ${y3 == "甲辰" ? "✓" : "✗"}');
  print('  日柱: $d3 (期望: 甲子) ${d3 == "甲子" ? "✓" : "✗"}');
}
