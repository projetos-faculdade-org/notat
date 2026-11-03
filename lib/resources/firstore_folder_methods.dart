import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_again/resources/auth_methods.dart';
import 'package:flutter_application_again/resources/firestore_methods.dart';

class FirestoreFolderService {
  final FirebaseFirestore _firestore;
  final String userUid;

  FirestoreFolderService({FirebaseFirestore? firestore, String? userUid})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        userUid = userUid ?? AuthService().useUid;

  /// Apaga as notas da pasta e mantem a pasta, agora vazia.
  /// Ver [FirestoreService.deleteDocsOfFolder].
  Future<String?> emptyFolder(String name,
      {void Function(String message)? onSyncError}) {
    return FirestoreService(firestore: _firestore, userUid: userUid)
        .deleteDocsOfFolder(name,
            folderValue: <String>[], onSyncError: onSyncError);
  }

  createMainFolder() async {
    //create the folder 'All' so you have a document to start with
    List<String> notes = [];
    try {
      await _firestore.collection(userUid).doc('folders').set({'All': notes});
    } on FirebaseException catch (e) {
      return e.message;
    }
  }

  Future<String?> createFolder(String name) async {
    List<String> notes = [];
    try {
      await _firestore.collection(userUid).doc('folders').update({name: notes});
    } on FirebaseException catch (e) {
      return e.message;
    }
    return null;
  }

  /// Apaga as notas da pasta e a propria pasta.
  /// Ver [FirestoreService.deleteDocsOfFolder].
  Future<String?> deleteFolder(String name,
      {void Function(String message)? onSyncError}) async {
    if (name == 'All') {
      return null;
    }
    return FirestoreService(firestore: _firestore, userUid: userUid)
        .deleteDocsOfFolder(name,
            folderValue: FieldValue.delete(), onSyncError: onSyncError);
  }

  Future<String?> addDocToFolder(
      {required String folderField,
      required String noteUid,
      void Function(String message)? onSyncError}) async {
    _syncInBackground(
        _firestore.collection(userUid).doc('folders').update({
          folderField: FieldValue.arrayUnion([noteUid])
        }),
        onSyncError);
    return null;
  }

  Future<String?> updateFolder(
      {required String folderField,
      required String noteUid,
      required String previousFolder}) async {
    try {
      //if the user is updating the folder, delete the note uid from the
      // previous folder and add the note uid to the new folder, otherwise don't change anything
      if (previousFolder != folderField) {
        await _firestore.collection(userUid).doc('folders').update({
          previousFolder: FieldValue.arrayRemove([noteUid])
        });

        await _firestore.collection(userUid).doc('folders').update({
          folderField: FieldValue.arrayUnion([noteUid])
        });
      }
    } on FirebaseException catch (e) {
      return e.message;
    }
    return null;
  }

  Future<String?> deleteDocFromFolder(
      {required String folderField,
      required String noteUid,
      void Function(String message)? onSyncError}) async {
    _syncInBackground(
        _firestore.collection(userUid).doc('folders').update({
          folderField: FieldValue.arrayRemove([noteUid])
        }),
        onSyncError);
    return null;
  }

  /// Nao aguarda a escrita: sem internet o Future so termina quando a conexao
  /// volta (ver [FirestoreService.deleteDocsOfFolder]). Se o servidor rejeitar,
  /// a mensagem vai para [onSyncError] em vez de ser engolida.
  void _syncInBackground(
      Future<void> write, void Function(String message)? onSyncError) {
    const fallback = 'Could not update the folder';
    unawaited(write.then<void>((_) {}, onError: (Object e) {
      final message = e is FirebaseException ? e.message ?? fallback : fallback;
      if (onSyncError != null) {
        onSyncError(message);
      } else {
        debugPrint(message);
      }
    }));
  }

  Future<String?> clearFolders() async {
    //Go inside the 'folder' doc, and set all folders to []
    try {
      await _firestore
          .collection(userUid)
          .doc('folders')
          .get()
          .then((value) => value.data()?.forEach((key, value) {
                _firestore.collection(userUid).doc('folders').update({key: []});
              }));
    } on FirebaseException catch (e) {
      return e.message;
    }
    return null;
  }
}
