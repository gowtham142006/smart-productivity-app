import 'package:intl/intl.dart';

class DateFormatter {
  static String relative(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1 && diff <= 7) return DateFormat.EEEE().format(date);
    if (diff < -1) return '${-diff} days overdue';
    return DateFormat.MMMd().format(date);
  }

  static String full(DateTime? date) {
    if (date == null) return '';
    return DateFormat.yMMMd().format(date);
  }

  static String time(DateTime? date) {
    if (date == null) return '';
    return DateFormat.jm().format(date);
  }

  static bool isOverdue(DateTime? date) {
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }

  static bool isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
