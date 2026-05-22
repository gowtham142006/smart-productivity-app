import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/dashboard_card.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Productivity App')),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hello Gowtham 👋', style: AppTextStyles.heading),

              const Text(
                'Stay productive today',
                style: AppTextStyles.subtitle,
              ),

              const SizedBox(height: 24),

              DashboardCard(
                title: 'AI Chat',
                subtitle: 'Ask anything instantly',
                icon: Icons.chat,
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
              CustomButton(
                text: 'Go to Login',
                onPressed: () {
                  context.go('/login');
                },
              ),
              TextButton(
                onPressed: () {
                  context.go('/signup');
                },

                child: const Text('Create an account'),
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
