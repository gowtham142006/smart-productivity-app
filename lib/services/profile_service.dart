import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class ProfileService {
  final SupabaseClient _client;
  ProfileService(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  /// Get the user's profile data.
  Future<Map<String, dynamic>?> getProfile() async {
    if (_userId == null) return null;

    return await _client
        .from('profiles')
        .select()
        .eq('id', _userId!)
        .maybeSingle();
  }

  /// Update profile fields.
  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    if (_userId == null) return;

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    if (updates.isNotEmpty) {
      updates['id'] = _userId!;
      updates['updated_at'] = DateTime.now().toIso8601String();
      await _client.from('profiles').upsert(updates);
    }
  }

  /// Upload a profile image to Supabase Storage and update the profile.
  Future<String?> uploadProfileImage(File imageFile) async {
    if (_userId == null) return null;

    try {
      final ext = p.extension(imageFile.path).replaceAll('.', '');
      final filePath = '$_userId/avatar.$ext';

      // Upload to Supabase Storage bucket 'avatars'
      await _client.storage.from('avatars').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Get the public URL and append a timestamp to bust the cache
      final baseUrl = _client.storage.from('avatars').getPublicUrl(filePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicUrl = '$baseUrl?t=$timestamp';

      // Update profile with new avatar URL
      await updateProfile(avatarUrl: publicUrl);

      return publicUrl;
    } catch (e) {
      debugPrint('[ProfileService] Error uploading avatar: $e');
      return null;
    }
  }

  /// Remove the profile image.
  Future<void> removeProfileImage() async {
    if (_userId == null) return;

    try {
      // List files in user's avatar folder
      final files =
          await _client.storage.from('avatars').list(path: _userId!);

      if (files.isNotEmpty) {
        final paths = files.map((f) => '$_userId/${f.name}').toList();
        await _client.storage.from('avatars').remove(paths);
      }

      await updateProfile(avatarUrl: '');
    } catch (e) {
      debugPrint('[ProfileService] Error removing avatar: $e');
    }
  }
}
