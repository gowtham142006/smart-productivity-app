import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_model.dart';
import '../../../core/providers/core_providers.dart';

/// Manages notification history from the `notifications` Supabase table.
class NotificationHistoryNotifier
    extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    return _fetchNotifications();
  }

  Future<List<NotificationModel>> _fetchNotifications() async {
    try {
      final service = ref.read(notificationHistoryServiceProvider);
      final data = await service.getNotifications();
      return data.map((e) => NotificationModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[NotificationHistory] Error fetching: $e');
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    // Optimistic update
    final previous = state.value ?? [];
    state = AsyncData(
      previous.map((n) {
        if (n.id == notificationId) return n.copyWith(isRead: true);
        return n;
      }).toList(),
    );

    try {
      final service = ref.read(notificationHistoryServiceProvider);
      await service.markAsRead(notificationId);
    } catch (e) {
      state = AsyncData(previous);
      debugPrint('[NotificationHistory] Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final previous = state.value ?? [];
    state = AsyncData(
      previous.map((n) => n.copyWith(isRead: true)).toList(),
    );

    try {
      final service = ref.read(notificationHistoryServiceProvider);
      await service.markAllAsRead();
    } catch (e) {
      state = AsyncData(previous);
      debugPrint('[NotificationHistory] Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final previous = state.value ?? [];
    state = AsyncData(previous.where((n) => n.id != notificationId).toList());

    try {
      final service = ref.read(notificationHistoryServiceProvider);
      await service.deleteNotification(notificationId);
    } catch (e) {
      state = AsyncData(previous);
      debugPrint('[NotificationHistory] Error deleting: $e');
    }
  }

  Future<void> clearAll() async {
    final previous = state.value ?? [];
    state = const AsyncData([]);

    try {
      final service = ref.read(notificationHistoryServiceProvider);
      await service.clearAll();
    } catch (e) {
      state = AsyncData(previous);
      debugPrint('[NotificationHistory] Error clearing all: $e');
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final notificationHistoryProvider = AsyncNotifierProvider<
    NotificationHistoryNotifier, List<NotificationModel>>(
  NotificationHistoryNotifier.new,
);

/// Derived provider for unread notification count.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationHistoryProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});
