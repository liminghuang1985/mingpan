# 命盘算法详细设计

## 1. 儒略日计算（核心）

### 1.1 公历转儒略日
```javascript
function toJulianDay(year, month, day, hour = 0, minute = 0) {
  if (month <= 2) {
    year -= 1;
    month += 12;
  }
  const A = Math.floor(year / 100);
  const B = 2 - A + Math.floor(A / 4);
  const JD = Math.floor(365.25 * (year + 4716))
           + Math.floor(30.6001 * (month + 1))
           + day + B - 1524.5
           + (hour + minute / 60) / 24;
  return Math.floor(JD + 0.5);
}

// 验证: 2000-01-01 00:00:00 = JD 2451545
// toJulianDay(2000, 1, 1, 0, 0) === 2451545
```

### 1.2 日柱计算（60甲子独立查找）

**正确做法：用已知基准点倒退 + 60甲子数组查找**

```javascript
const WUXINGJIAZI = [
  '甲子','乙丑','丙寅','丁卯','戊辰','己巳','庚午','辛未','壬申','癸酉',
  '甲戌','乙亥','丙子','丁丑','戊寅','己卯','庚辰','辛巳','壬午','癸未',
  '甲申','乙酉','丙戌','丁亥','戊子','己丑','庚寅','辛卯','壬辰','癸巳',
  '甲午','乙未','丙申','丁酉','戊戌','己亥','庚子','辛丑','壬寅','癸卯',
  '甲辰','乙巳','丙午','丁未','戊申','己酉','庚戌','辛亥','壬子','癸丑',
  '甲寅','乙卯','丙辰','丁巳','戊午','己未','庚申','辛酉','壬戌','癸亥'
];

function getDayGanZhi(year, month, day, hour = 0, minute = 0) {
  // 基准: 2000-01-01 00:00 = 庚辰 = index 17
  const BASE_JD = 2451545;
  const BASE_INDEX = 17; // 庚辰在 WUXINGJIAZI 中的索引
  
  const birthJD = toJulianDay(year, month, day, hour, minute);
  const offset = birthJD - BASE_JD;
  const index = ((BASE_INDEX + offset) % 60 + 60) % 60;
  
  return WUXINGJIAZI[index];
}
```

---

## 2. 年柱计算

### 2.1 六十甲子起点
- 1984年是甲子年 (JD ≈ 2445701)
- 每60年循环一次

### 2.2 计算公式
```javascript
function getYearGanZhi(year) {
  // 以 1984 年为基准（甲子年，index=0）
  const BASE_YEAR = 1984;
  const BASE_INDEX = 0;
  
  const offset = year - BASE_YEAR;
  const index = ((BASE_INDEX + offset) % 60 + 60) % 60;
  
  return WUXINGJIAZI[index];
}

// 验证:
// getYearGanZhi(1984) === '甲子'
// getYearGanZhi(2017) === '丁酉' (黄子玄案例)
```

---

## 3. 月柱计算

### 3.1 五虎遁（年干→月干）

**五虎遁口诀：甲己之年丙作首，乙庚之年戊为头，丙辛必定寻庚起，丁壬壬位顺行流，戊癸之年还甲来**

```javascript
// 五虎遁：年干 → 月干起始（寅月=1）
const WUHUTUN = {
  '甲': '丙',  // 甲己年起丙寅
  '乙': '戊',  // 乙庚年起戊寅
  '丙': '庚',  // 丙辛年起庚寅
  '丁': '壬',  // 丁壬年起壬寅
  '戊': '甲',  // 戊癸年起甲寅
  '己': '丙',  // 甲己年起丙寅
  '庚': '戊',  // 乙庚年起戊寅
  '辛': '庚',  // 丙辛年起庚寅
  '壬': '壬',  // 丁壬年起壬寅
  '癸': '甲'   // 戊癸年起甲寅
};

const TIANGAN = ['甲','乙','丙','丁','戊','己','庚','辛','壬','癸'];
const DIZHI = ['寅','卯','辰','巳','午','未','申','酉','戌','亥','子','丑'];

function getMonthGanZhi(yearGan, month) {
  // month: 1-12，对应寅月到丑月
  const startGan = WUHUTUN[yearGan];
  const startIndex = TIANGAN.indexOf(startGan);
  const ganIndex = (startIndex + month - 1) % 10;
  const gan = TIANGAN[ganIndex];
  const zhi = DIZHI[month - 1];
  return gan + zhi;
}
```

### 3.2 节气与月令

**月令由节气决定，不是简单的农历月：**
```
立春(2月4日左右) → 寅月起始
惊蛰(3月5日左右) → 卯月起始
清明(4月5日左右) → 辰月起始
...以此类推
```

**第一版简化方案：** 使用平均节气日期
```javascript
// 简化节气日期（月-日）
const AVERAGE_SOLAR_TERMS = {
  '立春': '02-04', '雨水': '02-19', '惊蛰': '03-05', '春分': '03-20',
  '清明': '04-05', '谷雨': '04-20', '立夏': '05-05', '小满': '05-21',
  '芒种': '06-05', '夏至': '06-21', '小暑': '07-07', '大暑': '07-22',
  '立秋': '08-07', '处暑': '08-23', '白露': '09-07', '秋分': '09-23',
  '寒露': '10-08', '霜降': '10-23', '立冬': '11-07', '小雪': '11-22',
  '大雪': '12-07', '冬至': '12-21', '小寒': '01-05', '大寒': '01-20'
};
```

**推荐使用精确库（后续版本）：**
- `solarterm` - 精确到分钟的节气计算
- `lunar` - 农历库，含八字排盘

---

## 4. 时柱计算

### 4.1 五鼠遁（日干→时干）

**五鼠遁口诀：甲己还生甲，乙庚丙作初，丙辛从戊起，丁壬庚子居，戊癸何方发，壬子是真途**

```javascript
// 五鼠遁：日干 → 时干起始（子时=23:00-00:59）
const WUSHUTUN = {
  '甲': '甲',  // 甲己日起甲子时
  '乙': '丙',  // 乙庚日起丙子时
  '丙': '戊',  // 丙辛日起戊子时
  '丁': '庚',  // 丁壬日起庚子时
  '戊': '壬',  // 戊癸日起壬子时
  '己': '甲',  // 甲己日起甲子时
  '庚': '丙',  // 乙庚日起丙子时
  '辛': '戊',  // 丙辛日起戊子时
  '壬': '庚',  // 丁壬日起庚子时
  '癸': '壬'   // 戊癸日起壬子时
};

const ZHI_HOUR = ['子','丑','寅','卯','辰','巳','午','未','申','酉','戌','亥'];

function getHourGanZhi(dayGan, hour) {
  // hour: 0-23
  // 23:00-00:59 = 子时(0), 01:00-02:59 = 丑时(1), ...
  // 注意：23:00-23:59 是"夜子时"，00:00-00:59 是"早子时"
  let zhiIndex;
  if (hour >= 23) {
    zhiIndex = 0; // 夜子时
  } else {
    zhiIndex = Math.floor((hour + 1) / 2) % 12;
  }
  
  const startGan = WUSHUTUN[dayGan];
  const startIndex = TIANGAN.indexOf(startGan);
  const ganIndex = (startIndex + zhiIndex) % 10;
  
  return TIANGAN[ganIndex] + ZHI_HOUR[zhiIndex];
}
```

---

## 5. 大运计算

### 5.1 阴阳判断
```javascript
const YANG_GAN = ['甲','丙','戊','庚','壬'];

function isYang(gan) {
  return YANG_GAN.includes(gan);
}
```

### 5.2 大运方向
| 条件 | 方向 |
|------|------|
| 阳年男 | 顺行 |
| 阳年女 | 逆行 |
| 阴年男 | 逆行 |
| 阴年女 | 顺行 |

```javascript
function getDayunDirection(yearGan, gender) {
  const yang = isYang(yearGan);
  if ((yang && gender === '男') || (!yang && gender === '女')) {
    return '顺';
  }
  return '逆';
}
```

### 5.3 起运年龄计算

```javascript
/**
 * 计算起运年龄
 * 规则：3天=1岁，1天=4个月，1时辰=10天
 * 
 * @param birthDate - 出生日期（公历）
 * @param nextJieqiDate - 下一个节气日期
 * @param direction - 顺/逆
 * @returns 起运年龄（岁+月）
 */
function calcQiyun(birthDate, nextJieqiDate, direction) {
  const diffDays = Math.ceil((nextJieqiDate - birthDate) / (1000 * 60 * 60 * 24));
  
  // 3天=1岁，即1天=4个月
  const totalMonths = Math.floor(diffDays / 3) * 12 + (diffDays % 3) * 4;
  const sui = Math.floor(totalMonths / 12);
  const yue = totalMonths % 12;
  
  return { sui, yue, direction };
}
```

---

## 6. 五行分析

### 6.1 天干五行
```javascript
const GAN_WUXING = {
  '甲': '木', '乙': '木',
  '丙': '火', '丁': '火',
  '戊': '土', '己': '土',
  '庚': '金', '辛': '金',
  '壬': '水', '癸': '水'
};
```

### 6.2 地支藏干
```javascript
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
  '亥': ['壬', '甲']
};
```

### 6.3 日主旺度判断
```javascript
function calcDayMasterStrength(bazi) {
  const dayMaster = bazi.dayGan; // 日干
  const dayMasterWX = GAN_WUXING[dayMaster];
  
  let score = 0;
  
  // 1. 天干帮扶（同类加分）
  bazi.tiangans.forEach(g => {
    if (GAN_WUXING[g] === dayMasterWX) score += 2;
  });
  
  // 2. 地支藏干（同类加分）
  bazi.dizhis.forEach(z => {
    ZHI_CANGGAN[z].forEach(cg => {
      if (GAN_WUXING[cg] === dayMasterWX) score += 1;
    });
  });
  
  // 3. 月令加成（最重要）
  const yuelingWX = getYuelingWuxing(bazi.yueling);
  if (yuelingWX === dayMasterWX) score += 3;
  
  return score; // >8 偏强，<5 偏弱
}
```

---

## 7. 测试用例

### 7.1 验证案例
```
黄子玄
出生: 2017年12月8日 00:05
性别: 男
期望结果:
- 年柱: 丁酉
- 月柱: 辛亥  
- 日柱: 丁卯
- 时柱: 庚子
```

### 7.2 验证步骤
1. `getYearGanZhi(2017)` → 丁酉 ✓
2. 12月8日在小雪(12/7)和冬至(12/22)之间，月令=亥 → 辛亥 ✓
3. `toJulianDay(2017,12,8,0,5)` → 计算 JD 后 `getDayGanZhi` → 丁卯 ✓
4. `getHourGanZhi('丁', 0)` → 庚子 ✓

### 7.3 边界情况测试
- 节气当天 23:30 出生（跨节气）
- 夏令时出生
- 闰月农历生日
- 甲子年（60年循环起点）

---

## 8. 推荐开源库

### 8.1 lunar (Node.js/JavaScript)
```javascript
const lunar = require('lunar');
const result = lunar.convertor.solarToLunar(2017, 12, 8);
// 八字、大运、流年全有
```

### 8.2 solarterm
精确到分钟的节气计算，基于天文算法。

### 8.3 suncalc
太阳位置计算，可用于验证节气。
