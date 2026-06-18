import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryService {
  final SupabaseClient _client;
  CategoryService(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> getCategories() async {
    if (_userId == null) return [];

    return await _client
        .from('categories')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: true);
  }

  Future<void> addCategory({
    required String name,
    required String color,
    String icon = 'folder',
  }) async {
    if (_userId == null) return;

    await _client.from('categories').insert({
      'name': name,
      'color': color,
      'icon': icon,
      'user_id': _userId,
    });
  }

  Future<void> updateCategory({
    required String id,
    String? name,
    String? color,
    String? icon,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (color != null) updates['color'] = color;
    if (icon != null) updates['icon'] = icon;

    if (updates.isNotEmpty) {
      await _client.from('categories').update(updates).eq('id', id);
    }
  }

  Future<void> deleteCategory(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }
}
