import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/modules/auth/presentation/bloc/auth_bloc.dart';
import 'package:frontend/modules/calendar/domain/entities/calendar_day.dart';
import 'package:frontend/modules/calendar/domain/entities/calendar_month.dart';
import 'package:frontend/modules/calendar/domain/entities/upsert_occurrence_result.dart';
import 'package:frontend/modules/calendar/domain/repositories/calendar_repository.dart';
import 'package:frontend/modules/calendar/domain/repositories/occurrence_repository.dart';
import 'package:frontend/modules/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:frontend/modules/calendar/presentation/bloc/calendar_event.dart';
import 'package:frontend/modules/calendar/presentation/pages/calendar_page.dart';
import 'package:frontend/modules/task/domain/entities/task.dart';
import 'package:frontend/modules/task/domain/repositories/task_repository.dart';
import 'package:frontend/modules/task/presentation/cubit/task_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCalendarRepository extends Mock implements CalendarRepository {}

class MockTaskRepository extends Mock implements TaskRepository {}

class MockOccurrenceRepository extends Mock implements OccurrenceRepository {}

void main() {
  final today = DateTime(2026, 3, 10);
  final gym = Task(id: 't1', name: 'Gym', weight: 1, startsOn: DateTime(2026, 3, 1));

  late MockAuthRepository authRepository;
  late MockCalendarRepository calendarRepository;
  late MockTaskRepository taskRepository;
  late MockOccurrenceRepository occurrenceRepository;

  setUp(() {
    authRepository = MockAuthRepository();
    calendarRepository = MockCalendarRepository();
    taskRepository = MockTaskRepository();
    occurrenceRepository = MockOccurrenceRepository();

    when(() => calendarRepository.getMonth(any(), any())).thenAnswer(
      (_) async => CalendarMonth(
        serverToday: today,
        days: [CalendarDay(date: today, performance: null, occurrences: const [])],
      ),
    );
    when(() => taskRepository.getTasks()).thenAnswer((_) async => [gym]);
  });

  Widget pump() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(create: (_) => AuthBloc(authRepository)),
          BlocProvider<CalendarBloc>(
            create: (_) =>
                CalendarBloc(calendarRepository, occurrenceRepository)
                  ..add(const CalendarStarted()),
          ),
          BlocProvider<TaskCubit>(create: (_) => TaskCubit(taskRepository)..load()),
        ],
        child: const CalendarView(),
      ),
    );
  }

  testWidgets(
    'golden path: selecting today shows the expected task slider, and dragging it autosaves',
    (tester) async {
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

      await tester.pumpWidget(pump());
      await tester.pumpAndSettle();

      expect(find.text('Gym'), findsOneWidget);

      final slider = tester.widget<Slider>(find.byType(Slider));
      slider.onChanged!(80);
      await tester.pump(CalendarBloc.debounceDuration + const Duration(milliseconds: 100));

      verify(
        () => occurrenceRepository.upsert(taskId: 't1', date: today, percentage: 80),
      ).called(1);
    },
  );
}
