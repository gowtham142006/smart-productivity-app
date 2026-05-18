import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Productivity App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AI Productivity App'),
        ),
        body: const Center(
          child: Text(
            'Welcome to AI Productivity App',
          ),
        ),
      ),
    );
  }
}