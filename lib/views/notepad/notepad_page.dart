import 'package:flutter/material.dart';
import '../../data/remote/notepad_firestore_service.dart';
import '../../data/models/note_model.dart';

class NotepadPage extends StatefulWidget {
  final String uid;

  const NotepadPage({super.key, required this.uid});

  @override
  State<NotepadPage> createState() => _NotepadPageState();
}

class _NotepadPageState extends State<NotepadPage> {
  final NotepadFirestoreService _service = NotepadFirestoreService();
  List<NoteModel> _notes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _notes = await _service.fetchNotes(widget.uid);
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Error loading notes: $e';
        _loading = false;
      });
    }
  }

  Future<void> _editNote([NoteModel? note]) async {
    final titleController = TextEditingController(text: note?.title ?? '');
    final controller = TextEditingController(text: note?.content ?? '');
    
    try {
      final result = await showDialog<String?>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(note == null ? 'New Note' : 'Edit Note'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'Write your note...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (result == null) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      final finalTitle = titleController.text.trim().isNotEmpty
          ? titleController.text.trim()
          : (result.isNotEmpty ? result.split('\n').first : '');

      final newNote = NoteModel(
        id: note?.id ?? now.toString(),
        title: finalTitle,
        content: result,
        updatedAt: now,
      );
      await _service.addOrUpdateNote(widget.uid, newNote);
      await _load();
    } finally {
      titleController.dispose();
      controller.dispose();
    }
  }

  Future<void> _deleteNote(String id) async {
    await _service.deleteNote(widget.uid, id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Notepad')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _notes.isEmpty
          ? Center(
              child: Text('No notes yet', style: theme.textTheme.bodyLarge),
            )
          : ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (_, i) {
                final n = _notes[i];
                return ListTile(
                  title: Text(
                    n.title.isNotEmpty ? n.title : n.content.split('\n').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    DateTime.fromMillisecondsSinceEpoch(
                      n.updatedAt,
                    ).toLocal().toString(),
                    style: theme.textTheme.bodySmall,
                  ),
                  onTap: () => _editNote(n),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteNote(n.id),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editNote(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
