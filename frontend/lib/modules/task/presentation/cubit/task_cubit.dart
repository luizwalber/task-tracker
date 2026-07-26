import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/task_repository.dart';
import 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  TaskCubit(this._taskRepository) : super(const TaskInitial());

  final TaskRepository _taskRepository;

  Future<void> load() async {
    emit(const TaskLoading());
    try {
      final tasks = await _taskRepository.getTasks();
      emit(TaskLoaded(tasks));
    } catch (error) {
      emit(TaskError(error.toString()));
    }
  }

  Future<void> create({
    required String name,
    required double weight,
    required DateTime startsOn,
    DateTime? endsOn,
  }) async {
    await _taskRepository.createTask(
      name: name,
      weight: weight,
      startsOn: startsOn,
      endsOn: endsOn,
    );
    await load();
  }

  Future<void> update({
    required String taskId,
    String? name,
    double? weight,
    DateTime? startsOn,
    DateTime? endsOn,
  }) async {
    await _taskRepository.updateTask(
      taskId: taskId,
      name: name,
      weight: weight,
      startsOn: startsOn,
      endsOn: endsOn,
    );
    await load();
  }
}
