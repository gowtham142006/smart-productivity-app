import 'dart:convert';

enum AIStructuredType {
  studyPlanner,
  taskPlanner,
  taskGeneration,
  noteSummarization,
  convertNotesToTasks,
  productivityCoach,
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
    final tasksList = json['suggested_tasks'] as List? ?? [];
    final scheduleMap = json['daily_schedule'] as Map? ?? {};
    
    return StudyPlanResponse(
      goal: json['goal'] ?? '',
      priority: json['priority'] ?? '',
      suggestedTasks: tasksList.map((t) => StudyTask.fromJson(t)).toList(),
      estimatedTimeHours: json['estimated_time_hours']?.toString() ?? '',
      dailySchedule: scheduleMap.map((key, value) => MapEntry(
        key.toString(),
        (value as List? ?? []).map((e) => e.toString()).toList(),
      )),
      importantTopics: (json['important_topics'] as List? ?? []).map((e) => e.toString()).toList(),
      revisionPlan: (json['revision_plan'] as List? ?? []).map((e) => e.toString()).toList(),
      motivation: json['motivation'] ?? '',
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
    final tasksList = json['tasks'] as List? ?? [];
    return TaskPlannerResponse(
      goal: json['goal'] ?? '',
      priority: json['priority'] ?? '',
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
    final tasksList = json['tasks'] as List? ?? [];
    return TaskGenerationResponse(
      source: json['source'] ?? '',
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
    final keyPointsList = json['key_points'] as List? ?? [];
    final actionItemsList = json['action_items'] as List? ?? [];
    return NoteSummarizationResponse(
      summary: json['summary'] ?? '',
      keyPoints: keyPointsList.map((e) => e.toString()).toList(),
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
    final tasksList = json['tasks'] as List? ?? [];
    return ConvertNotesToTasksResponse(
      source: json['source'] ?? '',
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
    return ProductivityCoachResponse(
      todaysFocus: (json['todays_focus'] as List? ?? []).map((e) => e.toString()).toList(),
      highPriority: (json['high_priority'] as List? ?? []).map((e) => e.toString()).toList(),
      timeManagement: (json['time_management'] as List? ?? []).map((e) => e.toString()).toList(),
      tips: (json['tips'] as List? ?? []).map((e) => e.toString()).toList(),
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
      // Validate it decodes successfully
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
  if (jsonStr == null) return null;
  
  try {
    final decoded = json.decode(jsonStr);
    if (decoded is Map<String, dynamic>) {
      final type = detectStructuredType(decoded);
      switch (type) {
        case AIStructuredType.studyPlanner:
          return StudyPlanResponse.fromJson(decoded);
        case AIStructuredType.taskPlanner:
          return TaskPlannerResponse.fromJson(decoded);
        case AIStructuredType.taskGeneration:
          return TaskGenerationResponse.fromJson(decoded);
        case AIStructuredType.noteSummarization:
          return NoteSummarizationResponse.fromJson(decoded);
        case AIStructuredType.convertNotesToTasks:
          return ConvertNotesToTasksResponse.fromJson(decoded);
        case AIStructuredType.productivityCoach:
          return ProductivityCoachResponse.fromJson(decoded);
        case null:
          return null;
      }
    }
  } catch (e) {
    // Graceful fallback
    return null;
  }
  return null;
}
