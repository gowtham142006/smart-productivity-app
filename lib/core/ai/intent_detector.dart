import 'prompts.dart';

AIIntent detectIntent(String input) {
  final text = input.toLowerCase();

  // Study planner
  final studyKeywords = [
    'prepare',
    'exam',
    'study plan',
    'revise',
    'revision',
    'syllabus',
    'prepare for',
    'study for',
  ];
  if (studyKeywords.any((k) => text.contains(k))) {
    return AIIntent.studyPlanner;
  }

  // Note summarization
  final summarizeKeywords = [
    'summarize',
    'summarise',
    'summary',
    'summarizer',
    'summarise this',
    'summarize this',
    'key points',
  ];
  if (summarizeKeywords.any((k) => text.contains(k))) {
    return AIIntent.noteSummarization;
  }

  // Convert notes to tasks
  final convertKeywords = [
    'convert notes',
    'notes to tasks',
    'convert to tasks',
    'turn notes into tasks',
  ];
  if (convertKeywords.any((k) => text.contains(k))) {
    return AIIntent.convertNotesToTasks;
  }

  // Task planner / generation
  final taskPlannerKeywords = [
    'create tasks',
    'task planner',
    'create task',
    'task list',
    'todo',
    'tasks for',
    'break down',
  ];
  final taskGenKeywords = [
    'generate tasks',
    'task generation',
    'make tasks',
    'suggest tasks',
  ];
  if (taskPlannerKeywords.any((k) => text.contains(k))) {
    return AIIntent.taskPlanner;
  }
  if (taskGenKeywords.any((k) => text.contains(k))) {
    return AIIntent.taskGeneration;
  }

  // Productivity coach
  final coachKeywords = [
    'productivity',
    'time management',
    'prioritize',
    'focus',
    'productivity coach',
    'today focus',
  ];
  if (coachKeywords.any((k) => text.contains(k))) {
    return AIIntent.productivityCoach;
  }

  // Default
  return AIIntent.generalChat;
}
