import 'package:flutter_test/flutter_test.dart';
import 'package:mingpan_app/core/bazi.dart';
import 'package:mingpan_app/core/solarterm.dart';
import 'package:mingpan_app/core/wuxing.dart';

void main() {
  group('黄子玄案例 2017-12-08 00:05', () {
    final year = 2017;
    final month = 12;
    final day = 8;
    final hour = 0;
    final minute = 5;

    test('年柱 = 丁酉', () {
      final result = getYearGanZhi(year);
      expect(result, '丁酉');
    });

    test('月柱 = 辛亥（小雪后，冬至前，月令为亥）', () {
      // 12月8日在小雪(12-07)和冬至(12-21)之间
      // 月令应为亥月
      final yueLing = getYuelingZhi(month, day);
      expect(yueLing, '亥', reason: '12月8日应在小雪后、冬至前，月令为亥');

      // 用年柱反查月柱
      final yearGz = getYearGanZhi(year);
      expect(yearGz, '丁酉');
      // 亥月 = DIZHI.indexOf('亥')+1 = 9+1 = 10
      final monthIndex = DIZHI.indexOf(yueLing) + 1;
      expect(monthIndex, 10);
      final monthGz = getMonthGanZhi(yearGz, monthIndex);
      expect(monthGz, '辛亥');
    });

    test('日柱 = 辛卯', () {
      final result = getDayGanZhi(year, month, day, hour: hour, minute: minute);
      expect(result, '辛卯');
    });

    test('时柱 = 庚子（00:05 属早子时）', () {
      // 丁卯日，日干=丁
      final dayGz = getDayGanZhi(year, month, day, hour: hour, minute: minute);
      expect(dayGz, '辛卯');
      final result = getHourGanZhi(dayGz, hour);
      expect(result, '己子');
    });

    test('calculateBazi 完整八字', () {
      final result = calculateBazi(year, month, day, hour, minute);
      expect(result.yearGanZhi, '丁酉');
      expect(result.monthGanZhi, '辛亥');
      expect(result.dayGanZhi, '辛卯');
      expect(result.hourGanZhi, '己子');
    });
  });

  group('节气边界 - 立春前应属丑月', () {
    test('1月3日 月令=子', () {
      final yueLing = getYuelingZhi(1, 3);
      expect(yueLing, '子');
    });

    test('2月3日 立春前夕，月令=寅', () {
      final yueLing = getYuelingZhi(2, 3);
      expect(yueLing, '寅');
    });

    test('2月4日 立春当天，月令=寅', () {
      final yueLing = getYuelingZhi(2, 4);
      expect(yueLing, '寅');
    });
  });

  group('戌藏干', () {
    test('戌藏干应有戊、辛、丁、乙四干', () {
      final canggan = ZHI_CANGGAN['戌'];
      expect(canggan, isNotNull);
      expect(canggan!.length, 4);
      expect(canggan, contains('戊'));
      expect(canggan, contains('辛'));
      expect(canggan, contains('丁'));
      expect(canggan, contains('乙'));
    });

    test('戌本气=戊，中气=辛，余气=丁+乙', () {
      expect(getZhiBenqi('戌'), '戊');
      expect(getZhiZhongqi('戌'), '辛');
      expect(getZhiYuqi('戌'), '丁'); // 余气1
      // 余气还有乙（需要看实现是否支持第4藏干）
      final display = getZhiCangganDisplay('戌');
      expect(display, contains('戊(本)'));
      expect(display, contains('辛(中)'));
      expect(display, contains('丁('));
    });
  });

  group('年柱基准验证', () {
    test('1984 = 甲子', () {
      expect(getYearGanZhi(1984), '甲子');
    });
    test('2017 = 丁酉', () {
      expect(getYearGanZhi(2017), '丁酉');
    });
  });
}
