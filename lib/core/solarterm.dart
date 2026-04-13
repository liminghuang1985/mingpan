/// 节气计算
/// 第一版使用简化平均日期
/// 参考: ALGORITHM.md
library;

/// 二十四节气平均日期（月-日）
/// 来源：传统节气统计平均值
const AVERAGE_SOLAR_TERMS = {
  '小寒': '01-05',
  '大寒': '01-20',
  '立春': '02-04',
  '雨水': '02-19',
  '惊蛰': '03-05',
  '春分': '03-20',
  '清明': '04-05',
  '谷雨': '04-20',
  '立夏': '05-05',
  '小满': '05-21',
  '芒种': '06-05',
  '夏至': '06-21',
  '小暑': '07-07',
  '大暑': '07-22',
  '立秋': '08-07',
  '处暑': '08-23',
  '白露': '09-07',
  '秋分': '09-23',
  '寒露': '10-08',
  '霜降': '10-23',
  '立冬': '11-07',
  '小雪': '11-22',
  '大雪': '12-07',
  '冬至': '12-21',
};

/// 节气名称列表（按顺序）
const SOLAR_TERM_NAMES = [
  '小寒', '大寒', '立春', '雨水', '惊蛰', '春分',
  '清明', '谷雨', '立夏', '小满', '芒种', '夏至',
  '小暑', '大暑', '立秋', '处暑', '白露', '秋分',
  '寒露', '霜降', '立冬', '小雪', '大雪', '冬至',
];

/// 获取指定年份的节气日期
///
/// 返回格式：{ '小寒': '01-05', '大寒': '01-20', ... }
Map<String, String> getSolarTermDates(int year) {
  // 节气日期在年份间可能有微小变动，这里使用平均日期
  // 精确版本需要天文算法计算
  return AVERAGE_SOLAR_TERMS;
}

/// 获取当前节气名称
///
/// [month] 月（1-12）
/// [day] 日
String getCurrentJieqi(int month, int day) {
  try {
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return '冬至'; // 异常时返回默认值
    }
    final String dateStr = '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

    // 找到最后一个早于当前日期的节气
    String current = '冬至'; // 默认
    for (final entry in AVERAGE_SOLAR_TERMS.entries) {
      if (entry.value.compareTo(dateStr) <= 0) {
        current = entry.key;
      } else {
        break;
      }
    }
    return current;
  } catch (_) {
    return '冬至'; // 异常时返回默认值
  }
}

/// 根据日期判断月令地支
///
/// 月令由节气决定：
/// 立春(2月4日左右) → 寅月
/// 惊蛰(3月5日左右) → 卯月
/// 清明(4月5日左右) → 辰月
/// 以此类推
///
/// 第一版简化：使用平均节气日期
String getYuelingZhi(int month, int day) {
  try {
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return '寅'; // 异常默认
    }
    final String dateStr = '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

    final List<String> jieqiOrder = [
      '小寒', '大寒', '立春', '雨水', '惊蛰', '春分',
      '清明', '谷雨', '立夏', '小满', '芒种', '夏至',
      '小暑', '大暑', '立秋', '处暑', '白露', '秋分',
      '寒露', '霜降', '立冬', '小雪', '大雪', '冬至',
    ];
    // 月令地支（二十四节气对应月令）
    // 丑月：小寒(01-05)~大寒(01-20)  寅月：立春(02-04)~雨水(02-19)
    // 卯月：惊蛰(03-05)~春分(03-20)  辰月：清明(04-05)~谷雨(04-20)
    // 巳月：立夏(05-05)~小满(05-21)  午月：芒种(06-05)~夏至(06-21)
    // 未月：小暑(07-07)~大暑(07-22)  申月：立秋(08-07)~处暑(08-23)
    // 酉月：白露(09-07)~秋分(09-23)  戌月：寒露(10-08)~霜降(10-23)
    // 亥月：立冬(11-07)~小雪(11-22)  子月：大雪(12-07)~冬至(12-21)
    // 年末过了冬至(12-21)后属子月，小寒(01-05)后属丑月
    final List<String> yueLingZhi = [
      '丑', '丑', '寅', '寅', '卯', '卯',  // 0~5:  小寒→丑, 大寒→丑, 立春→寅, 雨水→寅, 惊蛰→卯, 春分→卯
      '辰', '辰', '巳', '巳', '午', '午',  // 6~11: 清明→辰, 谷雨→辰, 立夏→巳, 小满→巳, 芒种→午, 夏至→午
      '未', '未', '申', '申', '酉', '酉',  // 12~17: 小暑→未, 大暑→未, 立秋→申, 处暑→申, 白露→酉, 秋分→酉
      '戌', '戌', '亥', '亥', '子', '子',  // 18~23: 寒露→戌, 霜降→戌, 立冬→亥, 小雪→亥, 大雪→子, 冬至→子
    ];

    for (int i = 0; i < jieqiOrder.length; i++) {
      final String jqDate = AVERAGE_SOLAR_TERMS[jieqiOrder[i]] ?? '01-01';
      // dateStr < 节气日期：当前日期在该节气之前，属上一个节气的月令
      // dateStr == 节气日期：节气当天仍属当前月令（循环继续到下一节气才切换）
      if (dateStr.compareTo(jqDate) <= 0) {
        if (i == 0) {
          // 年初（小于小寒 01-05），属子月
          return '子';
        }
        return yueLingZhi[i - 1];
      }
    }
    // 年末过了冬至（12-21之后），属子月
    return '子';
  } catch (_) {
    return '寅';
  }
}

/// 获取下一个节气的日期
///
/// 第一版返回平均日期
/// 异常时返回默认值 (小寒, 1, 5)
(String, int, int)? getNextSolarTerm(int year, int month, int day) {
  try {
    if (year < 1900 || year > 2100 || month < 1 || month > 12 || day < 1 || day > 31) {
      return ('小寒', 1, 5);
    }
    final String dateStr = '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

    for (final entry in AVERAGE_SOLAR_TERMS.entries) {
      if (entry.value.compareTo(dateStr) > 0) {
        // 找到了下一个节气
        final parts = entry.value.split('-');
        if (parts.length != 2) return ('小寒', 1, 5);
        final m = int.tryParse(parts[0]);
        final d = int.tryParse(parts[1]);
        if (m == null || d == null) return ('小寒', 1, 5);
        return (entry.key, m, d);
      }
    }

    // 过了冬至，下一年小寒
    return ('小寒', 1, 5);
  } catch (_) {
    return ('小寒', 1, 5);
  }
}
