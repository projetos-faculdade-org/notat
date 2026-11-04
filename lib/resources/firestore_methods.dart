import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_again/models/deletion_result.dart';
import 'package:flutter_application_again/models/note.dart';
import 'package:flutter_application_again/resources/auth_methods.dart';
import 'package:flutter_application_again/resources/firstore_folder_methods.dart';
import 'package:flutter_application_again/resources/sync_in_background.dart';

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

  /// Salva uma nota nova e a coloca em [folder].
  ///
  /// [uid] e o id do documento e vem de quem chama: a tela gera um por nota e
  /// usa o mesmo em todas as tentativas de salvar. Assim, repetir o envio
  /// (o SDK reenviando a fila ou o usuario salvando de novo) grava por cima da
  /// mesma nota em vez de criar outra, e o `arrayUnion` nao repete o id na
  /// pasta.
  ///
  /// As escritas nao sao aguardadas: a nota aparece na lista na hora e fica
  /// pendente ate o servidor confirmar (ver [syncInBackground]). Se o servidor
  /// recusar, a mensagem vai para [onSyncError].
  Future<String?> addDocument(
      {required String uid,
      required String document,
      required String title,
      required String searchableDocument,
      String folder = 'All',
      required DateTime date,
      void Function(String message)? onSyncError}) async {
    final Note note = Note.fromEditor(
        folder: folder,
        document: document,
        searchableDocument: searchableDocument,
        date: date,
        uid: uid,
        title: title);

    syncInBackground(_firestore.collection(userUid).doc(uid).set(note.toJson()),
        fallback: 'Could not save the note', onSyncError: onSyncError);
    await firestoreFolder.addDocToFolder(
        folderField: folder, noteUid: uid, onSyncError: onSyncError);
    return null;
  }

  /// Regrava a nota [noteUid] e, se a pasta mudou, move a nota de pasta.
  /// Mesmas regras de [addDocument]: nada e aguardado e repetir o envio nao
  /// duplica a nota.
  Future<String?> updateDocument(
      {required String document,
      required String searchableDocument,
      required String title,
      required String previousFolder,
      required String folder,
      required String noteUid,
      required DateTime date,
      void Function(String message)? onSyncError}) async {
    final Note note = Note.fromEditor(
        folder: folder,
        searchableDocument: searchableDocument,
        document: document,
        date: date,
        uid: noteUid,
        title: title);

    syncInBackground(
        _firestore.collection(userUid).doc(noteUid).set(note.toJson()),
        fallback: 'Could not save the note',
        onSyncError: onSyncError);
    await firestoreFolder.updateFolder(
        folderField: folder,
        noteUid: noteUid,
        previousFolder: previousFolder,
        onSyncError: onSyncError);
    return null;
  }

  getNote({required String uid}) async {
    final snapshot = await _firestore.collection(userUid).doc(uid).get();
    return snapshot.data();
  }

  clearAllNotes() async {
    final folder = _firestore.collection(userUid).doc('folders');

    try {
      await _firestore.collection(userUid).get().then((value) {
        //Delete all docs except the folder doc
        for (DocumentSnapshot ds in value.docs) {
          if (ds.reference != folder) {
            ds.reference.delete();
          }
        }
      });
      await firestoreFolder.clearFolders();
    } on FirebaseException catch (e) {
      return e.message;
    }
  }

  /// Apaga as notas de [folder] e grava [folderValue] no campo da pasta.
  ///
  /// Le as notas do cache local para nao depender do servidor. A escrita em
  /// lote vale localmente assim que e feita, entao os listeners atualizam a
  /// tela na hora, e sem internet ela fica na fila ate a conexao voltar. Por
  /// isso o Future do commit nao e aguardado: sem internet ele nao termina.
  ///
  /// Devolve uma mensagem se a exclusao nem comecou. Se o servidor rejeitar
  /// depois, o Firestore desfaz a escrita local e [onSyncError] e chamado.
  Future<String?> deleteDocsOfFolder(String folder,
      {required Object folderValue,
      void Function(String message)? onSyncError}) async {
    const fallback = 'Could not delete the notes';
    final user = _firestore.collection(userUid);
    try {
      final notes = await user
          .where('folder', isEqualTo: folder)
          .get(const GetOptions(source: Source.cache));

      final commits = <Future<void>>[];
      var batch = _firestore.batch();
      var operations = 0;
      for (final note in notes.docs) {
        batch.delete(note.reference);
        if (++operations == 500) {
          commits.add(batch.commit());
          batch = _firestore.batch();
          operations = 0;
        }
      }
      batch.update(user.doc('folders'), {folder: folderValue});
      commits.add(batch.commit());

      unawaited(Future.wait(commits).then<void>((_) {}, onError: (Object e) {
        onSyncError
            ?.call(e is FirebaseException ? e.message ?? fallback : fallback);
      }));
    } on FirebaseException catch (e) {
      return e.message ?? fallback;
    }
    return null;
  }

  Future<String?> deleteNote(
      {required String uid,
      required String folder,
      void Function(String message)? onSyncError}) async {
    try {
      await _firestore.collection(userUid).doc(uid).delete();
      await firestoreFolder.deleteDocFromFolder(
          folderField: folder, noteUid: uid, onSyncError: onSyncError);
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
