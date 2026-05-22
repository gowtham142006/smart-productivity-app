import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/tasks/presentation/screens/tasks_screen.dart';
import '../features/notes/presentation/screens/notes_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),

    GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),

    GoRoute(path: '/tasks', builder: (context, state) => const TasksScreen()),

    GoRoute(path: '/notes', builder: (context, state) => const NotesScreen()),
  ],
);
