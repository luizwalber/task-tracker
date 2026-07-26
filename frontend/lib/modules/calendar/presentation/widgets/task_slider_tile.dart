import 'package:flutter/material.dart';

import '../../../task/domain/entities/task.dart';
import '../bloc/calendar_state.dart';

/// One task's 10%-step slider for the selected day. Dragging calls
/// [onChanged] on every tick — debouncing into a single autosave is the
/// bloc's job, not this widget's.
class TaskSliderTile extends StatelessWidget {
  const TaskSliderTile({
    super.key,
    required this.task,
    required this.percentage,
    required this.saveStatus,
    required this.onChanged,
  });

  final Task task;
  final int percentage;
  final OccurrenceSaveStatus saveStatus;
  final ValueChanged<int> onChanged;

  String get _statusLabel => switch (saveStatus) {
    OccurrenceSaveStatus.idle => '',
    OccurrenceSaveStatus.saving => 'salvando…',
    OccurrenceSaveStatus.saved => 'salvo',
    OccurrenceSaveStatus.error => 'erro ao salvar, tentando de novo',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(task.name)),
              Text('$percentage%'),
              if (_statusLabel.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    color: saveStatus == OccurrenceSaveStatus.error ? Colors.red : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          Slider(
            value: percentage.toDouble(),
            min: 0,
            max: 100,
            divisions: 10,
            label: '$percentage%',
            onChanged: (value) => onChanged(value.round()),
          ),
        ],
      ),
    );
  }
}
