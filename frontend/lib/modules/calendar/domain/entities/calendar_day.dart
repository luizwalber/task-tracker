import 'package:equatable/equatable.dart';

import 'occurrence_entry.dart';

class CalendarDay extends Equatable {
  const CalendarDay({
    required this.date,
    required this.performance,
    required this.occurrences,
  });

  /// Null means the day has no scoreable task filled in yet — visually blank,
  /// distinct from a 0% day.
  final DateTime date;
  final double? performance;
  final List<OccurrenceEntry> occurrences;

  CalendarDay copyWith({double? performance, List<OccurrenceEntry>? occurrences}) {
    return CalendarDay(
      date: date,
      performance: performance ?? this.performance,
      occurrences: occurrences ?? this.occurrences,
    );
  }

  @override
  List<Object?> get props => [date, performance, occurrences];
}
