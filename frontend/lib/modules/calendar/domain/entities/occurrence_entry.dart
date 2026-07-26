import 'package:equatable/equatable.dart';

class OccurrenceEntry extends Equatable {
  const OccurrenceEntry({required this.taskId, required this.percentage});

  final String taskId;
  final int percentage;

  @override
  List<Object?> get props => [taskId, percentage];
}
