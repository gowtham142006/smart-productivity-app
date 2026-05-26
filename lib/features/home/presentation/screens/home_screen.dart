import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/dashboard_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    final email = user?.email ?? 'User';

    final username = email.split('@').first;
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Productivity App')),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 12),

              Text(
                'Hello $username 👋',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'Stay productive today',

                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 32),

              DashboardCard(
                title: 'AI Chat',

                subtitle: 'Ask anything instantly',

                icon: Icons.smart_toy,

                onTap: () {
                  context.go('/chat');
                },
              ),

              const SizedBox(height: 16),

              DashboardCard(
                title: 'Tasks',

                subtitle: 'Manage your daily tasks',

                icon: Icons.task,

                onTap: () {
                  context.go('/tasks');
                },
              ),

              const SizedBox(height: 16),

              DashboardCard(
                title: 'Notes',

                subtitle: 'Write and organize notes',

                icon: Icons.note,

                onTap: () {
                  context.go('/notes');
                },
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,

        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,

        backgroundColor: Colors.white,

        type: BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),

          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),

          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),

          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Notes'),
        ],
      ),
    );
  }
}
