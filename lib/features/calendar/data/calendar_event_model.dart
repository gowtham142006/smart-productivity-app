import 'package:flutter/material.dart';

/// Calendar event model mapping to the `calendar_events` Supabase table.
class CalendarEventModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime startDatetime;
  final DateTime? endDatetime;
  final String color;
  final String? category;
  final String? location;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CalendarEventModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.startDatetime,
    this.endDatetime,
    this.color = '#5B67F1',
    this.category,
    this.location,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      startDatetime: DateTime.parse(json['start_datetime'] as String),
      endDatetime: json['end_datetime'] != null
          ? DateTime.parse(json['end_datetime'] as String)
          : null,
      color: json['color'] as String? ?? '#5B67F1',
      category: json['category'] as String?,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'start_datetime': startDatetime.toIso8601String(),
      if (endDatetime != null)
        'end_datetime': endDatetime!.toIso8601String(),
      'color': color,
      'category': category,
      'location': location,
      'notes': notes,
    };
  }

  Color get colorValue {
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF5B67F1);
    }
  }

  CalendarEventModel copyWith({
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
  }) {
    return CalendarEventModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startDatetime: startDatetime ?? this.startDatetime,
      endDatetime: clearEndDatetime ? null : (endDatetime ?? this.endDatetime),
      color: color ?? this.color,
      category: clearCategory ? null : (category ?? this.category),
      location: clearLocation ? null : (location ?? this.location),
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
