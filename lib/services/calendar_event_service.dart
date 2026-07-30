import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for CRUD operations on the `calendar_events` table.
class CalendarEventService {
  final SupabaseClient _client;
  CalendarEventService(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  /// Fetch all events for the current user.
  Future<List<Map<String, dynamic>>> getEvents() async {
    if (_userId == null) return [];

    try {
      return await _client
          .from('calendar_events')
          .select()
          .eq('user_id', _userId!)
          .order('start_datetime', ascending: true);
    } catch (e) {
      debugPrint('[CalendarEventService] Error fetching events: $e');
      return [];
    }
  }

  /// Fetch events for a specific date range.
  Future<List<Map<String, dynamic>>> getEventsForRange(
    DateTime start,
    DateTime end,
  ) async {
    if (_userId == null) return [];

    try {
      return await _client
          .from('calendar_events')
          .select()
          .eq('user_id', _userId!)
          .gte('start_datetime', start.toIso8601String())
          .lte('start_datetime', end.toIso8601String())
          .order('start_datetime', ascending: true);
    } catch (e) {
      debugPrint('[CalendarEventService] Error fetching events for range: $e');
      return [];
    }
  }

  /// Add a new calendar event.
  Future<Map<String, dynamic>?> addEvent({
    required String title,
    String description = '',
    required DateTime startDatetime,
    DateTime? endDatetime,
    String color = '#5B67F1',
    String? category,
    String? location,
    String? notes,
  }) async {
    if (_userId == null) return null;

    try {
      final data = <String, dynamic>{
        'user_id': _userId,
        'title': title,
        'description': description,
        'start_datetime': startDatetime.toIso8601String(),
        'color': color,
      };

      if (endDatetime != null) {
        data['end_datetime'] = endDatetime.toIso8601String();
      }
      if (category != null) data['category'] = category;
      if (location != null) data['location'] = location;
      if (notes != null) data['notes'] = notes;

      final res = await _client
          .from('calendar_events')
          .insert(data)
          .select()
          .single();
      debugPrint('[CalendarEventService] ✅ Event "$title" created');
      return res;
    } catch (e) {
      debugPrint('[CalendarEventService] ❌ Error adding event: $e');
      rethrow;
    }
  }

  /// Update a calendar event.
  Future<void> updateEvent({
    required String eventId,
    String? title,
    String? description,
    DateTime? startDatetime,
    DateTime? endDatetime,
    String? color,
    String? category,
    String? location,
    String? notes,
    bool clearEndDatetime = false,
    bool clearCategory = false,
    bool clearLocation = false,
    bool clearNotes = false,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (startDatetime != null) {
      updates['start_datetime'] = startDatetime.toIso8601String();
    }
    if (color != null) updates['color'] = color;

    if (clearEndDatetime) {
      updates['end_datetime'] = null;
    } else if (endDatetime != null) {
      updates['end_datetime'] = endDatetime.toIso8601String();
    }

    if (clearCategory) {
      updates['category'] = null;
    } else if (category != null) {
      updates['category'] = category;
    }

    if (clearLocation) {
      updates['location'] = null;
    } else if (location != null) {
      updates['location'] = location;
    }

    if (clearNotes) {
      updates['notes'] = null;
    } else if (notes != null) {
      updates['notes'] = notes;
    }

    if (updates.length > 1) {
      await _client
          .from('calendar_events')
          .update(updates)
          .eq('id', eventId);
    }
  }

  /// Delete a calendar event.
  Future<void> deleteEvent(String eventId) async {
    await _client.from('calendar_events').delete().eq('id', eventId);
  }
}
