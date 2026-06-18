import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/task_provider.dart';
import '../../providers/category_provider.dart';

class TaskFilterBar extends ConsumerWidget {
  const TaskFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskFilterProvider);
    final categories = ref.watch(categoryListProvider).value ?? [];

    return Column(
      children: [
        // Quick filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                isSelected: filter.showCompleted == null,
                onTap: () =>
                    ref.read(taskFilterProvider.notifier).setShowCompleted(null),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Pending',
                isSelected: filter.showCompleted == false,
                onTap: () => ref
                    .read(taskFilterProvider.notifier)
                    .setShowCompleted(false),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Completed',
                isSelected: filter.showCompleted == true,
                onTap: () => ref
                    .read(taskFilterProvider.notifier)
                    .setShowCompleted(true),
              ),
              const SizedBox(width: 8),
              // Priority filter
              PopupMenuButton<String?>(
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _FilterChip(
                  label: filter.priority != null
                      ? TaskPriority.fromString(filter.priority).label
                      : 'Priority',
                  isSelected: filter.priority != null,
                  showDropdown: true,
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: null,
                    child: Text('All Priorities'),
                  ),
                  ...TaskPriority.values.map(
                    (p) => PopupMenuItem(
                      value: p.value,
                      child: Row(
                        children: [
                          Icon(p.icon, size: 18, color: p.color),
                          const SizedBox(width: 8),
                          Text(p.label),
                        ],
                      ),
                    ),
                  ),
                ],
                onSelected: (value) {
                  ref.read(taskFilterProvider.notifier).setPriority(value);
                },
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String?>(
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _FilterChip(
                    label: filter.categoryId != null
                        ? categories
                            .where((c) => c.id == filter.categoryId)
                            .firstOrNull
                            ?.name ?? 'Category'
                        : 'Category',
                    isSelected: filter.categoryId != null,
                    showDropdown: true,
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...categories.map(
                      (c) => PopupMenuItem(
                        value: c.id,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(
                                      c.color.replaceFirst('#', '0xFF')),
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    ref.read(taskFilterProvider.notifier).setCategory(value);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showDropdown;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.onTap,
    this.showDropdown = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            if (showDropdown) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more,
                size: 16,
                color:
                    isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
