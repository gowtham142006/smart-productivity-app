import 'package:supabase_flutter/supabase_flutter.dart';

class TaskService {
  final supabase = Supabase.instance.client;

  Future<void> addTask({
    required String title,
    required String description,
  }) async {
    final user = supabase.auth.currentUser;

    await supabase.from('tasks').insert({
      'title': title,

      'description': description,

      'is_completed': false,

      'user_id': user!.id,
    });
  }

  Future<List<dynamic>> getTasks() async {
    final user = supabase.auth.currentUser;

    final response = await supabase
        .from('tasks')
        .select()
        .eq('user_id', user!.id);

    return response;
  }

  Future<void> deleteTask(String taskId) async {
    await supabase.from('tasks').delete().eq('id', taskId);
  }

  Future<void> updateTaskStatus(String taskId, bool isCompleted) async {
    await supabase
        .from('tasks')
        .update({'is_completed': isCompleted})
        .eq('id', taskId);
  }
}
