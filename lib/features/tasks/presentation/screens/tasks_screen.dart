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

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  List<TaskModel> tasks = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final parentContext = context;

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(hintText: 'Task title'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Task description',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final taskService = ref.read(taskServiceProvider);

                        await taskService.addTask(
                          title: titleController.text,
                          description: descriptionController.text,
                        );

                        // Refresh the list so the new task appears immediately
                        await fetchTasks();

                        titleController.clear();
                        descriptionController.clear();

                        if (!context.mounted) return;

                        Navigator.pop(context);

                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(content: Text('Task added')),
                        );
                      },
                      child: const Text('Add Task'),
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
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
                                setState(() {
                                  tasks[index] = TaskModel(
                                    id: task.id,
                                    title: task.title,
                                    description: task.description,
                                    isCompleted: value!,
                                  );
                                });

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
                                setState(() {
                                  tasks.removeAt(index);
                                });

                                final taskService = ref.read(
                                  taskServiceProvider,
                                );

                                await taskService.deleteTask(task.id);

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Task deleted')),
                                );
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
