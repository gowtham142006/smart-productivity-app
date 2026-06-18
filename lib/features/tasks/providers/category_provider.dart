import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/category_model.dart';
import '../../../core/providers/core_providers.dart';

class CategoryListNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() async {
    final service = ref.watch(categoryServiceProvider);
    final data = await service.getCategories();
    return data.map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<void> addCategory({
    required String name,
    required String color,
    String icon = 'folder',
  }) async {
    final service = ref.read(categoryServiceProvider);
    await service.addCategory(name: name, color: color, icon: icon);
    ref.invalidateSelf();
  }

  Future<void> deleteCategory(String id) async {
    final previous = state.value ?? [];
    state = AsyncData(previous.where((c) => c.id != id).toList());

    try {
      final service = ref.read(categoryServiceProvider);
      await service.deleteCategory(id);
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final categoryListProvider =
    AsyncNotifierProvider<CategoryListNotifier, List<CategoryModel>>(
  CategoryListNotifier.new,
);
