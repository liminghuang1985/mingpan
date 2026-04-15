import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/dayun.dart';

/// 大运时间线组件
/// 
/// 可视化展示大运流转，高亮当前大运
class DayunTimeline extends StatelessWidget {
  final DayunResult dayunResult;
  final int currentYear;
  final Function(Dayun)? onDayunTap;
  
  const DayunTimeline({
    super.key,
    required this.dayunResult,
    required this.currentYear,
    this.onDayunTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final currentAge = currentYear - (dayunResult.dayuns.firstOrNull?.startYear ?? currentYear) 
        + (dayunResult.qiyun.sui);
    
    // 找到当前大运
    Dayun? currentDayun;
    for (final d in dayunResult.dayuns) {
      if (currentAge >= d.startAge && currentAge < d.endAge) {
        currentDayun = d;
        break;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 起运信息
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.flag, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '起运：${dayunResult.qiyun.sui}岁${dayunResult.qiyun.yue}月 '
                  '(${dayunResult.direction.nameCn}行)',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '当前${currentAge}岁',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // 大运时间线
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dayunResult.dayuns.length,
            itemBuilder: (context, index) {
              final dayun = dayunResult.dayuns[index];
              final isActive = dayun.index == currentDayun?.index;
              final isPast = currentAge >= dayun.endAge;
              final isFuture = currentAge < dayun.startAge;
              
              return GestureDetector(
                onTap: () => onDayunTap?.call(dayun),
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      // 大运干支 — 统一蓝色系，通过亮度区分状态
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isActive
                                ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)]
                                : isPast
                                    ? [const Color(0xFF90A4AE), const Color(0xFF607D8B)]
                                    : [const Color(0xFF64B5F6), const Color(0xFF42A5F5)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF1565C0).withOpacity(0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            dayun.ganZhi,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 2,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 年龄范围 — 主信息，放大加粗
                      Text(
                        '${dayun.startAge}-${dayun.endAge}岁',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? const Color(0xFF0D47A1)
                              : isPast
                                  ? const Color(0xFF607D8B)
                                  : const Color(0xFF42A5F5),
                        ),
                      ),
                      const SizedBox(height: 2),

                      // 年份范围 — 辅助信息，降级显示
                      Text(
                        '${dayun.startYear}-${dayun.startYear + 9}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // 当前进度条（仅在当前大运显示）
                      if (isActive) ...[
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: Colors.grey.shade300,
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (max(0, currentAge - dayun.startAge) / 10).clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: const Color(0xFF1565C0),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${max(0, currentAge - dayun.startAge + 1)}/10年',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                      ] else if (isPast)
                        const Icon(Icons.check_circle, size: 16, color: Color(0xFF90A4AE))
                      else
                        const Icon(Icons.schedule, size: 16, color: Color(0xFF64B5F6)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 大运详情卡片
class DayunDetailCard extends StatelessWidget {
  final Dayun dayun;
  final bool isCurrentDayun;
  
  const DayunDetailCard({
    super.key,
    required this.dayun,
    this.isCurrentDayun = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isCurrentDayun ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentDayun
            ? BorderSide(color: Colors.blue.shade300, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dayun.ganZhi,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '第${dayun.index + 1}步大运',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dayun.direction.nameCn}行',
                        style: TextStyle(
                          fontSize: 12,
                          color: dayun.direction == DayunDirection.shun
                              ? Colors.blue.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrentDayun)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '当前',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.cake, '年龄段', '${dayun.startAge} - ${dayun.endAge} 岁'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_month, '年份', '${dayun.startYear} - ${dayun.startYear + 9}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.wb_sunny, '天干', dayun.gan),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.landscape, '地支', dayun.zhi),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
