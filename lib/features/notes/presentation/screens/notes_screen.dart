import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/note_model.dart';

import '../../providers/note_provider.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final titleController = TextEditingController();

  final contentController = TextEditingController();

  List<NoteModel> notes = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    fetchNotes();
  }

  Future<void> fetchNotes() async {
    final noteService = ref.read(noteServiceProvider);

    final response = await noteService.getNotes();

    setState(() {
      notes = response.map((note) => NoteModel.fromJson(note)).toList();

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final parentContext = context;

          showModalBottomSheet(
            context: context,

            isScrollControlled: true,

            builder: (context) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,

                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    TextField(
                      controller: titleController,

                      decoration: const InputDecoration(hintText: 'Note title'),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: contentController,

                      maxLines: 5,

                      decoration: const InputDecoration(
                        hintText: 'Write your note...',
                      ),
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () async {
                        final noteService = ref.read(noteServiceProvider);

                        await noteService.addNote(
                          title: titleController.text,

                          content: contentController.text,
                        );

                        await fetchNotes();

                        titleController.clear();

                        contentController.clear();

                        if (!context.mounted) {
                          return;
                        }

                        Navigator.pop(context);

                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(content: Text('Note added')),
                        );
                      },

                      child: const Text('Add Note'),
                    ),
                  ],
                ),
              );
            },
          );
        },

        child: const Icon(Icons.add),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : notes.isEmpty
            ? const Center(child: Text('No notes yet'))
            : ListView.builder(
                itemCount: notes.length,

                itemBuilder: (context, index) {
                  final note = notes[index];

                  return Card(
                    child: ListTile(
                      title: Text(note.title),

                      subtitle: Text(note.content),

                      trailing: IconButton(
                        icon: const Icon(Icons.delete),

                        onPressed: () async {
                          final noteService = ref.read(noteServiceProvider);

                          await noteService.deleteNote(note.id);

                          await fetchNotes();

                          if (!context.mounted) {
                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Note deleted')),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
