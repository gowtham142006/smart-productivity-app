import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/tasks/presentation/screens/tasks_screen.dart';
import '../features/notes/presentation/screens/notes_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),

    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

    GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),

    GoRoute(path: '/tasks', builder: (context, state) => const TasksScreen()),

    GoRoute(path: '/notes', builder: (context, state) => const NotesScreen()),
  ],
);
