import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<void> signUp({
    required String email,

    required String password,

    required String username,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,

      password: password,
    );

    final user = response.user;

    if (user != null) {
      await supabase.from('profiles').insert({'id': user.id, 'name': username});
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
