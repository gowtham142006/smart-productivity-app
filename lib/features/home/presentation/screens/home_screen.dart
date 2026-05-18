import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Productivity App')),

      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.go('/chat');
          },
          child: const Text('Go to Chat'),
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
