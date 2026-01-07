import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotePage extends StatefulWidget {
  const NotePage({super.key});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController noteController = TextEditingController();

  List<dynamic> notes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    try {
      final data = await supabase
          .from('cafe_notes')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        notes = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> addNote() async {
    if (noteController.text.isEmpty) return;

    try {
      await supabase.from('cafe_notes').insert({
        'note': noteController.text,
      });

      noteController.clear();
      fetchNotes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add note')),
      );
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await supabase.from('cafe_notes').delete().eq('id', id);
      fetchNotes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete note')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cafe Notes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Add Note',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: addNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : notes.isEmpty
                    ? const Center(child: Text('No notes found'))
                    : ListView.builder(
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(note['note'] ?? ''),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteNote(note['id']),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

