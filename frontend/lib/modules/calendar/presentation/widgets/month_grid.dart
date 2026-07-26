import 'package:flutter/material.dart';

import '../../domain/entities/calendar_day.dart';

const _weekdayLabels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

/// A plain 7-column month grid, Sunday-first — [days] already arrives
/// padded to full weeks from the backend, so this widget just lays them out.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.days,
    required this.serverToday,
    required this.selectedDate,
    required this.onDaySelected,
  });

  final List<CalendarDay> days;
  final DateTime serverToday;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDaySelected;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: _weekdayLabels
              .map((label) => Expanded(child: Center(child: Text(label))))
              .toList(),
        ),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: days.map((day) {
            final isToday = _isSameDay(day.date, serverToday);
            final isSelected = selectedDate != null && _isSameDay(day.date, selectedDate!);
            return _DayCell(
              day: day,
              isToday: isToday,
              isSelected: isSelected,
              onTap: () => onDaySelected(day.date),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final CalendarDay day;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  /// Null performance renders blank — visually distinct from a scored 0%.
  /// Stepped bands, not a gradient — an abrupt color change at each cutoff
  /// makes it obvious which band a day is in at a glance.
  Color? get _backgroundColor {
    final performance = day.performance;
    if (performance == null) return null;
    if (performance < 20) return Colors.red.shade400;
    if (performance < 40) return Colors.orange.shade400;
    if (performance < 60) return Colors.yellow.shade600;
    if (performance < 80) return Colors.lightGreen.shade400;
    return Colors.green.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _backgroundColor,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            '${day.date.day}',
            style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ),
    );
  }
}
