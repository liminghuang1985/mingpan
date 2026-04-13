// Quick test of the calculation
const WUXINGJIAZI = [
  '甲子', '乙丑', '丙寅', '丁卯', '戊辰', '己巳', '庚午', '辛未', '壬申', '癸酉',
  '甲戌', '乙亥', '丙子', '丁丑', '戊寅', '己卯', '庚辰', '辛巳', '壬午', '癸未',
  '甲申', '乙酉', '丙戌', '丁亥', '戊子', '己丑', '庚寅', '辛卯', '壬辰', '癸巳',
  '甲午', '乙未', '丙申', '丁酉', '戊戌', '己亥', '庚子', '辛丑', '壬寅', '癸卯',
  '甲辰', '乙巳', '丙午', '丁未', '戊申', '己酉', '庚戌', '辛亥', '壬子', '癸丑',
  '甲寅', '乙卯', '丙辰', '丁巳', '戊午', '己未', '庚申', '辛酉', '壬戌', '癸亥',
];

int toJulianDay(int year, int month, int day, {int hour = 0, int minute = 0}) {
  int y = year;
  int m = month;
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
  const int BASE_INDEX = 17;
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

const TIANGAN = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
const DIZHI = ['寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥', '子', '丑'];

const WUHUTUN = {
  '甲': '丙', '己': '丙',
  '乙': '戊', '庚': '戊',
  '丙': '庚', '辛': '庚',
  '丁': '壬', '壬': '壬',
  '戊': '甲', '癸': '甲',
};

String getMonthGanZhi(String yearGan, int month) {
  final String gan = yearGan.length > 1 ? yearGan[0] : yearGan;
  final String startGan = WUHUTUN[gan] ?? '丙';
  final int startIndex = TIANGAN.indexOf(startGan);
  final int ganIndex = (startIndex + month - 1) % 10;
  final String resultGan = TIANGAN[ganIndex];
  final String resultZhi = DIZHI[month - 1];
  return '$resultGan$resultZhi';
}

const WUSHUTUN = {
  '甲': '甲', '己': '甲',
  '乙': '丙', '庚': '丙',
  '丙': '戊', '辛': '戊',
  '丁': '庚', '壬': '庚',
  '戊': '壬', '癸': '壬',
};

const _ZHI_HOUR = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

String getHourGanZhi(String dayGan, int hour) {
  final String gan = dayGan.length > 1 ? dayGan[0] : dayGan;
  final String startGan = WUSHUTUN[gan] ?? '甲';
  final int startIndex = TIANGAN.indexOf(startGan);
  int zhiIndex;
  if (hour >= 23) {
    zhiIndex = 0; // 夜子时
  } else {
    zhiIndex = ((hour + 1) / 2).floor() % 12;
  }
  final int ganIndex = (startIndex + zhiIndex) % 10;
  final String resultGan = TIANGAN[ganIndex];
  final String resultZhi = _ZHI_HOUR[zhiIndex];
  return '$resultGan$resultZhi';
}

// 黄子玄：2017年12月8日0点5分
void main() {
  final year = 2017;
  final month = 12;
  final day = 8;
  final hour = 0;
  final minute = 5;
  
  final yearGz = getYearGanZhi(year);
  final dayGz = getDayGanZhi(year, month, day, hour: hour, minute: minute);
  
  // 12月8日是大雪(12月7日)之后，属子月=11
  final monthNum = 11; // 子月
  final monthGz = getMonthGanZhi(yearGz, monthNum);
  final hourGz = getHourGanZhi(dayGz, hour);
  
  print('测试：2017年12月8日 00:05');
  print('年柱: $yearGz (期望: 丁酉) ${yearGz == "丁酉" ? "✓" : "✗"}');
  print('月柱: $monthGz (期望: 辛亥) ${monthGz == "辛亥" ? "✓" : "✗"}');
  print('日柱: $dayGz (期望: 丁卯) ${dayGz == "丁卯" ? "✓" : "✗"}');
  print('时柱: $hourGz (期望: 庚子) ${hourGz == "庚子" ? "✓" : "✗"}');
  
  // Test the actual calculateBazi function to understand month handling
  // In the code: if month==1, monthNum=11 (丑月), else use month directly
  // So for 2017-12-08, monthNum = 12, monthGz = getMonthGanZhi("丁酉", 12)
  // 丁年 start=壬, 壬(0)+11=11=壬, zhi=亥... wait that gives 壬亥 not 辛亥
  // Actually: 丁年用壬start, monthNum=12 (亥月), 壬(0)+11=11=壬 -> 壬亥
  // But expected is 辛亥...
  // 
  // Let me recheck: The 五虎遁 for 丁年 says "丁壬之年壬位顺行流"
  // So start=壬 for 丁年
  // monthNum should be 11 (子月), then ganIndex = 0+10=10=癸
  // Actually: 丁年start=壬(index 8), month=11, ganIndex=(8+10)%10=8=壬, zhi=亥 -> 壬亥
  // Hmm, but expected is 辛亥... 
  
  // WAIT - the actual code says: monthNum=month (for month==1 it's 11)
  // For 2017-12-08, month=12, so monthNum=12
  // 丁年 start=壬(index 8), 壬+11=壬 (wait, 8+11=19, 19%10=9=癸!)
  // ganIndex = (8 + 12 - 1) % 10 = 19 % 10 = 9 = 癸
  // zhi = DIZHI[11] = 亥
  // -> 癸亥
  
  // Let me check what the ACTUAL code does (without the month adjustment):
  // The actual code in calculateBazi: monthNum = month (for month==1, monthNum=11)
  // So for Dec: monthNum=12
  // getMonthGanZhi("丁酉", 12): 丁年start=壬
  // ganIndex = TIANGAN.indexOf(壬) + 12 - 1 = 8 + 11 = 19 % 10 = 9 = 癸
  // zhi = DIZHI[11] = 亥
  // Result: 癸亥
  
  // But the EXPECTED is 辛亥! Let me re-examine...
  // 辛亥 = 辛(7) + 亥
  // How do we get 辛 as month gan?
  // 
  // Wait - maybe the 12月 is NOT month 12 in terms of 节气月令
  // December 8 is after 大雪(12/7) but before 小寒(1/5)
  // This is the 子月 (month 11 in 节气 counting, starting from 寅=1)
  // 
  // If monthNum = 11 (子月):
  // ganIndex = (8 + 11 - 1) % 10 = 18 % 10 = 8 = 壬
  // zhi = DIZHI[10] = 子
  // Result: 壬子
  
  // STILL not 辛亥...
  // 
  // Let me recalculate: TIANGAN = [甲(0), 乙(1), 丙(2), 丁(3), 戊(4), 己(5), 庚(6), 辛(7), 壬(8), 癸(9)]
  // 丁 = index 3
  // WUHUTUN[丁] = 壬
  // startIndex = TIANGAN.indexOf(壬) = 8
  // 
  // For 辛亥 (month gan=辛=7, zhi=亥):
  // ganIndex should be 7
  // 7 = (8 + monthNum - 1) % 10
  // monthNum - 1 = -1 ≡ 9 (mod 10)
  // monthNum = 10 ≡ 0 (mod 10)... wait, monthNum should be 10?
  // 
  // Ah! monthNum=10 means 农历十月 (亥月 is month 11, but wait)
  // DIZHI[0]=寅, [1]=卯, [2]=辰, [3]=巳, [4]=午, [5]=未, [6]=申, [7]=酉, [8]=戌, [9]=亥, [10]=子, [11]=丑
  // So 亥月 is index 9... 
  // monthNum=10 gives zhiIndex=9=亥 ✓
  // ganIndex=(8+9)%10=7=辛 ✓ -> 辛亥
  // 
  // But how do we get monthNum=10 for Dec 8?
  // Dec 8 is between 大雪(12/7) and 冬至(12/21)
  // After 大雪 is 子月(month 11 in 节气), but actually:
  // 立冬(11/7) = 亥月 starts
  // But wait: the节气 month令 counting:
  // 立冬起亥月(month 10), 大雪(12/7) still 亥月 or actually 子月?
  // 
  // Traditional lunar calendar:
  // 立冬(11月7日左右) -> 亥月
  // 大雪(12月7日左右) -> Still in 亥月? No:
  // Actually: 亥月 is from 立冬到大雪
  // 子月 is from 大雪到小寒
  // 
  // So Dec 8 (after 大雪 12/7) should be 子月 (month 11)
  // With 子月: ganIndex=(8+10)%10=8=壬, zhi=亥? No wait, DIZHI[month-1]=DIZHI[10]=子
  // Actually for 子月: zhiIndex = 10 (DIZHI[10]=亥? Wait)
  // DIZHI = [寅(0), 卯(1), 辰(2), 巳(3), 午(4), 未(5), 申(6), 酉(7), 戌(8), 亥(9), 子(10), 丑(11)]
  // 子月 = DIZHI index 10 = 子
  // ganIndex = (8 + 10) % 10 = 8 = 壬
  // Result: 壬子
  
  // But expected: 辛亥
  // 辛 = index 7
  // 7 = (8 + monthNum - 1) % 10
  // monthNum - 1 = -1 ≡ 9 (mod 10)
  // monthNum = 10
  // For monthNum=10: DIZHI[9] = 亥 ✓
  // 
  // So monthNum=10 (亥月) gives 辛亥
  // But Dec 8 is after 大雪... 
  // 
  // AH WAIT. I think I'm confusing 节气令 and the month numbering in the formula.
  // The 五虎遁 formula counts from 寅月=1 onwards through the year.
  // Month 1=寅, 2=卯, ..., 11=亥, 12=子
  // 
  // For 亥月, monthNum should be 11 (DIZHI[10]=亥)
  // And 亥月 should give ganIndex = (startIndex + 11 - 1) % 10 = (8 + 10) % 10 = 8 = 壬
  // -> 壬亥 not 辛亥!
  // 
  // So either:
  // 1. The expected value 辛亥 is wrong, or
  // 2. I'm misunderstanding the month numbering
  // 
  // Let me think differently: Maybe for 丁年 the 五虎遁 gives a DIFFERENT start?
  // Re-read: "丁壬之年壬位顺行流"
  // This means for 丁年 AND 壬年, the month stem starts at 壬
  // But 顺行流 means follow the cycle... So start from 壬 and go forward
  // 
  // With start=壬(index 8):
  // month 1 (寅): 壬 (8)
  // month 2 (卯): 癸 (9)  
  // month 3 (辰): 甲 (0)
  // month 4 (巳): 乙 (1)
  // month 5 (午): 丙 (2)
  // month 6 (未): 丁 (3)
  // month 7 (申): 戊 (4)
  // month 8 (酉): 己 (5)
  // month 9 (戌): 庚 (6)
  // month 10 (亥): 辛 (7) <- 辛亥!
  // month 11 (子): 壬 (8)
  // month 12 (丑): 癸 (9)
  // 
  // So for 丁年, 亥月 (month 10) = 辛亥 ✓
  // 
  // Now, what is December 8 in terms of 节气令?
  // 大雪(12/7) is the START of 子月 (month 11)
  // So 12月8日 is in 子月 (month 11), not 亥月
  // 子月 = month 11 -> 壬子 (not 辛亥)
  // 
  // Hmm... the expected says 辛亥 (month 10 = 亥月)
  // Let me reconsider the 节气令 month mapping...
  // 
  // Actually, let me reconsider: maybe the app uses 公历月份 directly (without 节气 adjustment)?
  // For 12月: monthNum=12
  // getMonthGanZhi("丁酉", 12): 丁年 start=壬(index 8)
  // ganIndex = (8 + 12 - 1) % 10 = 19 % 10 = 9 = 癸
  // zhi = DIZHI[11] = 丑
  // -> 癸丑
  // 
  // That's also wrong...
  // 
  // Let me re-examine: maybe the code's monthNum=11 adjustment for month==1 is actually
  // TRYING to correct for this but doesn't work correctly for December.
  // 
  // Actually wait - the 2017年12月 case:
  // The user says month pillar should be 辛亥
  // 辛亥 = 辛(index 7) + 亥
  // 
  // For 丁年, 亥月 gives 辛亥 (as computed above, month 10)
  // So if monthNum=10 in the formula, we get 辛亥
  // But the code uses monthNum=12 for December...
  // 
  // WAIT. I think I've been wrong about the month numbering in the code!
  // The code uses: monthNum = month (1-12 for Jan-Dec)
  // But the 五虎遁 requires 寅月=1, 卯月=2, ... 丑月=12
  // So:
  // - month=1 -> 丑月 (monthNum=11 in formula, gives correct 丑月 result for Jan)
  // - month=12 -> 子月 (monthNum=12 in formula)
  // 
  // But the expected result is for 亥月 (monthNum=10 in formula)
  // So 12月8日 should map to 亥月, not 子月.
  // 
  // Hmm. Let me check the solar terms:
  // - 立冬 (11月7日) -> 亥月 starts
  // - 大雪 (12月7日) -> 子月 starts
  // 
  // So Dec 8 is indeed 子月, NOT 亥月. So the correct month pillar should be 壬子
  // not 辛亥.
  // 
  // Unless... the user's expected result "辛亥" is based on a different calculation
  // or there's an error in the expected values.
  // 
  // Let me check if there's a lunar calendar issue. 2017年12月8日 in the lunar calendar
  // is approximately 十月廿十 (农历十月二十).
  // But that doesn't directly give 亥月...
  // 
  // Actually, wait. Maybe I'm confusing 节气令 and the 五虎遁 month counting.
  // Let me re-examine the 五虎遁 formula more carefully.
  // 
  // The key insight: "丁壬之年壬位顺行流"
  // For 丁年: start at 壬
  // Then each month increment by 1 (顺行)
  // Month 1 = 寅 = 壬
  // Month 2 = 卯 = 癸
  // Month 3 = 辰 = 甲
  // ...
  // Month 10 = 亥 = 辛 ✓ (辛亥!)
  // Month 11 = 子 = 壬
  // Month 12 = 丑 = 癸
  // 
  // So for 丁年:
  // 寅月=壬, 卯月=癸, 辰月=甲, 巳月=乙, 午月=丙, 未月=丁, 申月=戊, 酉月=己, 戌月=庚, 亥月=辛, 子月=壬, 丑月=癸
  // 
  // Now, December 8 in 节气令 is 子月 (after 大雪 12/7)
  // So monthNum=11 in the 五虎遁 count, giving 壬子
  // 
  // But the expected says 辛亥 (month 10)
  // 
  // This means either:
  // 1. The expected value is wrong, OR
  // 2. The app's simple month-to-index mapping (using 公历 month directly) 
  //    actually gives different results
  // 
  // With 公历 month=12 directly:
  // monthNum=12, ganIndex = (8 + 12 - 1) % 10 = 19 % 10 = 9 = 癸
  // zhi = DIZHI[11] = 丑
  // -> 癸丑 (not 辛亥!)
  // 
  // So something is off. Let me re-read the calculateBazi function in the actual code:
  // int monthNum = month;
  // if (month == 1) monthNum = 11;
  // This means:
  // - Jan -> 丑月 (monthNum=11) -> correct for winter month before 立春
  // - Dec -> 子月 (monthNum=12)
  // 
  // With monthNum=12: ganIndex=(8+11)%10=9=癸, zhi=丑 -> 癸丑
  // 
  // With monthNum=11 (if Dec were treated as 子月): 
  // ganIndex=(8+10)%10=8=壬, zhi=亥 -> 壬亥
  // 
  // Neither gives 辛亥!
  // 
  // The expected 辛亥 comes from monthNum=10 (亥月)
  // 
  // I think the expected values provided might be wrong, OR there's a different
  // convention being used. Let me just check what the ACTUAL current code produces.
  // 
  // Actually, you know what - let me just run the flutter app's test to see what it produces.
  // The current code should give for 2017-12-08 00:05:
  // - yearGz = 丁酉 (1984+33=2017, 丁酉) ✓
  // - dayGz = 丁卯 (as calculated above) ✓  
  // - monthNum = 12 (no adjustment for Dec)
  // - monthGz = getMonthGanZhi("丁酉", 12) = getMonthGanZhi("丁", 12)
  //   丁年 start=壬(index 8), ganIndex=(8+12-1)%10=19%10=9=癸, zhi=DIZHI[11]=丑 -> 癸丑
  // - hourGz: dayGz=丁卯, 丁年 start=甲, 0:05 -> hour=0 -> zhiIndex=0, ganIndex=(0+0)%10=甲 -> 甲子
  // 
  // Result: 丁酉 癸丑 丁卯 甲子
  // Expected: 丁酉 辛亥 丁卯 庚子
  // 
  // Hmm, month is different (癸丑 vs 辛亥) and hour is different (甲子 vs 庚子)
  // 
  // For hour: 0:05 is in 子时 (23:00-00:59)
  // With dayGz=丁卯: 丁 start=甲, 子时 zhiIndex=0
  // ganIndex = startIndex + zhiIndex = 0 + 0 = 0 = 甲 -> 甲子 ✓
  // 
  // But expected 庚子: dayGz would need to be different...
  // If dayGz gave start=庚 (for 庚 start), then 庚+子=庚子
  // 
  // Let me re-check my dayGz calculation.
  // From Jan 1, 2000 (庚辰, index 17) to Dec 8, 2017
  // I calculated 6548 days, index = (17 + 6548) % 60 = 17 + 6548 % 60 = 17 + 8 = 25
  // WUXINGJIAZI[25] = 戊子
  // But expected dayGz = 丁卯 (not 戊子)
  // 
  // Hmm. Let me recalculate:
  // 2000-01-01 = 庚辰 = index 17
  // 2017-12-08:
  // 2000: 366 days (leap year), remaining from Jan 2: 365-1=364
  // 2001-2016: 16 years, leap years: 2004,2008,2012,2016 = 4 leap years
  //   Regular: 12 years * 365 = 4380
  //   Leap: 4 * 366 = 1464
  //   Total: 5844
  // 2017: Jan 1 to Dec 8 = 342 days
  // Total from Jan 1, 2000 (exclusive) to Dec 8, 2017: 364 + 5844 + 342 = 6550
  // Wait, this is FROM Jan 1 2000 TO Dec 8 2017
  // Actually: Jan 1, 2000 to Jan 1, 2017 = 17 years
  // Days in those 17 years (2000-2016):
  //   2000: 366-1 = 365 (from Jan 1 to Jan 1, 2001... wait this is confusing)
  // 
  // Let me just calculate: days between Jan 1, 2000 (day 0) and Dec 8, 2017
  // Number of days from Jan 1, 2000 (inclusive, at midnight) to Jan 1, 2017:
  // Years: 2000-2016 = 17 years
  // Leap years: 2000, 2004, 2008, 2012, 2016 = 5 leap years
  // Days = 12 * 365 + 5 * 366 = 4380 + 1830 = 6210
  // 
  // From Jan 1, 2017 to Dec 8, 2017:
  // 2017 is not leap. Total days = 342 (Jan 1 = day 0, Dec 8 = day 341)
  // Actually: Jan 1 to Dec 8 (not including Dec 8): 
  // 31+28+31+30+31+30+31+31+30+31+30+7 = let me count...
  // Jan: 31, Feb: 28, Mar: 31, Apr: 30, May: 31, Jun: 30
  // Jul: 31, Aug: 31, Sep: 30, Oct: 31, Nov: 30, Dec 1-8: 7
  // Total: 31+28+31+30+31+30+31+31+30+31+30+7 = 341
  // So Dec 8 is day 342 from Jan 1
  // 
  // Total: 6210 + 342 = 6552 days
  // But we should start from index 17 on Jan 1, 2000
  // So Dec 8, 2017 = index (17 + 6552) % 60 = (17 + 12) % 60 = 29
  // WUXINGJIAZI[29] = 甲辰
  // 
  // Still not matching... Let me try again with a cleaner approach.
  // I need: how many days from Jan 1, 2000 00:00 to Dec 8, 2017 00:00
  // 
  // Actually let me use the fact that 2017-12-08 is a known date.
  // JD for 2017-12-08 00:00:
  // From 2000-01-01 00:00 (JD 2451545) to 2017-12-08 00:00
  // 
  // I'll trust my original calculation: 6547 or 6548 days offset
  // (17 + 6547) % 60 = 17 + 7 = 24 -> 戊子
  // 
  // OK let me just move forward and test with flutter.
}
