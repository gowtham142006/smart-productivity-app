import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/message_model.dart';
import '../../../tasks/providers/task_provider.dart';
import '../../domain/ai_response_models.dart';
import 'structured_response_widgets.dart';

class ChatBubble extends ConsumerWidget {
  final MessageModel message;

  const ChatBubble({super.key, required this.message});

  bool get isUser => message.role == MessageRole.user;

  List<String> _extractTasks(String content) {
    final lines = content.split(RegExp(r"\r?\n"));
    final tasks = <String>[];
    for (var l in lines) {
      final s = l.trim();
      if (s.isEmpty) continue;
      // Markdown checkboxes or bullets
      final patterns = [
        RegExp(r'^[-*]\s+'),
        RegExp(r'^\d+\.\s+'),
        RegExp(r'^•\s+'),
        RegExp(r'^- \[.?\]\s+'),
      ];
      var matched = false;
      for (var p in patterns) {
        if (p.hasMatch(s)) {
          var t = s.replaceAll(p, '').trim();
          if (t.isNotEmpty) tasks.add(t);
          matched = true;
          break;
        }
      }
      // Also accept lines that look like short imperative sentences
      if (!matched && s.length < 80 && (s.split(' ').length <= 8)) {
        // Heuristic: start with a verb?
        final first = s.split(' ').first.toLowerCase();
        final verbs = [
          'collect',
          'revise',
          'solve',
          'practice',
          'read',
          'write',
          'plan',
          'review',
          'create',
          'add',
          'finish',
        ];
        if (verbs.contains(first)) tasks.add(s);
      }
    }
    return tasks;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if assistant returned structured JSON
    if (!isUser) {
      try {
        final parsedModel = parseAIResponse(message.content);
        if (parsedModel != null) {
          debugPrint('Structured widget selected: ${parsedModel.runtimeType}');
          final widget = Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.88,
              ),
              margin: const EdgeInsets.only(
                left: 0,
                right: 24,
                bottom: 8,
              ),
              child: StructuredResponseWidget(
                model: parsedModel,
                onCopyRaw: () async {
                  await Clipboard.setData(ClipboardData(text: message.content));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied raw response'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
            ),
          );
          debugPrint('Final widget rendered: ${parsedModel.runtimeType}');
          return widget;
        }
      } catch (e, st) {
        debugPrint('Exceptions while rendering structured responses: $e');
        debugPrintStack(stackTrace: st);

        // Render detailed validation error container
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.88,
            ),
            margin: const EdgeInsets.only(right: 24, bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.error_outline_rounded, color: AppColors.error),
                    SizedBox(width: 8),
                    Text(
                      'AI Response Validation Failure',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Falling back to raw response text:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  message.content,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    final tasks = !isUser ? _extractTasks(message.content) : [];

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: EdgeInsets.only(
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
          bottom: 8,
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : (isDark ? AppColors.darkCard : AppColors.surfaceVariant),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? AppColors.primary : Colors.black)
                        .withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SelectableText(
                message.content,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary),
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
            ),

            if (!isUser)
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: GestureDetector(
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await Clipboard.setData(
                          ClipboardData(text: message.content),
                        );
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Copied to clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (tasks.isNotEmpty)
                    TextButton.icon(
                      onPressed: () async {
                        final notifier = ref.read(allTasksProvider.notifier);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          for (var t in tasks) {
                            await notifier.addTask(title: t);
                          }
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Added ${tasks.length} tasks'),
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Failed to add tasks: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.add_box_outlined, size: 16),
                      label: const Text('Add all tasks'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
