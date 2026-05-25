import 'package:flutter/material.dart';
import '../../../../services/task_service.dart';
import '../../data/task_model.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final titleController = TextEditingController();

  final descriptionController = TextEditingController();

  final taskService = TaskService();

  List<TaskModel> tasks = [];

  @override
  void initState() {
    super.initState();

    fetchTasks();
  }

  Future<void> fetchTasks() async {
    final response = await taskService.getTasks();

    setState(() {
      tasks = response.map((task) => TaskModel.fromJson(task)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
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
                await taskService.addTask(
                  title: titleController.text,

                  description: descriptionController.text,
                );
                await fetchTasks();
                titleController.clear();

                descriptionController.clear(); // Refresh the task list
              },

              child: const Text('Add Task'),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,

                itemBuilder: (context, index) {
                  final task = tasks[index];

                  return Card(
                    child: ListTile(
                      title: Text(task.title),

                      subtitle: Text(task.description),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),

                        onPressed: () async {
                          await taskService.deleteTask(task.id);

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
