import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/task_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/task_provider.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

bool isLoading = false;

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final titleController = TextEditingController();

  final descriptionController = TextEditingController();

  List<TaskModel> tasks = [];

  @override
  void initState() {
    super.initState();

    fetchTasks();
  }

  Future<void> fetchTasks() async {
    setState(() {
      isLoading = true;
    });

    final taskService = ref.read(taskServiceProvider);

    final response = await taskService.getTasks();

    setState(() {
      tasks = response.map((task) => TaskModel.fromJson(task)).toList();

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller: titleController,

              decoration: const InputDecoration(hintText: 'Task title'),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: descriptionController,

              decoration: const InputDecoration(hintText: 'Task description'),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () async {
                final taskService = ref.read(taskServiceProvider);
                await taskService.addTask(
                  title: titleController.text,

                  description: descriptionController.text,
                );

                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Task added')));
                await fetchTasks();
                titleController.clear();

                descriptionController.clear(); // Refresh the task list
              },

              child: const Text('Add Task'),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : tasks.isEmpty
                  ? const Center(child: Text('No tasks yet'))
                  : ListView.builder(
                      itemCount: tasks.length,

                      itemBuilder: (context, index) {
                        final task = tasks[index];

                        return Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: task.isCompleted,

                              onChanged: (value) async {
                                final taskService = ref.read(
                                  taskServiceProvider,
                                );

                                await taskService.updateTaskStatus(
                                  task.id,
                                  value!,
                                );

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      value
                                          ? 'Task completed'
                                          : 'Task uncompleted',
                                    ),
                                  ),
                                );
                                await fetchTasks();
                              },
                            ),

                            title: Text(
                              task.title,

                              style: TextStyle(
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),

                            subtitle: Text(task.description),

                            trailing: IconButton(
                              icon: const Icon(Icons.delete),

                              onPressed: () async {
                                final taskService = ref.read(
                                  taskServiceProvider,
                                );

                                await taskService.deleteTask(task.id);

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Task deleted')),
                                );
                                await fetchTasks();
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
