import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_again/models/deletion_result.dart';
import 'package:flutter_application_again/models/note.dart';
import 'package:flutter_application_again/resources/auth_methods.dart';
import 'package:flutter_application_again/resources/firstore_folder_methods.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;
  final String userUid;
  final FirestoreFolderService firestoreFolder;

  FirestoreService({FirebaseFirestore? firestore, String? userUid})
      : this._(firestore ?? FirebaseFirestore.instance,
            userUid ?? AuthService().useUid);

  FirestoreService._(this._firestore, this.userUid)
      : firestoreFolder =
            FirestoreFolderService(firestore: _firestore, userUid: userUid);

  Future<String?> addDocument(
      {required String document,
      required String title,
      required String searchableDocument,
      String folder = 'All',
      required DateTime date}) async {
    final String uid = const Uuid().v4();
    final Note note = Note.fromEditor(
        folder: folder,
        document: document,
        searchableDocument: searchableDocument,
        date: date,
        uid: uid,
        title: title);

    try {
      await _firestore.collection(userUid).doc(uid).set(note.toJson());
      await firestoreFolder.addDocToFolder(folderField: folder, noteUid: uid);
    } on FirebaseException catch (e) {
      return e.message!;
    }
    return null;
  }

  Future<String?> updateDocument(
      {required String document,
      required String searchableDocument,
      required String title,
      required String previousFolder,
      required folder,
      required String noteUid,
      required DateTime date}) async {
    final Note note = Note.fromEditor(
        folder: folder,
        searchableDocument: searchableDocument,
        document: document,
        date: date,
        uid: noteUid,
        title: title);

    try {
      await _firestore.collection(userUid).doc(noteUid).set(note.toJson());
      await firestoreFolder.updateFolder(
          folderField: folder,
          noteUid: noteUid,
          previousFolder: previousFolder);
    } on FirebaseException catch (e) {
      return e.message!;
    }

    return null;
  }

  getNote({required String uid}) async {
    final snapshot = await _firestore.collection(userUid).doc(uid).get();
    return snapshot.data();
  }

  clearAllNotes() async {
    final folder = _firestore.collection(userUid).doc('folders');

    try {
      final docs = (await _firestore.collection(userUid).get()).docs;
      //Delete all docs except the folder doc
      await Future.wait(docs
          .where((ds) => ds.reference != folder)
          .map((ds) => ds.reference.delete()));
      await firestoreFolder.clearFolders();
    } on FirebaseException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteDocsOfFolder(String folder) async {
    var data =
        _firestore.collection(userUid).where('folder', isEqualTo: folder);
    try {
      final querySnapshot = await data.get();
      await Future.wait(
          querySnapshot.docs.map((element) => element.reference.delete()));
    } on FirebaseException catch (e) {
      return e.message;
    }
    return null;
  }

  Future<String?> deleteNote(
      {required String uid, required String folder}) async {
    try {
      await _firestore.collection(userUid).doc(uid).delete();
      await firestoreFolder.deleteDocFromFolder(
          folderField: folder, noteUid: uid);
    } on FirebaseException catch (e) {
      return e.message;
    }
    return null;
  }

  Future<int> countNotes() async {
    final snapshot = await _firestore.collection(userUid).get();
    return snapshot.docs.where((doc) => doc.id != 'folders').length;
  }

  Future<DeletionResult> deleteAllUserData() async {
    int deletedNotes = 0;
    try {
      final docs = (await _firestore.collection(userUid).get()).docs;

      for (var i = 0; i < docs.length; i += 500) {
        final chunk = docs.sublist(i, min(i + 500, docs.length));
        final batch = _firestore.batch();
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        deletedNotes += chunk.where((doc) => doc.id != 'folders').length;
      }

      final leftover = await _firestore
          .collection(userUid)
          .get(const GetOptions(source: Source.server));
      if (leftover.docs.isNotEmpty) {
        return DeletionResult(
            deletedNotes: deletedNotes,
            error:
                'ainda restam ${leftover.docs.length} registros no servidor');
      }
    } on FirebaseException catch (e) {
      return DeletionResult(
          deletedNotes: deletedNotes,
          error: e.message ?? 'erro ao apagar os dados');
    }
    return DeletionResult(deletedNotes: deletedNotes);
  }
}
