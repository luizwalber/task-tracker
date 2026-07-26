import 'package:equatable/equatable.dart';

import '../../domain/entities/task.dart';

sealed class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {
  const TaskInitial();
}

class TaskLoading extends TaskState {
  const TaskLoading();
}

class TaskLoaded extends TaskState {
  const TaskLoaded(this.tasks);

  final List<Task> tasks;

  @override
  List<Object?> get props => [tasks];
}

class TaskError extends TaskState {
  const TaskError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
