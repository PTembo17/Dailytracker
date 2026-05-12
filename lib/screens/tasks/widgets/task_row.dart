// task_row.dart — kept for compatibility but tasks_screen.dart inlines the row
// for reorderable list support. This file is retained for future use.
import 'package:flutter/material.dart';
import '../../../data/models/task.dart';

class TaskRow extends StatelessWidget {
  final Task task;
  final VoidCallback onDelete;

  const TaskRow({super.key, required this.task, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(task.name));
  }
}
