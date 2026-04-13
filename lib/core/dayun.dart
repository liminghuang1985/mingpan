/// 大运计算
library;

import 'package:mingpan_app/models/bazi.dart';
import 'package:mingpan_app/core/solarterm.dart';

/// 阳天干
const YANG_GAN = ['甲', '丙', '戊', '庚', '壬'];

/// 判断天干阴阳
bool isYang(String gan) {
  final g = gan.length > 1 ? gan[0] : gan;
  return YANG_GAN.contains(g);
}

/// 大运方向
enum DayunDirection { shun, ni }

extension DayunDirectionExt on DayunDirection {
  String get nameCn {
    switch (this) {
      case DayunDirection.shun:
        return '顺';
      case DayunDirection.ni:
        return '逆';
    }
  }
}

/// 大运数据
class Dayun {
  /// 大运名称（如"甲子"）
  final String ganZhi;

  /// 起运年龄（岁）
  final int startAge;

  /// 结束年龄（岁）
  final int endAge;

  /// 起运年份
  final int startYear;

  /// 方向
  final DayunDirection direction;

  /// 大运序号（0=第一步大运）
  final int index;

  const Dayun({
    required this.ganZhi,
    required this.startAge,
    required this.endAge,
    required this.startYear,
    required this.direction,
    required this.index,
  });

  String get gan => ganZhi.isNotEmpty ? ganZhi[0] : '';
  String get zhi => ganZhi.length > 1 ? ganZhi[1] : '';

  @override
  String toString() => 'Dayun$ganZhi(${startAge}-${endAge})';
}

/// 起运信息
class QiyunInfo {
  final int sui;
  final int yue;
  final DayunDirection direction;
  final int totalDays;

  const QiyunInfo({
    required this.sui,
    required this.yue,
    required this.direction,
    required this.totalDays,
  });
}

/// 计算大运方向
DayunDirection getDayunDirection(String yearGan, String gender) {
  final yang = isYang(yearGan);
  if ((yang && gender == '男') || (!yang && gender == '女')) {
    return DayunDirection.shun;
  }
  return DayunDirection.ni;
}

/// 计算起运年龄
QiyunInfo calcQiyun(DateTime birthDate, (String, int, int) nextJieqi, DayunDirection direction) {
  final (jqName, jqMonth, jqDay) = nextJieqi;

  int jqYear = birthDate.year;
  DateTime jqDate = DateTime(jqYear, jqMonth, jqDay);
  if (jqDate.isBefore(birthDate) || jqDate.isAtSameMomentAs(birthDate)) {
    jqYear += 1;
    jqDate = DateTime(jqYear, jqMonth, jqDay);
  }

  final diffDays = jqDate.difference(birthDate).inDays;
  final totalMonths = (diffDays ~/ 3) * 12 + (diffDays % 3) * 4;
  final sui = totalMonths ~/ 12;
  final yue = totalMonths % 12;

  return QiyunInfo(
    sui: sui,
    yue: yue,
    direction: direction,
    totalDays: diffDays,
  );
}

/// 获取日柱地支索引
int getDayZhiPosition(String dayZhi) {
  const dizhiOrder = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
  return dizhiOrder.indexOf(dayZhi);
}

/// 计算完整大运排盘
DayunResult calculateDayun(Bazi bazi, DateTime birthDate) {
  // 获取下一个节气
  final nextJq = getNextSolarTerm(
    birthDate.month == 12 ? birthDate.year + 1 : birthDate.year,
    birthDate.month == 12 ? 1 : birthDate.month + 1,
    birthDate.day,
  );

  final direction = getDayunDirection(bazi.yearGan, bazi.gender);

  // Handle nullable nextJq
  final (jqName, jqMonth, jqDay) = nextJq ?? ('小寒', 1, 5);

  final qiyun = calcQiyun(birthDate, (jqName, jqMonth, jqDay), direction);

  final dayunList = getDayunListFromBazi(
    bazi: bazi,
    birthDate: birthDate,
    qiyun: qiyun,
    direction: direction,
  );

  return DayunResult(
    direction: direction,
    qiyun: qiyun,
    dayuns: dayunList,
  );
}

/// 大运计算结果
class DayunResult {
  final DayunDirection direction;
  final QiyunInfo qiyun;
  final List<Dayun> dayuns;

  const DayunResult({
    required this.direction,
    required this.qiyun,
    required this.dayuns,
  });
}

/// 从八字计算大运列表
List<Dayun> getDayunListFromBazi({
  required Bazi bazi,
  required DateTime birthDate,
  required QiyunInfo qiyun,
  required DayunDirection direction,
  int count = 10,
}) {
  final dayuns = <Dayun>[];

  const tiangan = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];

  // 月柱天干地支索引
  final monthGan = bazi.monthGan;
  final monthZhi = bazi.monthZhi;
  final monthGanIndex = tiangan.indexOf(monthGan);
  final monthZhiIndex = getDayZhiPosition(monthZhi);

  final step = direction == DayunDirection.shun ? 1 : -1;

  int currentAge = qiyun.sui;
  int currentYear = birthDate.year + qiyun.sui;

  int currentGanIndex = monthGanIndex;
  int currentZhiIndex = monthZhiIndex;

  for (int i = 0; i < count; i++) {
    final startAge = currentAge;
    final endAge = startAge + 10;

    final gan = tiangan[currentGanIndex];
    final zhi = _dizhi[currentZhiIndex];

    dayuns.add(Dayun(
      ganZhi: '$gan$zhi',
      startAge: startAge,
      endAge: endAge,
      startYear: currentYear,
      direction: direction,
      index: i,
    ));

    currentGanIndex = (currentGanIndex + step) % 10;
    if (currentGanIndex < 0) currentGanIndex += 10;

    currentZhiIndex = (currentZhiIndex + step) % 12;
    if (currentZhiIndex < 0) currentZhiIndex += 12;

    currentAge += 10;
    currentYear += 10;
  }

  return dayuns;
}

const _dizhi = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
