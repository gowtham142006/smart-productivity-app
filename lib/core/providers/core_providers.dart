import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../services/note_service.dart';
import '../../services/category_service.dart';
import '../../services/gemini_service.dart';
import '../../services/habit_service.dart';
import '../../services/daily_stats_service.dart';
import '../../services/pomodoro_service.dart';
import '../../services/profile_service.dart';
import '../../services/notification_history_service.dart';
import '../../services/calendar_event_service.dart';
import '../../services/notification_service.dart';
import '../../features/chat/domain/chat_repository.dart';

// ─── Core Dependency Providers ─────────────────────

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ─── Service Providers ─────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService(ref.watch(supabaseClientProvider));
});

final noteServiceProvider = Provider<NoteService>((ref) {
  return NoteService(ref.watch(supabaseClientProvider));
});

final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService(ref.watch(supabaseClientProvider));
});

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(apiKey: dotenv.get('GEMINI_API_KEY'));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(supabaseClientProvider));
});

final habitServiceProvider = Provider<HabitService>((ref) {
  return HabitService(ref.watch(supabaseClientProvider));
});

final dailyStatsServiceProvider = Provider<DailyStatsService>((ref) {
  return DailyStatsService(ref.watch(supabaseClientProvider));
});

final pomodoroServiceProvider = Provider<PomodoroService>((ref) {
  return PomodoroService(ref.watch(supabaseClientProvider));
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.watch(supabaseClientProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationHistoryServiceProvider = Provider<NotificationHistoryService>((ref) {
  return NotificationHistoryService(ref.watch(supabaseClientProvider));
});

final calendarEventServiceProvider = Provider<CalendarEventService>((ref) {
  return CalendarEventService(ref.watch(supabaseClientProvider));
});

// ─── Auth State ────────────────────────────────────

final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  // Watch auth state stream so this provider rebuilds on login/logout/token refresh
  ref.watch(authStateProvider);
  return ref.watch(supabaseClientProvider).auth.currentUser;
});

