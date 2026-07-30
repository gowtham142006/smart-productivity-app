import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for CRUD operations on the `notifications` table.
class NotificationHistoryService {
  final SupabaseClient _client;
  NotificationHistoryService(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  /// Fetch all notifications for the current user, newest first.
  Future<List<Map<String, dynamic>>> getNotifications({int limit = 50}) async {
    if (_userId == null) return [];

    try {
      return await _client
          .from('notifications')
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false)
          .limit(limit);
    } catch (e) {
      debugPrint('[NotificationHistoryService] Error fetching notifications: $e');
      return [];
    }
  }

  /// Get count of unread notifications.
  Future<int> getUnreadCount() async {
    if (_userId == null) return 0;

    try {
      final result = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', _userId!)
          .eq('is_read', false);
      return (result as List).length;
    } catch (e) {
      debugPrint('[NotificationHistoryService] Error getting unread count: $e');
      return 0;
    }
  }

  /// Insert a notification record (called when local notifications fire).
  Future<void> insertNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? payload,
  }) async {
    if (_userId == null) return;

    try {
      await _client.from('notifications').insert({
        'user_id': _userId,
        'title': title,
        'body': body,
        'type': type,
        if (payload != null) 'payload': payload,
        'is_read': false,
      });
    } catch (e) {
      debugPrint('[NotificationHistoryService] Error inserting notification: $e');
    }
  }

  /// Mark a notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('[NotificationHistoryService] Error marking as read: $e');
    }
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    if (_userId == null) return;

    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _userId!)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('[NotificationHistoryService] Error marking all as read: $e');
    }
  }

  /// Delete a single notification.
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      debugPrint('[NotificationHistoryService] Error deleting notification: $e');
    }
  }

  /// Clear all notifications for the current user.
  Future<void> clearAll() async {
    if (_userId == null) return;

    try {
      await _client
          .from('notifications')
          .delete()
          .eq('user_id', _userId!);
    } catch (e) {
      debugPrint('[NotificationHistoryService] Error clearing all: $e');
    }
  }
}
