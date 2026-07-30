import 'dart:convert';
import 'package:flutter/foundation.dart';

enum AIStructuredType {
  studyPlanner,
  taskPlanner,
  taskGeneration,
  noteSummarization,
  convertNotesToTasks,
  productivityCoach,
}

// Validation Helper
void _validateFields({
  required Map<String, dynamic> json,
  required Set<String> expectedKeys,
  required Map<String, Type> fieldTypes,
  required Set<String> requiredKeys,
  required String modelName,
}) {
  // Check unexpected fields
  for (final key in json.keys) {
    if (!expectedKeys.contains(key)) {
      debugPrint('Unexpected field:\n$key');
      throw FormatException('Unexpected field: $key');
    }
  }

  // Check missing required fields
  for (final key in requiredKeys) {
    if (!json.containsKey(key)) {
      debugPrint('Missing field:\n$key');
      throw FormatException('Missing field: $key');
    }
  }

  // Check invalid types
  fieldTypes.forEach((key, expectedType) {
    if (json.containsKey(key)) {
      final value = json[key];
      if (value != null) {
        bool isValid = false;
        if (expectedType == String && value is String) { isValid = true; }
        else if (expectedType == int && value is int) { isValid = true; }
        else if (expectedType == double && value is double) { isValid = true; }
        else if (expectedType == num && value is num) { isValid = true; }
        else if (expectedType == List && value is List) { isValid = true; }
        else if (expectedType == Map && value is Map) { isValid = true; }
        else if (expectedType == bool && value is bool) { isValid = true; }

        if (!isValid) {
          debugPrint('Invalid type:\n$key expected ${expectedType.toString()} but received ${value.runtimeType.toString()}');
          throw FormatException('Invalid type: $key expected ${expectedType.toString()} but received ${value.runtimeType.toString()}');
        }
      }
    }
  });
}

// ----------------------------------------------------
// 1. Study Planner Model
// ----------------------------------------------------
class StudyPlanResponse {
  final String goal;
  final String priority;
  final List<StudyTask> suggestedTasks;
  final String estimatedTimeHours;
  final Map<String, List<String>> dailySchedule;
  final List<String> importantTopics;
  final List<String> revisionPlan;
  final String motivation;

  StudyPlanResponse({
    required this.goal,
    required this.priority,
    required this.suggestedTasks,
    required this.estimatedTimeHours,
    required this.dailySchedule,
    required this.importantTopics,
    required this.revisionPlan,
    required this.motivation,
  });

  factory StudyPlanResponse.fromJson(Map<String, dynamic> json) {
    _validateFields(
      json: json,
      expectedKeys: {
        'goal',
        'priority',
        'suggested_tasks',
        'estimated_time_hours',
        'daily_schedule',
        'important_topics',
        'revision_plan',
        'motivation',
      },
      requiredKeys: {
        'goal',
        'priority',
        'suggested_tasks',
        'estimated_time_hours',
        'daily_schedule',
        'important_topics',
        'revision_plan',
        'motivation',
      },
      fieldTypes: {
        'goal': String,
        'priority': String,
        'suggested_tasks': List,
        'estimated_time_hours': String,
        'daily_schedule': Map,
        'important_topics': List,
        'revision_plan': List,
        'motivation': String,
      },
      modelName: 'StudyPlanResponse',
    );

    final tasksList = json['suggested_tasks'] as List;
    for (var i = 0; i < tasksList.length; i++) {
      final t = tasksList[i];
      if (t is Map<String, dynamic>) {
        _validateFields(
          json: t,
          expectedKeys: {'title', 'estimated_hours'},
          requiredKeys: {'title'},
          fieldTypes: {'title': String, 'estimated_hours': String},
          modelName: 'StudyTask[$i]',
        );
      } else {
        debugPrint('Invalid type:\nsuggested_tasks[$i] expected Map but received ${t.runtimeType}');
        throw FormatException('suggested_tasks[$i] expected Map');
      }
    }

    final scheduleMap = json['daily_schedule'] as Map;
    final parsedTasks = <String>[];
    scheduleMap.forEach((day, tasks) {
      if (tasks is List) {
        for (var i = 0; i < tasks.length; i++) {
          final t = tasks[i];
          if (t is String) {
            parsedTasks.add(t);
          } else {
            debugPrint('Invalid type:\ndaily_schedule["$day"][$i] expected String but received ${t?.runtimeType}');
            throw FormatException('daily_schedule["$day"][$i] expected String');
          }
        }
      } else {
        debugPrint('Invalid type:\ndaily_schedule["$day"] expected List but received ${tasks?.runtimeType}');
        throw FormatException('daily_schedule["$day"] expected List');
      }
    });
    debugPrint('Task extraction completed. Extracted ${parsedTasks.length} daily schedule tasks and ${tasksList.length} suggested tasks.');

    return StudyPlanResponse(
      goal: json['goal'],
      priority: json['priority'],
      suggestedTasks: tasksList.map((t) => StudyTask.fromJson(t)).toList(),
      estimatedTimeHours: json['estimated_time_hours'],
      dailySchedule: scheduleMap.map((key, value) => MapEntry(
        key.toString(),
        (value as List).map((e) => e.toString()).toList(),
      )),
      importantTopics: (json['important_topics'] as List).map((e) => e.toString()).toList(),
      revisionPlan: (json['revision_plan'] as List).map((e) => e.toString()).toList(),
      motivation: json['motivation'],
    );
  }
}

class StudyTask {
  final String title;
  final String estimatedHours;

  StudyTask({required this.title, required this.estimatedHours});

  factory StudyTask.fromJson(dynamic json) {
    if (json is Map) {
      return StudyTask(
        title: json['title'] ?? '',
        estimatedHours: json['estimated_hours']?.toString() ?? '',
      );
    }
    return StudyTask(title: json?.toString() ?? '', estimatedHours: '');
  }
}

// ----------------------------------------------------
// 2. Task Planner Model
// ----------------------------------------------------
class TaskPlannerResponse {
  final String goal;
  final String priority;
  final List<TaskPlannerItem> tasks;

  TaskPlannerResponse({
    required this.goal,
    required this.priority,
    required this.tasks,
  });

  factory TaskPlannerResponse.fromJson(Map<String, dynamic> json) {
    _validateFields(
      json: json,
      expectedKeys: {'goal', 'priority', 'tasks'},
      requiredKeys: {'goal', 'priority', 'tasks'},
      fieldTypes: {'goal': String, 'priority': String, 'tasks': List},
      modelName: 'TaskPlannerResponse',
    );

    final tasksList = json['tasks'] as List;
    for (var i = 0; i < tasksList.length; i++) {
      final t = tasksList[i];
      if (t is Map<String, dynamic>) {
        _validateFields(
          json: t,
          expectedKeys: {'title', 'priority', 'estimated_minutes', 'suggested_deadline'},
          requiredKeys: {'title', 'priority', 'estimated_minutes', 'suggested_deadline'},
          fieldTypes: {
            'title': String,
            'priority': String,
            'estimated_minutes': num,
            'suggested_deadline': String,
          },
          modelName: 'TaskPlannerItem[$i]',
        );
      } else {
        debugPrint('Invalid type:\ntasks[$i] expected Map but received ${t.runtimeType}');
        throw FormatException('tasks[$i] expected Map');
      }
    }
    debugPrint('Task extraction completed. Extracted ${tasksList.length} tasks.');

    return TaskPlannerResponse(
      goal: json['goal'],
      priority: json['priority'],
      tasks: tasksList.map((t) => TaskPlannerItem.fromJson(t)).toList(),
    );
  }
}

class TaskPlannerItem {
  final String title;
  final String priority;
  final int estimatedMinutes;
  final String suggestedDeadline;

  TaskPlannerItem({
    required this.title,
    required this.priority,
    required this.estimatedMinutes,
    required this.suggestedDeadline,
  });

  factory TaskPlannerItem.fromJson(dynamic json) {
    if (json is Map) {
      final est = json['estimated_minutes'];
      return TaskPlannerItem(
        title: json['title'] ?? '',
        priority: json['priority'] ?? 'medium',
        estimatedMinutes: est is num ? est.toInt() : 0,
        suggestedDeadline: json['suggested_deadline'] ?? '',
      );
    }
    return TaskPlannerItem(
      title: json?.toString() ?? '',
      priority: 'medium',
      estimatedMinutes: 0,
      suggestedDeadline: '',
    );
  }
}

// ----------------------------------------------------
// 3. Task Generation Model
// ----------------------------------------------------
class TaskGenerationResponse {
  final String source;
  final List<TaskGenerationItem> tasks;

  TaskGenerationResponse({
    required this.source,
    required this.tasks,
  });

  factory TaskGenerationResponse.fromJson(Map<String, dynamic> json) {
    _validateFields(
      json: json,
      expectedKeys: {'source', 'tasks'},
      requiredKeys: {'source', 'tasks'},
      fieldTypes: {'source': String, 'tasks': List},
      modelName: 'TaskGenerationResponse',
    );

    final tasksList = json['tasks'] as List;
    for (var i = 0; i < tasksList.length; i++) {
      final t = tasksList[i];
      if (t is Map<String, dynamic>) {
        _validateFields(
          json: t,
          expectedKeys: {'title', 'description', 'estimated_minutes'},
          requiredKeys: {'title', 'description', 'estimated_minutes'},
          fieldTypes: {
            'title': String,
            'description': String,
            'estimated_minutes': num,
          },
          modelName: 'TaskGenerationItem[$i]',
        );
      } else {
        debugPrint('Invalid type:\ntasks[$i] expected Map but received ${t.runtimeType}');
        throw FormatException('tasks[$i] expected Map');
      }
    }
    debugPrint('Task extraction completed. Extracted ${tasksList.length} tasks.');

    return TaskGenerationResponse(
      source: json['source'],
      tasks: tasksList.map((t) => TaskGenerationItem.fromJson(t)).toList(),
    );
  }
}

class TaskGenerationItem {
  final String title;
  final String description;
  final int estimatedMinutes;

  TaskGenerationItem({
    required this.title,
    required this.description,
    required this.estimatedMinutes,
  });

  factory TaskGenerationItem.fromJson(dynamic json) {
    if (json is Map) {
      final est = json['estimated_minutes'];
      return TaskGenerationItem(
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        estimatedMinutes: est is num ? est.toInt() : 0,
      );
    }
    return TaskGenerationItem(
      title: json?.toString() ?? '',
      description: '',
      estimatedMinutes: 0,
    );
  }
}

// ----------------------------------------------------
// 4. Note Summarization Model
// ----------------------------------------------------
class NoteSummarizationResponse {
  final String summary;
  final List<String> keyPoints;
  final List<ActionItem> actionItems;

  NoteSummarizationResponse({
    required this.summary,
    required this.keyPoints,
    required this.actionItems,
  });

  factory NoteSummarizationResponse.fromJson(Map<String, dynamic> json) {
    _validateFields(
      json: json,
      expectedKeys: {'summary', 'key_points', 'action_items'},
      requiredKeys: {'summary', 'key_points', 'action_items'},
      fieldTypes: {'summary': String, 'key_points': List, 'action_items': List},
      modelName: 'NoteSummarizationResponse',
    );

    final actionItemsList = json['action_items'] as List;
    for (var i = 0; i < actionItemsList.length; i++) {
      final a = actionItemsList[i];
      if (a is Map<String, dynamic>) {
        _validateFields(
          json: a,
          expectedKeys: {'title', 'description'},
          requiredKeys: {'title', 'description'},
          fieldTypes: {'title': String, 'description': String},
          modelName: 'ActionItem[$i]',
        );
      } else {
        debugPrint('Invalid type:\naction_items[$i] expected Map but received ${a.runtimeType}');
        throw FormatException('action_items[$i] expected Map');
      }
    }
    debugPrint('Task extraction completed. Extracted ${actionItemsList.length} action items.');

    return NoteSummarizationResponse(
      summary: json['summary'],
      keyPoints: (json['key_points'] as List).map((e) => e.toString()).toList(),
      actionItems: actionItemsList.map((a) => ActionItem.fromJson(a)).toList(),
    );
  }
}

class ActionItem {
  final String title;
  final String description;

  ActionItem({required this.title, required this.description});

  factory ActionItem.fromJson(dynamic json) {
    if (json is Map) {
      return ActionItem(
        title: json['title'] ?? '',
        description: json['description'] ?? '',
      );
    }
    return ActionItem(title: json?.toString() ?? '', description: '');
  }
}

// ----------------------------------------------------
// 5. Convert Notes to Tasks Model
// ----------------------------------------------------
class ConvertNotesToTasksResponse {
  final String source;
  final List<ConvertNotesTaskItem> tasks;

  ConvertNotesToTasksResponse({
    required this.source,
    required this.tasks,
  });

  factory ConvertNotesToTasksResponse.fromJson(Map<String, dynamic> json) {
    _validateFields(
      json: json,
      expectedKeys: {'source', 'tasks'},
      requiredKeys: {'source', 'tasks'},
      fieldTypes: {'source': String, 'tasks': List},
      modelName: 'ConvertNotesToTasksResponse',
    );

    final tasksList = json['tasks'] as List;
    for (var i = 0; i < tasksList.length; i++) {
      final t = tasksList[i];
      if (t is Map<String, dynamic>) {
        _validateFields(
          json: t,
          expectedKeys: {'title', 'description', 'priority', 'due_date'},
          requiredKeys: {'title', 'description'},
          fieldTypes: {
            'title': String,
            'description': String,
            'priority': String,
            'due_date': String,
          },
          modelName: 'ConvertNotesTaskItem[$i]',
        );
      } else {
        debugPrint('Invalid type:\ntasks[$i] expected Map but received ${t.runtimeType}');
        throw FormatException('tasks[$i] expected Map');
      }
    }
    debugPrint('Task extraction completed. Extracted ${tasksList.length} tasks.');

    return ConvertNotesToTasksResponse(
      source: json['source'],
      tasks: tasksList.map((t) => ConvertNotesTaskItem.fromJson(t)).toList(),
    );
  }
}

class ConvertNotesTaskItem {
  final String title;
  final String description;
  final String? priority;
  final String? dueDate;

  ConvertNotesTaskItem({
    required this.title,
    required this.description,
    this.priority,
    this.dueDate,
  });

  factory ConvertNotesTaskItem.fromJson(dynamic json) {
    if (json is Map) {
      return ConvertNotesTaskItem(
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        priority: json['priority'],
        dueDate: json['due_date'],
      );
    }
    return ConvertNotesTaskItem(
      title: json?.toString() ?? '',
      description: '',
    );
  }
}

// ----------------------------------------------------
// 6. Productivity Coach Model
// ----------------------------------------------------
class ProductivityCoachResponse {
  final List<String> todaysFocus;
  final List<String> highPriority;
  final List<String> timeManagement;
  final List<String> tips;

  ProductivityCoachResponse({
    required this.todaysFocus,
    required this.highPriority,
    required this.timeManagement,
    required this.tips,
  });

  factory ProductivityCoachResponse.fromJson(Map<String, dynamic> json) {
    _validateFields(
      json: json,
      expectedKeys: {'todays_focus', 'high_priority', 'time_management', 'tips'},
      requiredKeys: {'todays_focus', 'high_priority', 'time_management', 'tips'},
      fieldTypes: {
        'todays_focus': List,
        'high_priority': List,
        'time_management': List,
        'tips': List,
      },
      modelName: 'ProductivityCoachResponse',
    );

    return ProductivityCoachResponse(
      todaysFocus: (json['todays_focus'] as List).map((e) => e.toString()).toList(),
      highPriority: (json['high_priority'] as List).map((e) => e.toString()).toList(),
      timeManagement: (json['time_management'] as List).map((e) => e.toString()).toList(),
      tips: (json['tips'] as List).map((e) => e.toString()).toList(),
    );
  }
}

// ----------------------------------------------------
// JSON Detection and Parsing Helpers
// ----------------------------------------------------

String? extractJson(String content) {
  var trimmed = content.trim();
  
  // 1. Check if the whole string is direct JSON object
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    return trimmed;
  }
  
  // 2. Try to match ```json { ... } ``` or ``` { ... } ```
  final blockRegExp = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
  final match = blockRegExp.firstMatch(trimmed);
  if (match != null) {
    final extracted = match.group(1)!.trim();
    if (extracted.startsWith('{') && extracted.endsWith('}')) {
      return extracted;
    }
  }
  
  // 3. Fallback: Search for the first '{' and last '}'
  final firstBrace = trimmed.indexOf('{');
  final lastBrace = trimmed.lastIndexOf('}');
  if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
    final candidate = trimmed.substring(firstBrace, lastBrace + 1);
    try {
      json.decode(candidate);
      return candidate;
    } catch (_) {
      // Not valid JSON
    }
  }
  
  return null;
}

AIStructuredType? detectStructuredType(Map<String, dynamic> map) {
  if (map.containsKey('daily_schedule') || map.containsKey('suggested_tasks')) {
    return AIStructuredType.studyPlanner;
  }
  if (map.containsKey('tasks') && map.containsKey('goal') && map.containsKey('priority')) {
    return AIStructuredType.taskPlanner;
  }
  if (map.containsKey('tasks') && map.containsKey('source')) {
    // Distinguish between convertNotesToTasks and taskGeneration
    final tasksList = map['tasks'] as List?;
    if (tasksList != null && tasksList.isNotEmpty) {
      final firstTask = tasksList.first;
      if (firstTask is Map) {
        if (firstTask.containsKey('due_date') || firstTask.containsKey('priority')) {
          return AIStructuredType.convertNotesToTasks;
        }
      }
    }
    return AIStructuredType.taskGeneration;
  }
  if (map.containsKey('summary') || map.containsKey('action_items')) {
    return AIStructuredType.noteSummarization;
  }
  if (map.containsKey('todays_focus') || map.containsKey('time_management')) {
    return AIStructuredType.productivityCoach;
  }
  return null;
}

dynamic parseAIResponse(String content) {
  final jsonStr = extractJson(content);
  if (jsonStr == null) {
    return null;
  }
  
  debugPrint('JSON cleaned: attempting to decode...');
  try {
    final decoded = json.decode(jsonStr);
    debugPrint('JSON decoded successfully.');
    if (decoded is Map<String, dynamic>) {
      final type = detectStructuredType(decoded);
      debugPrint('Intent detected from JSON: $type');
      if (type == null) {
        debugPrint('JSON keys did not match any expected AI intents.');
        return null;
      }
      
      dynamic model;
      switch (type) {
        case AIStructuredType.studyPlanner:
          model = StudyPlanResponse.fromJson(decoded);
          break;
        case AIStructuredType.taskPlanner:
          model = TaskPlannerResponse.fromJson(decoded);
          break;
        case AIStructuredType.taskGeneration:
          model = TaskGenerationResponse.fromJson(decoded);
          break;
        case AIStructuredType.noteSummarization:
          model = NoteSummarizationResponse.fromJson(decoded);
          break;
        case AIStructuredType.convertNotesToTasks:
          model = ConvertNotesToTasksResponse.fromJson(decoded);
          break;
        case AIStructuredType.productivityCoach:
          model = ProductivityCoachResponse.fromJson(decoded);
          break;
      }
      
      debugPrint('Model created: ${model.runtimeType}');
      return model;
    }
  } catch (e, st) {
    debugPrint('JSON parsing / Model creation failed: $e');
    debugPrintStack(stackTrace: st);
    rethrow;
  }
  return null;
}
