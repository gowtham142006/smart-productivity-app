import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../services/note_service.dart';
import '../../services/category_service.dart';

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

// ─── Auth State ────────────────────────────────────

final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser;
});
