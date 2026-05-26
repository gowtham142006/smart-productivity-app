import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/note_service.dart';

final noteServiceProvider = Provider<NoteService>((ref) {
  return NoteService();
});
