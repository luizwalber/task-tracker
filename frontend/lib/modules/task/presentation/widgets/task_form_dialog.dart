import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/task.dart';
import '../cubit/task_cubit.dart';

/// Name, weight (0.5-2), start date and an optional end date — recurrence is
/// fixed to "every day" for this slice, so there is no pattern picker yet.
/// Doubles as the create and the edit form: pass [editingTask] to prefill
/// the fields and call `TaskCubit.update` on save instead of `create`.
class TaskFormDialog extends StatefulWidget {
  const TaskFormDialog({super.key, this.editingTask});

  final Task? editingTask;

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  late final TextEditingController _nameController;
  late double _weight;
  late DateTime _startsOn;
  DateTime? _endsOn;

  bool get _isEditing => widget.editingTask != null;

  @override
  void initState() {
    super.initState();
    final editingTask = widget.editingTask;
    _nameController = TextEditingController(text: editingTask?.name ?? '');
    _weight = editingTask?.weight ?? 1;
    _startsOn = editingTask?.startsOn ?? DateTime.now();
    _endsOn = editingTask?.endsOn;
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isEnd}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isEnd ? (_endsOn ?? _startsOn) : _startsOn,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => isEnd ? _endsOn = picked : _startsOn = picked);
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  void _save() {
    final taskCubit = context.read<TaskCubit>();
    if (_isEditing) {
      taskCubit.update(
        taskId: widget.editingTask!.id,
        name: _nameController.text.trim(),
        weight: _weight,
        startsOn: _startsOn,
        endsOn: _endsOn,
      );
    } else {
      taskCubit.create(
        name: _nameController.text.trim(),
        weight: _weight,
        startsOn: _startsOn,
        endsOn: _endsOn,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar tarefa' : 'Nova tarefa'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('task-name-field'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 16),
            Text('Peso: ${_weight.toStringAsFixed(1)}'),
            Slider(
              key: const Key('task-weight-slider'),
              value: _weight,
              min: 0.5,
              max: 2,
              divisions: 15,
              label: _weight.toStringAsFixed(1),
              onChanged: (value) => setState(() => _weight = value),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Início'),
              subtitle: Text(_formatDate(_startsOn)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(isEnd: false),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Término (opcional)'),
              subtitle: Text(_endsOn == null ? '—' : _formatDate(_endsOn!)),
              trailing: _endsOn == null
                  ? const Icon(Icons.calendar_today)
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _endsOn = null),
                    ),
              onTap: () => _pickDate(isEnd: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('save-task-button'),
          onPressed: _nameController.text.trim().isEmpty ? null : _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
