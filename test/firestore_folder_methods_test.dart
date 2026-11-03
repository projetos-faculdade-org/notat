import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_application_again/resources/firstore_folder_methods.dart';
import 'package:flutter_test/flutter_test.dart';

const uid = 'user-1';

/// Firestore em que o update do doc 'folders' devolve o Future de [onUpdate].
/// O resto da API nao e usado por addDocToFolder/deleteDocFromFolder.
class _Firestore implements FirebaseFirestore {
  _Firestore(this.onUpdate);
  final Future<void> Function() onUpdate;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #collection) {
      return _Collection(onUpdate);
    }
    return super.noSuchMethod(invocation);
  }
}

// ignore: subtype_of_sealed_class
class _Collection implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.onUpdate);
  final Future<void> Function() onUpdate;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #doc) {
      return _Document(onUpdate);
    }
    return super.noSuchMethod(invocation);
  }
}

// ignore: subtype_of_sealed_class
class _Document implements DocumentReference<Map<String, dynamic>> {
  _Document(this.onUpdate);
  final Future<void> Function() onUpdate;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #update) {
      return onUpdate();
    }
    return super.noSuchMethod(invocation);
  }
}

/// Deixa as escritas que nao foram aguardadas terminarem.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  group('caminho feliz (passa antes e depois)', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreFolderService service;

    Future<Map<String, dynamic>> folders() async =>
        (await firestore.collection(uid).doc('folders').get()).data()!;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      service = FirestoreFolderService(firestore: firestore, userUid: uid);
      await firestore
          .collection(uid)
          .doc('folders')
          .set({'All': <String>[], 'Work': <String>[]});
    });

    test('addDocToFolder coloca a nota na pasta e devolve null', () async {
      final result =
          await service.addDocToFolder(folderField: 'Work', noteUid: 'n1');
      await settle();

      expect(result, isNull);
      expect((await folders())['Work'], ['n1']);
    });

    test('deleteDocFromFolder tira a nota da pasta e devolve null', () async {
      await service.addDocToFolder(folderField: 'Work', noteUid: 'n1');
      await settle();

      final result =
          await service.deleteDocFromFolder(folderField: 'Work', noteUid: 'n1');
      await settle();

      expect(result, isNull);
      expect((await folders())['Work'], isEmpty);
    });
  });

  group('sem internet (passa antes e depois)', () {
    // Offline, o Future da escrita so termina quando a conexao volta.
    // A funcao nao pode ficar esperando por ele (mesma regra do Card 1).
    late FirestoreFolderService service;

    setUp(() {
      final neverSynced = Completer<void>().future;
      service = FirestoreFolderService(
          firestore: _Firestore(() => neverSynced), userUid: uid);
    });

    test('addDocToFolder nao trava esperando o servidor', () async {
      expect(
          await service
              .addDocToFolder(folderField: 'Work', noteUid: 'n1')
              .timeout(const Duration(seconds: 1)),
          isNull);
    });

    test('deleteDocFromFolder nao trava esperando o servidor', () async {
      expect(
          await service
              .deleteDocFromFolder(folderField: 'Work', noteUid: 'n1')
              .timeout(const Duration(seconds: 1)),
          isNull);
    });
  });

  group('servidor rejeita a escrita (falhava antes: erro era engolido)', () {
    // Antes, o update sem await ficava dentro de um try/catch que nunca
    // pegava nada: a FirebaseException escapava como erro nao tratado,
    // o que faz o teste falhar.
    late FirestoreFolderService service;

    setUp(() {
      service = FirestoreFolderService(
          firestore: _Firestore(() => Future.error(FirebaseException(
              plugin: 'cloud_firestore', message: 'permission-denied'))),
          userUid: uid);
    });

    test('addDocToFolder trata o erro do servidor', () async {
      await service.addDocToFolder(folderField: 'Work', noteUid: 'n1');
      await settle();
    });

    test('deleteDocFromFolder trata o erro do servidor', () async {
      await service.deleteDocFromFolder(folderField: 'Work', noteUid: 'n1');
      await settle();
    });
  });
}
