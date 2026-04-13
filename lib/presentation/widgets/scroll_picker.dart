import 'package:flutter/material.dart';

/// 滚动选择器组件（iOS风格）
class ScrollPicker extends StatefulWidget {
  final List<String> items;
  final int initialIndex;
  final ValueChanged<int> onSelectedItemChanged;
  final double itemHeight;
  final double height;

  const ScrollPicker({
    super.key,
    required this.items,
    required this.onSelectedItemChanged,
    this.initialIndex = 0,
    this.itemHeight = 44.0,
    this.height = 220.0,
  });

  @override
  State<ScrollPicker> createState() => _ScrollPickerState();
}

class _ScrollPickerState extends State<ScrollPicker> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // 滚动列表
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: widget.itemHeight,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: widget.onSelectedItemChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index >= widget.items.length) {
                  return null;
                }
                return Center(
                  child: Text(
                    widget.items[index],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
              childCount: widget.items.length,
            ),
          ),
          // 中间高亮区域
          Center(
            child: Container(
              height: widget.itemHeight,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                color: Colors.grey.shade100.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 日期时间滚动选择器
class DateTimeScrollPicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateTimeChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DateTimeScrollPicker({
    super.key,
    required this.initialDate,
    required this.onDateTimeChanged,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<DateTimeScrollPicker> createState() => _DateTimeScrollPickerState();
}

class _DateTimeScrollPickerState extends State<DateTimeScrollPicker> {
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;
  late int _selectedHour;
  late int _selectedMinute;

  late List<int> _years;
  late List<int> _months;
  late List<int> _days;
  late List<int> _hours;
  late List<int> _minutes;

  @override
  void initState() {
    super.initState();
    
    // 初始化年份范围
    final firstYear = widget.firstDate?.year ?? 1900;
    final lastYear = widget.lastDate?.year ?? DateTime.now().year;
    _years = List.generate(lastYear - firstYear + 1, (i) => firstYear + i);
    
    // 初始化月份
    _months = List.generate(12, (i) => i + 1);
    
    // 初始化小时和分钟
    _hours = List.generate(24, (i) => i);
    _minutes = List.generate(60, (i) => i);
    
    // 设置初始值
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;
    _selectedHour = widget.initialDate.hour;
    _selectedMinute = widget.initialDate.minute;
    
    _updateDays();
  }

  void _updateDays() {
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    _days = List.generate(daysInMonth, (i) => i + 1);
    
    // 如果当前选择的日期超过了该月的天数，调整为该月最后一天
    if (_selectedDay > daysInMonth) {
      _selectedDay = daysInMonth;
    }
  }

  void _notifyChange() {
    widget.onDateTimeChanged(
      DateTime(_selectedYear, _selectedMonth, _selectedDay, _selectedHour, _selectedMinute),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 日期部分
          const Text(
            '出生日期',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 年
              Expanded(
                child: Column(
                  children: [
                    const Text('年', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ScrollPicker(
                      items: _years.map((y) => y.toString()).toList(),
                      initialIndex: _years.indexOf(_selectedYear),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedYear = _years[index];
                          _updateDays();
                          _notifyChange();
                        });
                      },
                    ),
                  ],
                ),
              ),
              // 月
              Expanded(
                child: Column(
                  children: [
                    const Text('月', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ScrollPicker(
                      items: _months.map((m) => m.toString()).toList(),
                      initialIndex: _months.indexOf(_selectedMonth),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedMonth = _months[index];
                          _updateDays();
                          _notifyChange();
                        });
                      },
                    ),
                  ],
                ),
              ),
              // 日
              Expanded(
                child: Column(
                  children: [
                    const Text('日', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ScrollPicker(
                      items: _days.map((d) => d.toString()).toList(),
                      initialIndex: _days.indexOf(_selectedDay),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedDay = _days[index];
                          _notifyChange();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          // 时间部分
          const Text(
            '出生时间',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 时
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    const Text('时', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ScrollPicker(
                      items: _hours.map((h) => h.toString().padLeft(2, '0')).toList(),
                      initialIndex: _hours.indexOf(_selectedHour),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedHour = _hours[index];
                          _notifyChange();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              // 分
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    const Text('分', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ScrollPicker(
                      items: _minutes.map((m) => m.toString().padLeft(2, '0')).toList(),
                      initialIndex: _minutes.indexOf(_selectedMinute),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedMinute = _minutes[index];
                          _notifyChange();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
