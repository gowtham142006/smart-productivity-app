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

  /// Converts raw Supabase auth exceptions or network errors into clean, user-friendly messages.
  static String getErrorMessage(dynamic error) {
    if (error is AuthException) {
      final code = error.code?.toLowerCase() ?? '';
      final message = error.message.toLowerCase();
      final statusCode = error.statusCode;

      // Invalid credentials
      if (code == 'invalid_credentials' ||
          message.contains('invalid login credentials') ||
          message.contains('invalid credentials') ||
          message.contains('invalid grant')) {
        return 'Incorrect email or password. Please check your credentials and try again.';
      }

      // Email rate limit
      if (code == 'over_email_send_rate_limit' ||
          code == 'over_request_rate_limit' ||
          statusCode == '429' ||
          message.contains('rate limit') ||
          message.contains('email rate limit exceeded')) {
        return 'Too many signup attempts. Please wait a few minutes and try again.';
      }

      // Email not confirmed
      if (code == 'email_not_confirmed' ||
          message.contains('email not confirmed')) {
        return 'Please confirm your email address before signing in.';
      }

      // User / Account already exists
      if (code == 'user_already_exists' ||
          code == 'email_exists' ||
          code == 'user_already_registered' ||
          message.contains('user already registered') ||
          message.contains('user already exists') ||
          message.contains('already registered') ||
          message.contains('already exists')) {
        return 'An account with this email already exists. Please log in instead.';
      }

      // Network errors wrapped inside AuthException
      if (message.contains('socketexception') ||
          message.contains('failed host lookup') ||
          message.contains('connection failed') ||
          message.contains('network error') ||
          message.contains('clientexception')) {
        return 'Unable to connect. Please check your internet connection and try again.';
      }

      return 'Something went wrong. Please try again.';
    }

    // Network / Connection errors outside AuthException
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('socketexception') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('clientexception') ||
        errStr.contains('connection refused') ||
        errStr.contains('network')) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }

    return 'Something went wrong. Please try again.';
  }
}
