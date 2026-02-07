import 'package:flutter/material.dart';
import '../../data/remote/notepad_firestore_service.dart';
import '../../data/models/note_model.dart';

class NotepadListWidget extends StatefulWidget {
  final String uid;
  final VoidCallback? onAddNote;

  const NotepadListWidget({
    super.key,
    required this.uid,
    this.onAddNote,
  });

  @override
  State<NotepadListWidget> createState() => NotepadListWidgetState();
}

class NotepadListWidgetState extends State<NotepadListWidget> {
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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    try {
      final result = await showDialog<String?>(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    note == null ? 'New Note' : 'Edit Note',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 18 : 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: isSmallScreen ? 5 : 8,
                    decoration: InputDecoration(
                      hintText: 'Write your note...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, controller.text.trim()),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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

  void addNote() => _editNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: isSmallScreen ? 40 : 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: isSmallScreen ? 13 : 14,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notes.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 24 : 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.note_outlined,
                size: isSmallScreen ? 48 : 64,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No notes yet',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to create your first note',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: isSmallScreen ? 12 : 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 8 : 12,
        horizontal: isSmallScreen ? 8 : 0,
      ),
      itemCount: _notes.length,
      itemBuilder: (_, i) {
        final n = _notes[i];
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? screenSize.width - 16 : 800,
            ),
            child: Card(
              margin: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: 4,
              ),
              elevation: 0,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                onTap: () => _editNote(n),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title.isNotEmpty
                            ? n.title
                            : n.content.split('\n').first,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 15 : 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        n.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: isSmallScreen ? 12 : 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateTime.fromMillisecondsSinceEpoch(n.updatedAt)
                                .toLocal()
                                .toString()
                                .split(' ')[0],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: isSmallScreen ? 11 : 12,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: isSmallScreen ? 18 : 20,
                            ),
                            iconSize: isSmallScreen ? 18 : 24,
                            padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                            onPressed: () => _deleteNote(n.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
