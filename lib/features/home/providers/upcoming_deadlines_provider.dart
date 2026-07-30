import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tasks/providers/task_provider.dart';
import '../../tasks/data/task_model.dart';

/// Derived provider: next 5 upcoming tasks sorted by due date.
/// Only includes incomplete tasks with a due date set.
final upcomingDeadlinesProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(allTasksProvider).value ?? [];

  final upcoming = tasks
      .where((t) => !t.isCompleted && t.dueDate != null)
      .toList()
    ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

  return upcoming.take(5).toList();
});
