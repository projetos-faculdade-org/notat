import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  /// Salva uma nota nova.
  ///
  /// [noteUid] deve ser gerado uma vez pela tela e reusado se o usuario
  /// salvar de novo: como a nota e gravada com `set` no documento desse id,
  /// salvar duas vezes sobrescreve a mesma nota em vez de criar outra.
  /// Sem [noteUid], um id novo e gerado.
  ///
  /// Ver [_commitInBackground] para o comportamento sem internet.
  Future<String?> addDocument(
      {required String document,
      required String title,
      required String searchableDocument,
      String folder = 'All',
      required DateTime date,
      String? noteUid,
      void Function(String message)? onSyncError}) async {
    final String uid = noteUid ?? const Uuid().v4();
    final Note note = Note.fromEditor(
        folder: folder,
        document: document,
        searchableDocument: searchableDocument,
        date: date,
        uid: uid,
        title: title);

    final user = _firestore.collection(userUid);
    final batch = _firestore.batch()
      ..set(user.doc(uid), note.toJson())
      ..set(
          user.doc('folders'),
          {
            folder: FieldValue.arrayUnion([uid])
          },
          SetOptions(merge: true));
    return _commitInBackground(batch, 'Could not save the note', onSyncError);
  }

  /// Salva a edicao de uma nota e, se ela mudou de pasta, move o id entre
  /// as listas das pastas no mesmo envio.
  /// Ver [_commitInBackground] para o comportamento sem internet.
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

    final user = _firestore.collection(userUid);
    final batch = _firestore.batch()..set(user.doc(noteUid), note.toJson());
    if (previousFolder != folder) {
      batch.set(
          user.doc('folders'),
          {
            previousFolder: FieldValue.arrayRemove([noteUid]),
            folder: FieldValue.arrayUnion([noteUid]),
          },
          SetOptions(merge: true));
    }
    return _commitInBackground(
        batch, 'Could not update the note', onSyncError);
  }

  /// Envia [batch] sem esperar o servidor.
  ///
  /// O Firestore aplica a escrita no cache do aparelho assim que o commit e
  /// chamado (a tela atualiza pelos listeners), guarda a escrita na fila
  /// persistida e a envia sozinho quando a conexao volta. O Future do commit
  /// so termina quando o servidor confirma, entao sem internet ele fica
  /// pendente: aguarda-lo travava a tela e levava o usuario a salvar de novo.
  ///
  /// Nota e lista da pasta vao no mesmo batch para chegarem juntas (atomico)
  /// ao servidor. Se o servidor rejeitar, o Firestore desfaz a escrita local
  /// e a mensagem vai para [onSyncError].
  String? _commitInBackground(WriteBatch batch, String fallback,
      void Function(String message)? onSyncError) {
    try {
      unawaited(batch.commit().then<void>((_) {}, onError: (Object e) {
        final message =
            e is FirebaseException ? e.message ?? fallback : fallback;
        if (onSyncError != null) {
          onSyncError(message);
        } else {
          debugPrint(message);
        }
      }));
    } on FirebaseException catch (e) {
      return e.message ?? fallback;
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

  /// Apaga a nota e tira o id dela da lista da pasta, no mesmo envio.
  /// Ver [_commitInBackground] para o comportamento sem internet.
  Future<String?> deleteNote(
      {required String uid,
      required String folder,
      void Function(String message)? onSyncError}) async {
    final user = _firestore.collection(userUid);
    final batch = _firestore.batch()
      ..delete(user.doc(uid))
      ..set(
          user.doc('folders'),
          {
            folder: FieldValue.arrayRemove([uid])
          },
          SetOptions(merge: true));
    return _commitInBackground(
        batch, 'Could not delete the note', onSyncError);
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
