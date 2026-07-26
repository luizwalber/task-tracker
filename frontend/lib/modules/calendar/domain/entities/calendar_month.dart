import 'package:equatable/equatable.dart';

import 'calendar_day.dart';

class CalendarMonth extends Equatable {
  const CalendarMonth({required this.serverToday, required this.days});

  final DateTime serverToday;
  final List<CalendarDay> days;

  @override
  List<Object?> get props => [serverToday, days];
}
