import 'package:equatable/equatable.dart';

class UpsertOccurrenceResult extends Equatable {
  const UpsertOccurrenceResult({
    required this.taskId,
    required this.date,
    required this.percentage,
    required this.dayPerformance,
  });

  final String taskId;
  final DateTime date;
  final int percentage;
  final double? dayPerformance;

  @override
  List<Object?> get props => [taskId, date, percentage, dayPerformance];
}
