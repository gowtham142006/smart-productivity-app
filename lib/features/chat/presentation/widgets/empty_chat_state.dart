import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class EmptyChatState extends StatelessWidget {
  final ValueChanged<String> onSuggestionTap;

  const EmptyChatState({super.key, required this.onSuggestionTap});

  static const _suggestions = [
    '📋 Help me plan my day',
    '✅ Suggest tasks for productivity',
    '📝 Summarize my recent notes',
    '💡 Give me study tips',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primaryLight.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'How can I help you?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'I\'m your AI productivity assistant.\nAsk me anything!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions.map((s) {
                return ActionChip(
                  label: Text(
                    s,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () => onSuggestionTap(s),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
