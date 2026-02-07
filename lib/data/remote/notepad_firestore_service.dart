import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

class NotepadFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userNotes(String uid) =>
      _db.collection('users').doc(uid).collection('notepad');

  Future<List<NoteModel>> fetchNotes(String uid) async {
    try {
      final snap = await _userNotes(uid).get();
      final notes = snap.docs.map((d) => NoteModel.fromMap(d.data())).toList();
      // Sort client-side instead of ordering in Firestore
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return notes;
    } catch (e) {
      print('❌ Notepad fetch error: $e');
      return [];
    }
  }

  Stream<List<NoteModel>> streamNotes(String uid) {
    return _userNotes(uid).snapshots().map((s) {
      final notes = s.docs.map((d) => NoteModel.fromMap(d.data())).toList();
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return notes;
    });
  }

  Future<void> addOrUpdateNote(String uid, NoteModel note) async {
    await _userNotes(uid).doc(note.id).set(note.toMap());
  }

  Future<void> deleteNote(String uid, String id) async {
    await _userNotes(uid).doc(id).delete();
  }
}
