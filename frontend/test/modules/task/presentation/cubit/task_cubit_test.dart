import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/task/domain/entities/task.dart';
import 'package:frontend/modules/task/domain/repositories/task_repository.dart';
import 'package:frontend/modules/task/presentation/cubit/task_cubit.dart';
import 'package:frontend/modules/task/presentation/cubit/task_state.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository repository;

  final gym = Task(
    id: 't1',
    name: 'Gym',
    weight: 1,
    startsOn: DateTime(2026, 3, 1),
  );

  setUp(() {
    repository = MockTaskRepository();
  });

  blocTest<TaskCubit, TaskState>(
    'load() emits [TaskLoading, TaskLoaded] on success',
    setUp: () => when(() => repository.getTasks()).thenAnswer((_) async => [gym]),
    build: () => TaskCubit(repository),
    act: (cubit) => cubit.load(),
    expect: () => [const TaskLoading(), TaskLoaded([gym])],
  );

  blocTest<TaskCubit, TaskState>(
    'load() emits [TaskLoading, TaskError] on failure',
    setUp: () => when(() => repository.getTasks()).thenThrow(Exception('network down')),
    build: () => TaskCubit(repository),
    act: (cubit) => cubit.load(),
    expect: () => [const TaskLoading(), isA<TaskError>()],
  );

  blocTest<TaskCubit, TaskState>(
    'create() persists the task then reloads the list',
    setUp: () {
      when(
        () => repository.createTask(
          name: any(named: 'name'),
          weight: any(named: 'weight'),
          startsOn: any(named: 'startsOn'),
          endsOn: any(named: 'endsOn'),
        ),
      ).thenAnswer((_) async => gym);
      when(() => repository.getTasks()).thenAnswer((_) async => [gym]);
    },
    build: () => TaskCubit(repository),
    act: (cubit) => cubit.create(name: 'Gym', weight: 1, startsOn: DateTime(2026, 3, 1)),
    expect: () => [const TaskLoading(), TaskLoaded([gym])],
    verify: (_) {
      verify(
        () => repository.createTask(
          name: 'Gym',
          weight: 1,
          startsOn: DateTime(2026, 3, 1),
          endsOn: null,
        ),
      ).called(1);
    },
  );
}
