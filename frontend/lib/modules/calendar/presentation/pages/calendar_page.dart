import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart' hide ModularStateX;

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../task/domain/entities/task.dart';
import '../../../task/presentation/cubit/task_cubit.dart';
import '../../../task/presentation/cubit/task_state.dart';
import '../../../task/presentation/widgets/task_form_dialog.dart';
import '../../../task/presentation/widgets/task_list_dialog.dart';
import '../../domain/entities/calendar_day.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';
import '../widgets/month_grid.dart';
import '../widgets/task_slider_tile.dart';

/// The app's main screen: this month's calendar with today selected, and —
/// once a day is picked — a slider per task expected that day, autosaving on
/// every drag stop.
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CalendarBloc>.value(
          value: inject<CalendarBloc>()..add(const CalendarStarted()),
        ),
        BlocProvider<TaskCubit>.value(value: inject<TaskCubit>()..load()),
      ],
      child: const CalendarView(),
    );
  }
}

/// The screen's content, separated from [CalendarPage]'s Modular DI wiring
/// so widget tests can pump it directly with real Blocs over fake
/// repositories, the same way login_page_test.dart does for AuthBloc.
class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracker Pessoal de Desempenho'),
        actions: [
          IconButton(
            key: const Key('list-tasks-button'),
            icon: const Icon(Icons.checklist),
            tooltip: 'Minhas tarefas',
            onPressed: () => showDialog(
              context: context,
              builder: (dialogContext) => BlocProvider.value(
                value: context.read<TaskCubit>(),
                child: const TaskListDialog(),
              ),
            ),
          ),
          IconButton(
            key: const Key('add-task-button'),
            icon: const Icon(Icons.add_task),
            tooltip: 'Nova tarefa',
            onPressed: () => showDialog(
              context: context,
              builder: (dialogContext) => BlocProvider.value(
                value: context.read<TaskCubit>(),
                child: const TaskFormDialog(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
      body: BlocBuilder<TaskCubit, TaskState>(
        builder: (context, taskState) => BlocBuilder<CalendarBloc, CalendarState>(
          builder: (context, state) => switch (state.status) {
            CalendarStatus.initial || CalendarStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            CalendarStatus.error => Center(
              child: Text('Falha ao carregar o calendário: ${state.errorMessage}'),
            ),
            CalendarStatus.loaded => _CalendarLoadedBody(
              state: state,
              tasks: taskState is TaskLoaded ? taskState.tasks : const [],
              isSameDay: _isSameDay,
            ),
          },
        ),
      ),
    );
  }
}

class _CalendarLoadedBody extends StatelessWidget {
  const _CalendarLoadedBody({
    required this.state,
    required this.tasks,
    required this.isSameDay,
  });

  final CalendarState state;
  final List<Task> tasks;
  final bool Function(DateTime, DateTime) isSameDay;

  @override
  Widget build(BuildContext context) {
    final selectedDate = state.selectedDate;
    final selectedDay = selectedDate == null
        ? null
        : state.days.firstWhere(
            (d) => isSameDay(d.date, selectedDate),
            orElse: () => CalendarDay(date: selectedDate, performance: null, occurrences: const []),
          );
    final expectedTasks = selectedDay == null
        ? const <Task>[]
        : tasks.where((t) => t.occursOn(selectedDay.date)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        MonthGrid(
          days: state.days,
          serverToday: state.serverToday!,
          selectedDate: state.selectedDate,
          onDaySelected: (date) =>
              context.read<CalendarBloc>().add(DaySelected(date)),
        ),
        const SizedBox(height: 24),
        if (selectedDay != null) ...[
          Text(
            'Tarefas do dia',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (expectedTasks.isEmpty) const Text('Nenhuma tarefa esperada neste dia.'),
          ...expectedTasks.map((task) {
            final matchingOccurrences = selectedDay.occurrences.where(
              (o) => o.taskId == task.id,
            );
            final percentage = matchingOccurrences.isEmpty
                ? 0
                : matchingOccurrences.first.percentage;
            return TaskSliderTile(
              key: Key('task-slider-${task.id}'),
              task: task,
              percentage: percentage,
              saveStatus: state.saveStatuses[task.id] ?? OccurrenceSaveStatus.idle,
              onChanged: (value) => context.read<CalendarBloc>().add(
                SliderDragged(taskId: task.id, date: selectedDay.date, percentage: value),
              ),
            );
          }),
        ],
      ],
    );
  }
}
