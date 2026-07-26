import 'package:equatable/equatable.dart';

/// Recurrence is fixed to "every day" for this slice — the full
/// RecurrencePattern set lands in a later ticket.
class Task extends Equatable {
  const Task({
    required this.id,
    required this.name,
    required this.weight,
    required this.startsOn,
    this.endsOn,
  });

  final String id;
  final String name;
  final double weight;
  final DateTime startsOn;
  final DateTime? endsOn;

  bool occursOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    if (day.isBefore(_dateOnly(startsOn))) return false;
    if (endsOn != null && day.isAfter(_dateOnly(endsOn!))) return false;
    return true;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  List<Object?> get props => [id, name, weight, startsOn, endsOn];
}
