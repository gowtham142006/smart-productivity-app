import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/task_model.dart';
import '../../../core/providers/core_providers.dart';

// ─── Task Filter State ─────────────────────────────

class TaskFilter {
  final bool? showCompleted;
  final String? priority;
  final String? categoryId;
  final String sortBy;

  const TaskFilter({
    this.showCompleted,
    this.priority,
    this.categoryId,
    this.sortBy = 'created_at',
  });

  TaskFilter copyWith({
    bool? showCompleted,
    String? priority,
    String? categoryId,
    String? sortBy,
    bool clearPriority = false,
    bool clearCategory = false,
    bool clearCompleted = false,
  }) {
    return TaskFilter(
      showCompleted: clearCompleted ? null : (showCompleted ?? this.showCompleted),
      priority: clearPriority ? null : (priority ?? this.priority),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class TaskFilterNotifier extends Notifier<TaskFilter> {
  @override
  TaskFilter build() => const TaskFilter();

  void setPriority(String? priority) {
    if (priority == null) {
      state = state.copyWith(clearPriority: true);
    } else {
      state = state.copyWith(priority: priority);
    }
  }

  void setCategory(String? categoryId) {
    if (categoryId == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(categoryId: categoryId);
    }
  }

  void setShowCompleted(bool? show) {
    if (show == null) {
      state = state.copyWith(clearCompleted: true);
    } else {
      state = state.copyWith(showCompleted: show);
    }
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void clearAll() {
    state = const TaskFilter();
  }
}

final taskFilterProvider =
    NotifierProvider<TaskFilterNotifier, TaskFilter>(TaskFilterNotifier.new);

// ─── Task List (AsyncNotifier) ─────────────────────

class TaskListNotifier extends AsyncNotifier<List<TaskModel>> {
  @override
  Future<List<TaskModel>> build() async {
    final service = ref.watch(taskServiceProvider);
    final filters = ref.watch(taskFilterProvider);

    final data = await service.getTasks(
      isCompleted: filters.showCompleted,
      priority: filters.priority,
      categoryId: filters.categoryId,
      orderBy: filters.sortBy,
    );

    return data.map((e) => TaskModel.fromJson(e)).toList();
  }

  Future<void> addTask({
    required String title,
    String description = '',
    String priority = 'medium',
    String? categoryId,
    DateTime? dueDate,
  }) async {
    final service = ref.read(taskServiceProvider);
    await service.addTask(
      title: title,
      description: description,
      priority: priority,
      categoryId: categoryId,
      dueDate: dueDate,
    );
    ref.invalidateSelf();
  }

  Future<void> toggleComplete(String taskId, bool isCompleted) async {
    // Optimistic update
    final previous = state.value ?? [];
    state = AsyncData(
      previous.map((t) {
        if (t.id == taskId) return t.copyWith(isCompleted: isCompleted);
        return t;
      }).toList(),
    );

    try {
      final service = ref.read(taskServiceProvider);
      await service.updateTaskStatus(taskId, isCompleted);
    } catch (e) {
      // Revert on failure
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    // Optimistic update
    final previous = state.value ?? [];
    state = AsyncData(previous.where((t) => t.id != taskId).toList());

    try {
      final service = ref.read(taskServiceProvider);
      await service.deleteTask(taskId);
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? priority,
    String? categoryId,
    DateTime? dueDate,
    bool? isCompleted,
    bool clearDueDate = false,
    bool clearCategory = false,
  }) async {
    final service = ref.read(taskServiceProvider);
    await service.updateTask(
      taskId: taskId,
      title: title,
      description: description,
      priority: priority,
      categoryId: categoryId,
      dueDate: dueDate,
      isCompleted: isCompleted,
      clearDueDate: clearDueDate,
      clearCategory: clearCategory,
    );
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final taskListProvider =
    AsyncNotifierProvider<TaskListNotifier, List<TaskModel>>(
  TaskListNotifier.new,
);

// ─── Derived Providers ─────────────────────────────

final overdueTasksCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(taskListProvider).value ?? [];
  final now = DateTime.now();
  return tasks
      .where((t) =>
          t.dueDate != null && t.dueDate!.isBefore(now) && !t.isCompleted)
      .length;
});

final todayTasksCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(taskListProvider).value ?? [];
  final now = DateTime.now();
  return tasks
      .where((t) =>
          t.dueDate != null &&
          t.dueDate!.year == now.year &&
          t.dueDate!.month == now.month &&
          t.dueDate!.day == now.day)
      .length;
});

final completedTasksCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(taskListProvider).value ?? [];
  return tasks.where((t) => t.isCompleted).length;
});

final pendingTasksCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(taskListProvider).value ?? [];
  return tasks.where((t) => !t.isCompleted).length;
});
