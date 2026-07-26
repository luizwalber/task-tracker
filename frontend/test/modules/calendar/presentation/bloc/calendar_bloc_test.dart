import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/calendar/domain/entities/calendar_day.dart';
import 'package:frontend/modules/calendar/domain/entities/calendar_month.dart';
import 'package:frontend/modules/calendar/domain/entities/upsert_occurrence_result.dart';
import 'package:frontend/modules/calendar/domain/repositories/calendar_repository.dart';
import 'package:frontend/modules/calendar/domain/repositories/occurrence_repository.dart';
import 'package:frontend/modules/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:frontend/modules/calendar/presentation/bloc/calendar_event.dart';
import 'package:frontend/modules/calendar/presentation/bloc/calendar_state.dart';
import 'package:mocktail/mocktail.dart';

class MockCalendarRepository extends Mock implements CalendarRepository {}

class MockOccurrenceRepository extends Mock implements OccurrenceRepository {}

void main() {
  late MockCalendarRepository calendarRepository;
  late MockOccurrenceRepository occurrenceRepository;

  final today = DateTime(2026, 3, 10);
  final month = CalendarMonth(
    serverToday: today,
    days: [CalendarDay(date: today, performance: null, occurrences: const [])],
  );

  setUp(() {
    calendarRepository = MockCalendarRepository();
    occurrenceRepository = MockOccurrenceRepository();
  });

  CalendarBloc buildBloc() => CalendarBloc(calendarRepository, occurrenceRepository);

  blocTest<CalendarBloc, CalendarState>(
    'CalendarStarted loads the current month, selecting serverToday',
    setUp: () {
      when(() => calendarRepository.getMonth(any(), any())).thenAnswer((_) async => month);
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const CalendarStarted()),
    expect: () => [
      const CalendarState(status: CalendarStatus.loading),
      CalendarState(
        status: CalendarStatus.loaded,
        serverToday: today,
        days: month.days,
        selectedDate: today,
      ),
    ],
  );

  blocTest<CalendarBloc, CalendarState>(
    'refetches using the server month when the device clock guessed a different month '
    '(never trusts the device clock for what is actually rendered)',
    setUp: () {
      var callCount = 0;
      when(() => calendarRepository.getMonth(any(), any())).thenAnswer((_) async {
        callCount++;
        // First response deliberately disagrees with whatever the device's
        // real "now" is, forcing a mismatch and a second, corrected fetch.
        if (callCount == 1) {
          return CalendarMonth(serverToday: DateTime(2099, 1, 1), days: const []);
        }
        return month;
      });
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const CalendarStarted()),
    expect: () => [
      const CalendarState(status: CalendarStatus.loading),
      CalendarState(
        status: CalendarStatus.loaded,
        serverToday: today,
        days: month.days,
        selectedDate: today,
      ),
    ],
    verify: (_) {
      verify(() => calendarRepository.getMonth(any(), any())).called(2);
    },
  );

  blocTest<CalendarBloc, CalendarState>(
    'a slider drag debounces into a single upsert call and marks the day saved',
    setUp: () {
      when(
        () => occurrenceRepository.upsert(
          taskId: any(named: 'taskId'),
          date: any(named: 'date'),
          percentage: any(named: 'percentage'),
        ),
      ).thenAnswer(
        (_) async => UpsertOccurrenceResult(
          taskId: 't1',
          date: today,
          percentage: 80,
          dayPerformance: 80,
        ),
      );
    },
    build: buildBloc,
    seed: () => CalendarState(
      status: CalendarStatus.loaded,
      serverToday: today,
      days: [CalendarDay(date: today, performance: null, occurrences: const [])],
      selectedDate: today,
    ),
    act: (bloc) async {
      bloc.add(SliderDragged(taskId: 't1', date: today, percentage: 50));
      bloc.add(SliderDragged(taskId: 't1', date: today, percentage: 80));
      await Future.delayed(CalendarBloc.debounceDuration + const Duration(milliseconds: 100));
    },
    verify: (_) {
      verify(
        () => occurrenceRepository.upsert(taskId: 't1', date: today, percentage: 80),
      ).called(1); // only the final value after the drag stops, never one call per tick
    },
    expect: () => [
      isA<CalendarState>().having(
        (s) => s.days.first.occurrences.single.percentage,
        'optimistic percentage',
        50,
      ),
      isA<CalendarState>().having(
        (s) => s.days.first.occurrences.single.percentage,
        'optimistic percentage after second tick',
        80,
      ),
      isA<CalendarState>().having(
        (s) => s.saveStatuses['t1'],
        'save status',
        OccurrenceSaveStatus.saved,
      ),
    ],
  );

  blocTest<CalendarBloc, CalendarState>(
    'a failed save keeps the dragged value and marks the status as error',
    setUp: () {
      when(
        () => occurrenceRepository.upsert(
          taskId: any(named: 'taskId'),
          date: any(named: 'date'),
          percentage: any(named: 'percentage'),
        ),
      ).thenThrow(Exception('network down'));
    },
    build: buildBloc,
    seed: () => CalendarState(
      status: CalendarStatus.loaded,
      serverToday: today,
      days: [CalendarDay(date: today, performance: null, occurrences: const [])],
      selectedDate: today,
    ),
    act: (bloc) async {
      bloc.add(SliderDragged(taskId: 't1', date: today, percentage: 60));
      await Future.delayed(CalendarBloc.debounceDuration + const Duration(milliseconds: 100));
    },
    expect: () => [
      isA<CalendarState>().having(
        (s) => s.days.first.occurrences.single.percentage,
        'optimistic percentage',
        60,
      ),
      isA<CalendarState>().having(
        (s) => s.saveStatuses['t1'],
        'save status',
        OccurrenceSaveStatus.error,
      ),
    ],
    verify: (bloc) {
      expect(bloc.state.days.first.occurrences.single.percentage, 60); // never reverted
    },
  );

  blocTest<CalendarBloc, CalendarState>(
    'automatically retries once after a failed save, and marks it saved if the retry succeeds',
    setUp: () {
      var attempt = 0;
      when(
        () => occurrenceRepository.upsert(
          taskId: any(named: 'taskId'),
          date: any(named: 'date'),
          percentage: any(named: 'percentage'),
        ),
      ).thenAnswer((_) async {
        attempt++;
        if (attempt == 1) throw Exception('network down');
        return UpsertOccurrenceResult(
          taskId: 't1',
          date: today,
          percentage: 90,
          dayPerformance: 90,
        );
      });
    },
    build: buildBloc,
    seed: () => CalendarState(
      status: CalendarStatus.loaded,
      serverToday: today,
      days: [CalendarDay(date: today, performance: null, occurrences: const [])],
      selectedDate: today,
    ),
    act: (bloc) async {
      bloc.add(SliderDragged(taskId: 't1', date: today, percentage: 90));
      await Future.delayed(
        CalendarBloc.debounceDuration + CalendarBloc.retryDelay + const Duration(milliseconds: 200),
      );
    },
    verify: (_) {
      verify(
        () => occurrenceRepository.upsert(taskId: 't1', date: today, percentage: 90),
      ).called(2); // the original attempt, plus exactly one automatic retry
    },
    expect: () => [
      isA<CalendarState>().having(
        (s) => s.saveStatuses['t1'],
        'optimistic save status',
        OccurrenceSaveStatus.saving,
      ),
      isA<CalendarState>().having(
        (s) => s.saveStatuses['t1'],
        'save status after the first failure',
        OccurrenceSaveStatus.error,
      ),
      isA<CalendarState>().having(
        (s) => s.saveStatuses['t1'],
        'save status after the automatic retry succeeds',
        OccurrenceSaveStatus.saved,
      ),
    ],
  );
}
