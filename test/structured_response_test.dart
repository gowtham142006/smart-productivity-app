import 'package:flutter_test/flutter_test.dart';
import 'package:smart_productivity_app/features/chat/domain/ai_response_models.dart';

void main() {
  group('JSON Detection and Extraction', () {
    test('detects direct JSON', () {
      const input = '{"goal": "study", "priority": "high"}';
      expect(extractJson(input), equals('{"goal": "study", "priority": "high"}'));
    });

    test('detects markdown code block JSON', () {
      const input = '```json\n{"goal": "study", "priority": "high"}\n```';
      expect(extractJson(input), equals('{"goal": "study", "priority": "high"}'));
    });

    test('detects JSON with prefix/suffix text', () {
      const input = 'Here is the plan:\n```\n{"goal": "study", "priority": "high"}\n```\nEnjoy!';
      expect(extractJson(input), equals('{"goal": "study", "priority": "high"}'));
    });

    test('returns null for non-JSON text', () {
      const input = 'Just a regular plain chat message';
      expect(extractJson(input), isNull);
    });
  });

  group('Structured AI Response Parsing', () {
    test('parses StudyPlanResponse', () {
      const json = '''
      {
        "goal": "Revise Biology",
        "priority": "High",
        "suggested_tasks": [{"title": "Read chapter 1", "estimated_hours": "2"}],
        "estimated_time_hours": "5",
        "daily_schedule": {"Monday": ["Read chapter 1"]},
        "important_topics": ["Genetics"],
        "revision_plan": ["Do practice test"],
        "motivation": "You can do it!"
      }
      ''';
      final model = parseAIResponse(json);
      expect(model, isA<StudyPlanResponse>());
      final plan = model as StudyPlanResponse;
      expect(plan.goal, equals("Revise Biology"));
      expect(plan.priority, equals("High"));
      expect(plan.suggestedTasks.length, equals(1));
      expect(plan.suggestedTasks[0].title, equals("Read chapter 1"));
      expect(plan.dailySchedule['Monday'], contains("Read chapter 1"));
    });

    test('parses TaskPlannerResponse', () {
      const json = '''
      {
        "goal": "Prepare dinner",
        "priority": "Medium",
        "tasks": [{"title": "Buy groceries", "priority": "High", "estimated_minutes": 30, "suggested_deadline": "6 PM"}]
      }
      ''';
      final model = parseAIResponse(json);
      expect(model, isA<TaskPlannerResponse>());
      final plan = model as TaskPlannerResponse;
      expect(plan.goal, equals("Prepare dinner"));
      expect(plan.tasks[0].title, equals("Buy groceries"));
      expect(plan.tasks[0].estimatedMinutes, equals(30));
    });

    test('parses ProductivityCoachResponse', () {
      const json = '''
      {
        "todays_focus": ["Time blocking"],
        "high_priority": ["Finish project"],
        "time_management": ["25-minute Pomodoro"],
        "tips": ["Stay hydrated"]
      }
      ''';
      final model = parseAIResponse(json);
      expect(model, isA<ProductivityCoachResponse>());
      final coach = model as ProductivityCoachResponse;
      expect(coach.todaysFocus, contains("Time blocking"));
      expect(coach.tips, contains("Stay hydrated"));
    });
  });

  group('Schema Validation Errors', () {
    test('throws on missing field', () {
      const json = '''
      {
        "goal": "Revise Biology",
        "priority": "High",
        "suggested_tasks": [{"title": "Read chapter 1", "estimated_hours": "2"}],
        "daily_schedule": {"Monday": ["Read chapter 1"]},
        "important_topics": ["Genetics"],
        "revision_plan": ["Do practice test"],
        "motivation": "You can do it!"
      }
      ''';
      expect(() => parseAIResponse(json), throwsA(isA<FormatException>()));
    });

    test('throws on unexpected field', () {
      const json = '''
      {
        "goal": "Revise Biology",
        "priority": "High",
        "suggested_tasks": [{"title": "Read chapter 1", "estimated_hours": "2"}],
        "estimated_time_hours": "5",
        "daily_schedule": {"Monday": ["Read chapter 1"]},
        "important_topics": ["Genetics"],
        "revision_plan": ["Do practice test"],
        "motivation": "You can do it!",
        "unexpected_key": "some value"
      }
      ''';
      expect(() => parseAIResponse(json), throwsA(isA<FormatException>()));
    });

    test('throws on invalid field type', () {
      const json = '''
      {
        "goal": "Revise Biology",
        "priority": {"level": "High"},
        "suggested_tasks": [{"title": "Read chapter 1", "estimated_hours": "2"}],
        "estimated_time_hours": "5",
        "daily_schedule": {"Monday": ["Read chapter 1"]},
        "important_topics": ["Genetics"],
        "revision_plan": ["Do practice test"],
        "motivation": "You can do it!"
      }
      ''';
      expect(() => parseAIResponse(json), throwsA(isA<FormatException>()));
    });
  });
}
