import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/tasks/presentation/screens/tasks_screen.dart';
import '../features/notes/presentation/screens/notes_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/calendar/presentation/screens/calendar_screen.dart';
import '../features/habits/presentation/screens/habits_screen.dart';
import '../features/pomodoro/presentation/screens/pomodoro_screen.dart';
import '../features/analytics/presentation/screens/analytics_screen.dart';
import '../features/notifications/presentation/screens/notification_history_screen.dart';
import 'shell_scaffold.dart';

/// Converts a Supabase auth state [Stream] into a [Listenable]
/// so GoRouter re-evaluates its redirect whenever the session changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners(); // initial evaluation
    _subscription = stream.asBroadcastStream().listen((authState) {
      if (authState.event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
      } else if (authState.event == AuthChangeEvent.signedOut) {
        _isPasswordRecovery = false;
      }
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;
  bool _isPasswordRecovery = false;

  bool get isPasswordRecovery => _isPasswordRecovery;

  void clearPasswordRecovery() {
    _isPasswordRecovery = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterRefreshStream =
    GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange);

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: appRouterRefreshStream,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final matched = state.matchedLocation;

    // 1. Password recovery mode takes priority: keep user on /reset-password until updated/logged out
    if (appRouterRefreshStream.isPasswordRecovery) {
      if (matched != '/reset-password') {
        return '/reset-password';
      }
      return null;
    }

    final isAuthRoute = matched == '/login' ||
        matched == '/signup' ||
        matched == '/forgot-password' ||
        matched == '/reset-password' ||
        matched == '/';

    // 2. Not logged in and trying to access protected route -> go to /login
    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }

    // 3. Logged in and on an auth route (except /reset-password) -> go to /home
    if (isLoggedIn &&
        (matched == '/login' ||
            matched == '/signup' ||
            matched == '/')) {
      return '/home';
    }

    return null;
  },
  routes: [
    // Auth routes (no shell/bottom nav)
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),

    // Main app routes with bottom navigation (Decision #3: Notes in nav)
    ShellRoute(
      builder: (context, state, child) {
        return ShellScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/chat',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ChatScreen(),
          ),
        ),
        GoRoute(
          path: '/tasks',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TasksScreen(),
          ),
        ),
        GoRoute(
          path: '/notes',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: NotesScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),

    // Feature routes opened from Home dashboard (Decision #4)
    GoRoute(
      path: '/calendar',
      builder: (context, state) => const CalendarScreen(),
    ),
    GoRoute(
      path: '/habits',
      builder: (context, state) => const HabitsScreen(),
    ),
    GoRoute(
      path: '/pomodoro',
      builder: (context, state) => const PomodoroScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationHistoryScreen(),
    ),
  ],
);
