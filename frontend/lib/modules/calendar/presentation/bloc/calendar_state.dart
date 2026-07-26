import 'package:equatable/equatable.dart';

import '../../domain/entities/calendar_day.dart';

enum CalendarStatus { initial, loading, loaded, error }

/// Per-task save status for the currently selected day's sliders. Keyed by
/// taskId — only one day is ever selected at a time.
enum OccurrenceSaveStatus { idle, saving, saved, error }

class CalendarState extends Equatable {
  const CalendarState({
    this.status = CalendarStatus.initial,
    this.errorMessage,
    this.serverToday,
    this.days = const [],
    this.selectedDate,
    this.saveStatuses = const {},
  });

  final CalendarStatus status;
  final String? errorMessage;
  final DateTime? serverToday;
  final List<CalendarDay> days;
  final DateTime? selectedDate;
  final Map<String, OccurrenceSaveStatus> saveStatuses;

  CalendarState copyWith({
    CalendarStatus? status,
    String? errorMessage,
    DateTime? serverToday,
    List<CalendarDay>? days,
    DateTime? selectedDate,
    Map<String, OccurrenceSaveStatus>? saveStatuses,
  }) {
    return CalendarState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      serverToday: serverToday ?? this.serverToday,
      days: days ?? this.days,
      selectedDate: selectedDate ?? this.selectedDate,
      saveStatuses: saveStatuses ?? this.saveStatuses,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    serverToday,
    days,
    selectedDate,
    saveStatuses,
  ];
}
