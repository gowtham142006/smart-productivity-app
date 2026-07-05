import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

/// Profile data state.
class ProfileState {
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isLoading;

  const ProfileState({
    this.name = '',
    this.email = '',
    this.avatarUrl,
    this.isLoading = false,
  });

  ProfileState copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    bool? isLoading,
    bool clearAvatar = false,
  }) {
    return ProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProfileNotifier extends AsyncNotifier<ProfileState> {
  @override
  Future<ProfileState> build() async {
    return _loadProfile();
  }

  Future<ProfileState> _loadProfile() async {
    final user = ref.read(currentUserProvider);
    final service = ref.read(profileServiceProvider);
    final profile = await service.getProfile();

    return ProfileState(
      name: profile?['name'] ?? user?.email?.split('@').first ?? '',
      email: user?.email ?? '',
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }

  Future<void> updateName(String name) async {
    final service = ref.read(profileServiceProvider);
    await service.updateProfile(name: name);
    state = AsyncData(state.value!.copyWith(name: name));
  }

  /// Upload profile image via Supabase Storage (Decision #1).
  Future<void> uploadAvatar(File imageFile) async {
    state = AsyncData(state.value!.copyWith(isLoading: true));

    final service = ref.read(profileServiceProvider);
    final url = await service.uploadProfileImage(imageFile);

    if (url != null) {
      state = AsyncData(state.value!.copyWith(
        avatarUrl: url,
        isLoading: false,
      ));
    } else {
      state = AsyncData(state.value!.copyWith(isLoading: false));
    }
  }

  Future<void> removeAvatar() async {
    final service = ref.read(profileServiceProvider);
    await service.removeProfileImage();
    state = AsyncData(state.value!.copyWith(clearAvatar: true));
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
