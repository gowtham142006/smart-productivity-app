import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/task_service.dart';

final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService();
});
