import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';

class NotepadService {
  static const _notesKey = 'notepad_notes';

  Future<List<NoteModel>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_notesKey) ?? <String>[];
    return raw.map((s) => NoteModel.fromMap(jsonDecode(s))).toList();
  }

  Future<void> saveNotes(List<NoteModel> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = notes.map((n) => jsonEncode(n.toMap())).toList();
    await prefs.setStringList(_notesKey, raw);
  }

  Future<void> addOrUpdateNote(NoteModel note) async {
    final notes = await loadNotes();
    final idx = notes.indexWhere((n) => n.id == note.id);
    if (idx == -1) {
      notes.insert(0, note);
    } else {
      notes[idx] = note;
    }
    await saveNotes(notes);
  }

  Future<void> deleteNote(String id) async {
    final notes = await loadNotes();
    notes.removeWhere((n) => n.id == id);
    await saveNotes(notes);
  }
}
