import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../providers/note_ai_provider.dart';
import '../../data/note_model.dart';

class NoteSummarySheet extends ConsumerWidget {
  final NoteModel? note; // Null means summarizing all notes

  const NoteSummarySheet({super.key, this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAiState = ref.watch(noteAiProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  note != null ? 'Note Summary' : 'All Notes Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                note!.title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const Divider(height: 24),
          // Content
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: noteAiState.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(strokeWidth: 3),
                        SizedBox(height: 16),
                        Text(
                          'AI is analyzing note content...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 36),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to summarize note',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString().replaceAll('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                data: (text) {
                  if (text.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _parseMarkdownToWidgets(text, isDark),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Actions
          noteAiState.maybeWhen(
            data: (text) {
              if (text.isEmpty) return const SizedBox.shrink();
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Summary copied to clipboard'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy'),
                    ),
                  ),
                  if (note != null && !text.startsWith('Successfully')) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          try {
                            final added = await ref.read(noteAiProvider.notifier).convertNoteToTasks(note!);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Added ${added.length} tasks from note!'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            navigator.pop();
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to convert: $e'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                        label: const Text('Create Tasks'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  List<Widget> _parseMarkdownToWidgets(String markdown, bool isDark) {
    final List<Widget> widgets = [];
    final lines = markdown.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Headers (e.g. #, ##, ###)
      if (trimmed.startsWith('#')) {
        final level = trimmed.indexOf(RegExp(r'[^#]'));
        final text = trimmed.substring(level).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Text(
              text,
              style: TextStyle(
                fontSize: level == 1 ? 18 : level == 2 ? 15 : 13,
                fontWeight: FontWeight.bold,
                color: level <= 2 ? AppColors.primary : (isDark ? Colors.white : AppColors.textPrimary),
              ),
            ),
          ),
        );
      }
      // List items starting with -, *, or emoji
      else if (trimmed.startsWith('-') || trimmed.startsWith('*') || trimmed.startsWith('•')) {
        final text = trimmed.replaceFirst(RegExp(r'^[\-\*\•]\s*'), '').trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6.0, right: 8.0),
                  child: Icon(Icons.circle, size: 6, color: AppColors.primary),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: _parseInlineBold(text, isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Regular paragraphs
      else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: RichText(
              text: TextSpan(
                children: _parseInlineBold(trimmed, isDark),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  List<TextSpan> _parseInlineBold(String text, bool isDark) {
    final List<TextSpan> spans = [];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    final color = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    for (final match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, match.start),
            style: TextStyle(color: color, fontSize: 13.5, height: 1.45),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: TextStyle(color: color, fontSize: 13.5, height: 1.45),
        ),
      );
    }

    return spans;
  }
}
