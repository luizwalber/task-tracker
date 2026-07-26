import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import 'task_form_dialog.dart';

/// "Minhas tarefas" — lists every task, tapping one opens [TaskFormDialog]
/// pre-filled for editing. The only way to reach `TaskCubit.update` from
/// the UI, since the calendar day view only shows sliders, not a task list.
class TaskListDialog extends StatelessWidget {
  const TaskListDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final taskCubit = context.read<TaskCubit>();
    return AlertDialog(
      title: const Text('Minhas tarefas'),
      content: SizedBox(
        width: double.maxFinite,
        child: BlocBuilder<TaskCubit, TaskState>(
          bloc: taskCubit,
          builder: (context, state) {
            if (state is! TaskLoaded) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state.tasks.isEmpty) {
              return const Text('Nenhuma tarefa cadastrada ainda.');
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: state.tasks.length,
              itemBuilder: (context, index) {
                final task = state.tasks[index];
                return ListTile(
                  key: Key('task-list-item-${task.id}'),
                  title: Text(task.name),
                  subtitle: Text('Peso ${task.weight.toStringAsFixed(1)}'),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (dialogContext) => BlocProvider.value(
                        value: taskCubit,
                        child: TaskFormDialog(editingTask: task),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
