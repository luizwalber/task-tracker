import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/calendar_day.dart';
import '../../domain/entities/occurrence_entry.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/occurrence_repository.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  CalendarBloc(this._calendarRepository, this._occurrenceRepository)
    : super(const CalendarState()) {
    on<CalendarStarted>(_onStarted);
    on<DaySelected>(_onDaySelected);
    on<SliderDragged>(_onSliderDragged);
    on<CommitOccurrence>(_onCommitOccurrence);
  }

  final CalendarRepository _calendarRepository;
  final OccurrenceRepository _occurrenceRepository;

  static const debounceDuration = Duration(milliseconds: 400);
  static const retryDelay = Duration(milliseconds: 400);
  final Map<String, Timer> _debounceTimers = {};

  @override
  Future<void> close() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    return super.close();
  }

  Future<void> _onStarted(
    CalendarStarted event,
    Emitter<CalendarState> emit,
  ) async {
    emit(state.copyWith(status: CalendarStatus.loading));
    try {
      // The device clock only seeds the very first network call — the app
      // never trusts it for what's actually rendered. If the server's
      // `serverToday` lands in a different month (device/server clock or
      // timezone drift), the month is refetched using the server's own
      // month so "today" is always guaranteed to be on-screen.
      final deviceGuess = DateTime.now();
      var month = await _calendarRepository.getMonth(deviceGuess.year, deviceGuess.month);
      if (month.serverToday.year != deviceGuess.year ||
          month.serverToday.month != deviceGuess.month) {
        month = await _calendarRepository.getMonth(
          month.serverToday.year,
          month.serverToday.month,
        );
      }
      emit(
        state.copyWith(
          status: CalendarStatus.loaded,
          serverToday: month.serverToday,
          days: month.days,
          selectedDate: month.serverToday,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: CalendarStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onDaySelected(DaySelected event, Emitter<CalendarState> emit) {
    emit(state.copyWith(selectedDate: event.date, saveStatuses: const {}));
  }

  void _onSliderDragged(SliderDragged event, Emitter<CalendarState> emit) {
    emit(
      state.copyWith(
        days: _withOccurrence(state.days, event.date, event.taskId, event.percentage),
        saveStatuses: _withStatus(state.saveStatuses, event.taskId, OccurrenceSaveStatus.saving),
      ),
    );

    final key = '${event.taskId}|${_dateKey(event.date)}';
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(debounceDuration, () {
      if (!isClosed) {
        add(
          CommitOccurrence(
            taskId: event.taskId,
            date: event.date,
            percentage: event.percentage,
          ),
        );
      }
    });
  }

  Future<void> _onCommitOccurrence(
    CommitOccurrence event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      final result = await _occurrenceRepository.upsert(
        taskId: event.taskId,
        date: event.date,
        percentage: event.percentage,
      );
      emit(
        state.copyWith(
          days: _withDayPerformance(state.days, result.date, result.dayPerformance),
          saveStatuses: _withStatus(state.saveStatuses, event.taskId, OccurrenceSaveStatus.saved),
        ),
      );
    } catch (_) {
      // The dragged value stays in state.days (set optimistically in
      // _onSliderDragged) — a failed save never discards what the user set.
      emit(
        state.copyWith(
          saveStatuses: _withStatus(state.saveStatuses, event.taskId, OccurrenceSaveStatus.error),
        ),
      );
      // One automatic retry, matching the documented "erro, tentando de
      // novo" flow — capped at a single attempt so a persistently down
      // network doesn't retry forever; the next drag starts a fresh attempt.
      if (!event.isRetry) {
        Timer(retryDelay, () {
          if (!isClosed) {
            add(
              CommitOccurrence(
                taskId: event.taskId,
                date: event.date,
                percentage: event.percentage,
                isRetry: true,
              ),
            );
          }
        });
      }
    }
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static Map<String, OccurrenceSaveStatus> _withStatus(
    Map<String, OccurrenceSaveStatus> statuses,
    String taskId,
    OccurrenceSaveStatus status,
  ) {
    return {...statuses, taskId: status};
  }

  static List<CalendarDay> _withOccurrence(
    List<CalendarDay> days,
    DateTime date,
    String taskId,
    int percentage,
  ) {
    return days.map((day) {
      if (!_isSameDay(day.date, date)) return day;
      final occurrences = [
        ...day.occurrences.where((o) => o.taskId != taskId),
        OccurrenceEntry(taskId: taskId, percentage: percentage),
      ];
      return day.copyWith(occurrences: occurrences);
    }).toList();
  }

  static List<CalendarDay> _withDayPerformance(
    List<CalendarDay> days,
    DateTime date,
    double? performance,
  ) {
    return days.map((day) {
      if (!_isSameDay(day.date, date)) return day;
      return CalendarDay(
        date: day.date,
        performance: performance,
        occurrences: day.occurrences,
      );
    }).toList();
  }
}
