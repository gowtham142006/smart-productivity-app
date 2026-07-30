import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../tasks/providers/task_provider.dart';
import '../../../tasks/data/task_model.dart';
import '../../providers/calendar_provider.dart';
import '../../data/calendar_event_model.dart';
import 'add_edit_event_screen.dart';
import 'event_detail_screen.dart';

/// Unified item type for the calendar agenda.
enum _AgendaItemType { task, event }

class _AgendaItem {
  final String id;
  final String title;
  final String? subtitle;
  final Color color;
  final IconData icon;
  final _AgendaItemType type;
  final bool isCompleted;
  final String? category;
  final dynamic data; // TaskModel or CalendarEventModel

  const _AgendaItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.color,
    required this.icon,
    required this.type,
    this.isCompleted = false,
    this.category,
    this.data,
  });
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  /// Build agenda items for a given day combining tasks and events.
  List<_AgendaItem> _getItemsForDay(
    DateTime day,
    List<TaskModel> tasks,
    List<CalendarEventModel> events,
  ) {
    final items = <_AgendaItem>[];

    // Tasks with due date on this day
    for (final task in tasks) {
      if (task.dueDate == null) continue;
      if (isSameDay(task.dueDate!, day)) {
        items.add(_AgendaItem(
          id: task.id,
          title: task.title,
          subtitle: task.description.isNotEmpty ? task.description : null,
          color: AppColors.info,
          icon: Icons.task_alt_rounded,
          type: _AgendaItemType.task,
          isCompleted: task.isCompleted,
          data: task,
        ));
      }
    }

    // Calendar events on this day
    for (final event in events) {
      if (isSameDay(event.startDatetime, day)) {
        final timeStr = DateFormat.jm().format(event.startDatetime);
        items.add(_AgendaItem(
          id: event.id,
          title: event.title,
          subtitle: '$timeStr${event.location != null ? ' · ${event.location}' : ''}',
          color: event.colorValue,
          icon: Icons.event_rounded,
          type: _AgendaItemType.event,
          category: event.category,
          data: event,
        ));
      }
    }

    return items;
  }

  /// Get dot markers for a day (for the calendar widget).
  List<_AgendaItem> _getMarkersForDay(
    DateTime day,
    List<TaskModel> tasks,
    List<CalendarEventModel> events,
  ) {
    final items = <_AgendaItem>[];

    for (final task in tasks) {
      if (task.dueDate != null && isSameDay(task.dueDate!, day)) {
        items.add(_AgendaItem(
          id: task.id,
          title: task.title,
          color: AppColors.info,
          icon: Icons.task_alt_rounded,
          type: _AgendaItemType.task,
        ));
      }
    }

    for (final event in events) {
      if (isSameDay(event.startDatetime, day)) {
        items.add(_AgendaItem(
          id: event.id,
          title: event.title,
          color: event.colorValue,
          icon: Icons.event_rounded,
          type: _AgendaItemType.event,
        ));
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(allTasksProvider);
    final eventsAsync = ref.watch(calendarEventProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tasks = allTasks.value ?? [];
    final events = eventsAsync.value ?? [];

    final selectedItems = _getItemsForDay(
      _selectedDay ?? _focusedDay,
      tasks,
      events,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // View toggle
          PopupMenuButton<CalendarFormat>(
            icon: const Icon(Icons.view_agenda_outlined),
            onSelected: (format) {
              setState(() => _calendarFormat = format);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: CalendarFormat.month,
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_month,
                        size: 20,
                        color: _calendarFormat == CalendarFormat.month
                            ? AppColors.primary
                            : null),
                    const SizedBox(width: 8),
                    const Text('Monthly'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: CalendarFormat.twoWeeks,
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_week,
                        size: 20,
                        color: _calendarFormat == CalendarFormat.twoWeeks
                            ? AppColors.primary
                            : null),
                    const SizedBox(width: 8),
                    const Text('2 Weeks'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: CalendarFormat.week,
                child: Row(
                  children: [
                    Icon(Icons.view_week_rounded,
                        size: 20,
                        color: _calendarFormat == CalendarFormat.week
                            ? AppColors.primary
                            : null),
                    const SizedBox(width: 8),
                    const Text('Weekly'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditEventScreen(
                initialDate: _selectedDay ?? _focusedDay,
              ),
            ),
          );
          if (result == true) {
            ref.read(calendarEventProvider.notifier).refresh();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Calendar widget
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TableCalendar<_AgendaItem>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) => _getMarkersForDay(day, tasks, events),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                markerSize: 6,
                markersMaxCount: 3,
                markerMargin: const EdgeInsets.symmetric(horizontal: 1),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, markers) {
                  if (markers.isEmpty) return null;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: markers.take(3).map((marker) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: marker.color,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _LegendDot(color: AppColors.info, label: 'Tasks'),
                const SizedBox(width: 16),
                _LegendDot(color: AppColors.primary, label: 'Events'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${selectedItems.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Agenda list
          Expanded(
            child: selectedItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 48,
                          color: AppColors.textTertiary
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No items for this day',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: selectedItems.length,
                    itemBuilder: (context, index) {
                      final item = selectedItems[index];
                      return _AgendaTile(
                        item: item,
                        onTap: () => _onItemTap(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _onItemTap(_AgendaItem item) async {
    if (item.type == _AgendaItemType.event) {
      final event = item.data as CalendarEventModel;
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(event: event),
        ),
      );
      if (result == true) {
        ref.read(calendarEventProvider.notifier).refresh();
      }
    }
    // Tasks navigate to tasks screen handled elsewhere if needed
  }
}

class _AgendaTile extends StatelessWidget {
  final _AgendaItem item;
  final VoidCallback onTap;

  const _AgendaTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: item.isCompleted
                            ? AppColors.textTertiary
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary),
                      ),
                    ),
                    if (item.subtitle != null)
                      Text(
                        item.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              // Category badge
              if (item.category != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.category!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: item.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Type badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _typeLabel(item.type),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: item.color,
                  ),
                ),
              ),
              if (item.isCompleted) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(_AgendaItemType type) {
    switch (type) {
      case _AgendaItemType.task:
        return 'Task';
      case _AgendaItemType.event:
        return 'Event';
    }
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
