import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client;
  AuthService(this._client);

  // Convenience constructor for backward compatibility
  factory AuthService.instance() {
    return AuthService(Supabase.instance.client);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    String? emailRedirectTo,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: emailRedirectTo ?? 'smartproductivity://auth-callback',
      data: {'name': username},
    );
    // Profile row is created on first verified login (see ProfileProvider).
    // Storing username in user_metadata ensures it survives email verification.
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email, {String? redirectTo}) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo ?? 'smartproductivity://reset-password',
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
