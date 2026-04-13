import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/wuxing.dart' as wx;

/// 五行能量图表
/// 
/// 使用环形进度条展示五行强弱分布
class WuxingEnergyChart extends StatelessWidget {
  final wx.BaziAnalysis analysis;
  
  const WuxingEnergyChart({
    super.key,
    required this.analysis,
  });
  
  // 五行颜色映射
  static const wuxingColors = {
    '木': Color(0xFF4CAF50),
    '火': Color(0xFFF44336),
    '土': Color(0xFF795548),
    '金': Color(0xFFFFC107),
    '水': Color(0xFF2196F3),
  };
  
  // 五行图标
  static const wuxingIcons = {
    '木': Icons.eco,
    '火': Icons.local_fire_department,
    '土': Icons.landscape,
    '金': Icons.diamond,
    '水': Icons.water_drop,
  };
  
  @override
  Widget build(BuildContext context) {
    final score = analysis.wuxingScore;
    final scores = {
      '木': score.mu,
      '火': score.huo,
      '土': score.tu,
      '金': score.jin,
      '水': score.shui,
    };
    final maxScore = scores.values.reduce(math.max).toDouble();
    final minScore = scores.values.reduce(math.min).toDouble();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 五行能量条
        ...scores.entries.map((entry) {
          final wuxing = entry.key;
          final score = entry.value;
          final color = wuxingColors[wuxing] ?? Colors.grey;
          final icon = wuxingIcons[wuxing] ?? Icons.circle;
          final percentage = maxScore > 0 ? score / maxScore : 0.0;
          
          // 判断旺衰
          String level;
          Color levelColor;
          if (score >= maxScore * 0.8) {
            level = '极旺';
            levelColor = Colors.red.shade700;
          } else if (score >= maxScore * 0.6) {
            level = '偏旺';
            levelColor = Colors.orange.shade700;
          } else if (score >= maxScore * 0.4) {
            level = '中和';
            levelColor = Colors.green.shade700;
          } else if (score >= maxScore * 0.2) {
            level = '偏弱';
            levelColor = Colors.blue.shade700;
          } else {
            level = '极弱';
            levelColor = Colors.purple.shade700;
          }
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        wuxing,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        children: [
                          // 背景条
                          Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          // 能量条
                          FractionallySizedBox(
                            widthFactor: percentage.clamp(0.0, 1.0),
                            child: Container(
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color.withOpacity(0.7),
                                    color,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 分数文字
                          Container(
                            height: 24,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '$score',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: percentage > 0.5 ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: levelColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: levelColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        level,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: levelColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        
        const Divider(height: 24),
        
        // 五行相生相克提示
        _buildWuxingRelations(scores),
      ],
    );
  }
  
  Widget _buildWuxingRelations(Map<String, int> scores) {
    // 找出最旺和最弱的五行
    var maxWuxing = '';
    var minWuxing = '';
    var maxScore = 0;
    var minScore = 999;
    
    for (final entry in scores.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        maxWuxing = entry.key;
      }
      if (entry.value < minScore) {
        minScore = entry.value;
        minWuxing = entry.key;
      }
    }
    
    // 相生关系
    const shengMap = {
      '木': '火',
      '火': '土',
      '土': '金',
      '金': '水',
      '水': '木',
    };
    
    // 相克关系
    const keMap = {
      '木': '土',
      '火': '金',
      '土': '水',
      '金': '木',
      '水': '火',
    };
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '五行分析',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        if (maxWuxing.isNotEmpty)
          _buildAnalysisRow(
            Icons.trending_up,
            Colors.red,
            '最旺：$maxWuxing（分数：$maxScore）',
            '${maxWuxing}生${shengMap[maxWuxing]}，克${keMap[maxWuxing]}',
          ),
        
        const SizedBox(height: 8),
        
        if (minWuxing.isNotEmpty)
          _buildAnalysisRow(
            Icons.trending_down,
            Colors.blue,
            '最弱：$minWuxing（分数：$minScore）',
            '需${_getReverseSheng(minWuxing)}来生扶',
          ),
        
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '五行相生：木→火→土→金→水→木\n五行相克：木克土，土克水，水克火，火克金，金克木',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade700,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAnalysisRow(IconData icon, Color color, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _getReverseSheng(String wuxing) {
    const reverseShengMap = {
      '木': '水',
      '火': '木',
      '土': '火',
      '金': '土',
      '水': '金',
    };
    return reverseShengMap[wuxing] ?? '';
  }
}

/// 十神分析卡片
class ShishenAnalysisCard extends StatelessWidget {
  final wx.BaziAnalysis analysis;
  
  const ShishenAnalysisCard({
    super.key,
    required this.analysis,
  });
  
  // 十神颜色映射
  static const shishenColors = {
    '比肩': Color(0xFF4CAF50),
    '劫财': Color(0xFF8BC34A),
    '食神': Color(0xFFFFC107),
    '伤官': Color(0xFFFF9800),
    '偏财': Color(0xFF9C27B0),
    '正财': Color(0xFFE91E63),
    '七杀': Color(0xFFF44336),
    '正官': Color(0xFF2196F3),
    '偏印': Color(0xFF607D8B),
    '正印': Color(0xFF00BCD4),
  };
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '十神分布',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // 年柱十神
        _buildPillarShishen('年柱', analysis.shishenMap['年柱'], null),
        const SizedBox(height: 8),
        
        // 月柱十神
        _buildPillarShishen('月柱', analysis.shishenMap['月柱'], null),
        const SizedBox(height: 8),
        
        // 日柱（日主）
        _buildPillarShishen('日柱', analysis.shishenMap['日柱'], null),
        const SizedBox(height: 8),
        
        // 时柱十神
        _buildPillarShishen('时柱', analysis.shishenMap['时柱'], null),
        const SizedBox(height: 16),
        
        // 十神统计
        _buildShishenSummary(),
      ],
    );
  }
  
  Widget _buildPillarShishen(String pillarName, String? ganShishen, String? zhiShishen) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              pillarName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (ganShishen != null && ganShishen != '日主')
            _buildShishenChip(ganShishen, '天干'),
          if (ganShishen == '日主')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Text(
                '日主',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildShishenChip(String shishen, String type) {
    final color = shishenColors[shishen] ?? Colors.grey;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            shishen,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            type,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildShishenSummary() {
    final allShishen = [
      analysis.shishenMap['年柱'],
      analysis.shishenMap['月柱'],
      analysis.shishenMap['时柱'],
    ].whereType<String>().toList();
    
    // 统计各十神出现次数
    final counts = <String, int>{};
    for (final ss in allShishen) {
      counts[ss] = (counts[ss] ?? 0) + 1;
    }
    
    if (counts.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                '十神统计',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: counts.entries.map((entry) {
              final color = shishenColors[entry.key] ?? Colors.grey;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Text(
                  '${entry.key} × ${entry.value}',
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
