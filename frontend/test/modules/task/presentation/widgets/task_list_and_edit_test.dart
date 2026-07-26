import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/task/domain/entities/task.dart';
import 'package:frontend/modules/task/domain/repositories/task_repository.dart';
import 'package:frontend/modules/task/presentation/cubit/task_cubit.dart';
import 'package:frontend/modules/task/presentation/widgets/task_list_dialog.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository repository;
  late TaskCubit taskCubit;

  final gym = Task(id: 't1', name: 'Gym', weight: 1, startsOn: DateTime(2026, 3, 1));

  setUp(() {
    repository = MockTaskRepository();
    taskCubit = TaskCubit(repository);
    when(() => repository.getTasks()).thenAnswer((_) async => [gym]);
    when(
      () => repository.updateTask(
        taskId: any(named: 'taskId'),
        name: any(named: 'name'),
        weight: any(named: 'weight'),
        startsOn: any(named: 'startsOn'),
        endsOn: any(named: 'endsOn'),
      ),
    ).thenAnswer((_) async => gym);
  });

  testWidgets(
    'golden path: opening the task list and editing a task calls TaskCubit.update, '
    'the only UI entry point that reaches it',
    (tester) async {
      await taskCubit.load();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TaskCubit>.value(
            value: taskCubit,
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (dialogContext) => BlocProvider.value(
                        value: taskCubit,
                        child: const TaskListDialog(),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Gym'), findsOneWidget);

      await tester.tap(find.byKey(const Key('task-list-item-t1')));
      await tester.pumpAndSettle();

      expect(find.text('Editar tarefa'), findsOneWidget);
      final nameField = tester.widget<TextField>(find.byKey(const Key('task-name-field')));
      expect(nameField.controller!.text, 'Gym');

      await tester.enterText(find.byKey(const Key('task-name-field')), 'Gym 5x');
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      verify(
        () => repository.updateTask(
          taskId: 't1',
          name: 'Gym 5x',
          weight: 1,
          startsOn: gym.startsOn,
          endsOn: null,
        ),
      ).called(1);
    },
  );
}
