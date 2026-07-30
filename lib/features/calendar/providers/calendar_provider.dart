import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/calendar_event_model.dart';
import '../../../core/providers/core_providers.dart';

/// Manages calendar events from the `calendar_events` Supabase table.
class CalendarEventNotifier
    extends AsyncNotifier<List<CalendarEventModel>> {
  @override
  Future<List<CalendarEventModel>> build() async {
    return _fetchEvents();
  }

  Future<List<CalendarEventModel>> _fetchEvents() async {
    try {
      final service = ref.read(calendarEventServiceProvider);
      final data = await service.getEvents();
      return data.map((e) => CalendarEventModel.fromJson(e)).toList();
    } catch (e, st) {
      debugPrint('[CalendarProvider] ❌ Error fetching events: $e');
      debugPrint('[CalendarProvider] Stack: $st');
      return [];
    }
  }

  Future<void> addEvent({
    required String title,
    String description = '',
    required DateTime startDatetime,
    DateTime? endDatetime,
    String color = '#5B67F1',
    String? category,
    String? location,
    String? notes,
  }) async {
    try {
      final service = ref.read(calendarEventServiceProvider);
      await service.addEvent(
        title: title,
        description: description,
        startDatetime: startDatetime,
        endDatetime: endDatetime,
        color: color,
        category: category,
        location: location,
        notes: notes,
      );
      ref.invalidateSelf();
      await future;
    } catch (e) {
      debugPrint('[CalendarProvider] ❌ Error adding event: $e');
      rethrow;
    }
  }

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
    try {
      final service = ref.read(calendarEventServiceProvider);
      await service.updateEvent(
        eventId: eventId,
        title: title,
        description: description,
        startDatetime: startDatetime,
        endDatetime: endDatetime,
        color: color,
        category: category,
        location: location,
        notes: notes,
        clearEndDatetime: clearEndDatetime,
        clearCategory: clearCategory,
        clearLocation: clearLocation,
        clearNotes: clearNotes,
      );
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('[CalendarProvider] ❌ Error updating event: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    final previous = state.value ?? [];
    state = AsyncData(previous.where((e) => e.id != eventId).toList());

    try {
      final service = ref.read(calendarEventServiceProvider);
      await service.deleteEvent(eventId);
    } catch (e) {
      state = AsyncData(previous);
      debugPrint('[CalendarProvider] ❌ Error deleting event: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final calendarEventProvider = AsyncNotifierProvider<CalendarEventNotifier,
    List<CalendarEventModel>>(
  CalendarEventNotifier.new,
);
