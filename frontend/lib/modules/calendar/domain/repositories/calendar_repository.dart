import '../entities/calendar_month.dart';

abstract class CalendarRepository {
  Future<CalendarMonth> getMonth(int year, int month);
}
