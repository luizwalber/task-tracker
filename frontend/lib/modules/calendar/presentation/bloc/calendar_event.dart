import 'package:equatable/equatable.dart';

sealed class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

class CalendarStarted extends CalendarEvent {
  const CalendarStarted();
}

class DaySelected extends CalendarEvent {
  const DaySelected(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

/// Fired on every slider tick during a drag — the bloc debounces internally
/// so the server only ever sees one call per drag stop.
class SliderDragged extends CalendarEvent {
  const SliderDragged({
    required this.taskId,
    required this.date,
    required this.percentage,
  });

  final String taskId;
  final DateTime date;
  final int percentage;

  @override
  List<Object?> get props => [taskId, date, percentage];
}

/// Internal — enqueued by the bloc itself once a drag's debounce window
/// elapses with no further ticks (or once to auto-retry a failed save).
/// Not dispatched by the UI directly.
class CommitOccurrence extends CalendarEvent {
  const CommitOccurrence({
    required this.taskId,
    required this.date,
    required this.percentage,
    this.isRetry = false,
  });

  final String taskId;
  final DateTime date;
  final int percentage;

  /// True when this is the single automatic retry after a failed save —
  /// caps retries at one attempt instead of retrying forever.
  final bool isRetry;

  @override
  List<Object?> get props => [taskId, date, percentage, isRetry];
}
