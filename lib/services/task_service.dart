import 'package:supabase_flutter/supabase_flutter.dart';

class TaskService {
  final SupabaseClient _client;
  TaskService(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> getTasks({
    bool? isCompleted,
    String? priority,
    String? categoryId,
    String orderBy = 'created_at',
    bool ascending = false,
  }) async {
    if (_userId == null) return [];

    var query = _client.from('tasks').select().eq('user_id', _userId!);

    if (isCompleted != null) {
      query = query.eq('is_completed', isCompleted);
    }
    if (priority != null) {
      query = query.eq('priority', priority);
    }
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    return await query.order(orderBy, ascending: ascending);
  }

  Future<void> addTask({
    required String title,
    String description = '',
    String priority = 'medium',
    String? categoryId,
    DateTime? dueDate,
  }) async {
    if (_userId == null) return;

    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'is_completed': false,
      'priority': priority,
      'user_id': _userId,
    };

    if (categoryId != null) data['category_id'] = categoryId;
    if (dueDate != null) data['due_date'] = dueDate.toIso8601String();

    await _client.from('tasks').insert(data);
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
    final updates = <String, dynamic>{};

    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (priority != null) updates['priority'] = priority;
    if (isCompleted != null) updates['is_completed'] = isCompleted;

    if (clearCategory) {
      updates['category_id'] = null;
    } else if (categoryId != null) {
      updates['category_id'] = categoryId;
    }

    if (clearDueDate) {
      updates['due_date'] = null;
    } else if (dueDate != null) {
      updates['due_date'] = dueDate.toIso8601String();
    }

    if (updates.isNotEmpty) {
      await _client.from('tasks').update(updates).eq('id', taskId);
    }
  }

  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }

  Future<void> updateTaskStatus(String taskId, bool isCompleted) async {
    await _client
        .from('tasks')
        .update({'is_completed': isCompleted})
        .eq('id', taskId);
  }
}
