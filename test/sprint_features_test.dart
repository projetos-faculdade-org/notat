import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_application_again/models/deletion_result.dart';
import 'package:flutter_application_again/models/note.dart';
import 'package:flutter_application_again/resources/firestore_methods.dart';
import 'package:flutter_application_again/resources/firstore_folder_methods.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/offline_firestore.dart';

const _uid = 'user-1';

/// Funcionalidades entregues nas sprints anteriores, conferidas de novo:
/// pastas, excluir meus dados, limpar todas as notas e notas offline.
void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreService notes;
  late FirestoreFolderService folders;
  final date = DateTime(2026, 11, 24);

  Future<Json> foldersDoc() async =>
      (await firestore.collection(_uid).doc('folders').get()).data()!;

  Future<List<String>> noteIds() async => (await firestore.collection(_uid).get())
      .docs
      .map((d) => d.id)
      .where((id) => id != 'folders')
      .toList();

  Future<void> seedNote(String id, String folder) async {
    await notes.addDocument(
        uid: id,
        document: '[]',
        title: id,
        searchableDocument: '""',
        folder: folder,
        date: date);
    await pumpEventQueue();
  }

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    notes = FirestoreService(firestore: firestore, userUid: _uid);
    folders = FirestoreFolderService(firestore: firestore, userUid: _uid);
    await folders.createMainFolder();
  });

  group('pastas', () {
    test('o cadastro cria a pasta All vazia', () async {
      expect(await foldersDoc(), {'All': <String>[]});
    });

    test('criar pasta adiciona uma lista vazia', () async {
      expect(await folders.createFolder('Faculdade'), isNull);

      expect(await foldersDoc(), {'All': <String>[], 'Faculdade': <String>[]});
    });

    test('nota criada entra na lista da pasta escolhida', () async {
      await folders.createFolder('Faculdade');
      await seedNote('n1', 'Faculdade');

      expect((await foldersDoc())['Faculdade'], ['n1']);
      expect((await foldersDoc())['All'], isEmpty);
    });

    test('apagar nota tira o id da lista da pasta', () async {
      await seedNote('n1', 'All');

      expect(await notes.deleteNote(uid: 'n1', folder: 'All'), isNull);
      await pumpEventQueue();

      expect(await noteIds(), isEmpty);
      expect((await foldersDoc())['All'], isEmpty);
    });
  });

  group('abrir nota para editar', () {
    test('getNote devolve os campos salvos', () async {
      await seedNote('n1', 'All');

      final data = await notes.getNote(uid: 'n1');

      expect(data['title'], 'n1');
      expect(data['folder'], 'All');
    });

    test('nota criada offline abre antes de sincronizar', () async {
      final offline = OfflineFirestore();
      final service = FirestoreService(firestore: offline, userUid: _uid);
      await service.addDocument(
          uid: 'n1',
          document: '[]',
          title: 'Offline',
          searchableDocument: '""',
          date: date);
      await pumpEventQueue();

      final data = await service.getNote(uid: 'n1');

      expect(data['title'], 'Offline');
      expect(offline.pendingWrites, greaterThan(0));
    });
  });

  group('limpar todas as notas', () {
    test('apaga as notas e esvazia as pastas, mantendo as pastas', () async {
      await folders.createFolder('Faculdade');
      await seedNote('n1', 'All');
      await seedNote('n2', 'Faculdade');

      await notes.clearAllNotes();
      await pumpEventQueue();

      expect(await noteIds(), isEmpty);
      expect(await foldersDoc(), {'All': [], 'Faculdade': []});
    });
  });

  group('excluir meus dados', () {
    test('countNotes nao conta o documento de pastas', () async {
      await seedNote('n1', 'All');
      await seedNote('n2', 'All');

      expect(await notes.countNotes(), 2);
    });

    test('apaga notas e pastas e informa quantas notas foram apagadas',
        () async {
      await seedNote('n1', 'All');
      await seedNote('n2', 'All');

      final result = await notes.deleteAllUserData();

      expect(result.success, isTrue);
      expect(result.deletedNotes, 2);
      expect((await firestore.collection(_uid).get()).docs, isEmpty);
    });

    test('mais de 500 documentos sao apagados em varios lotes', () async {
      for (var i = 0; i < 520; i++) {
        await firestore.collection(_uid).doc('n$i').set({'folder': 'All'});
      }

      final result = await notes.deleteAllUserData();

      expect(result.deletedNotes, 520);
      expect((await firestore.collection(_uid).get()).docs, isEmpty);
    });

    test('DeletionResult so e sucesso sem erro', () {
      expect(const DeletionResult(deletedNotes: 3).success, isTrue);
      expect(const DeletionResult(error: 'falhou').success, isFalse);
    });
  });

  group('model Note', () {
    test('toJson tem todos os campos que as telas leem', () {
      final json = Note.fromEditor(
              document: '[]',
              searchableDocument: '""',
              title: '',
              folder: 'All',
              date: date,
              uid: 'n1')
          .toJson();

      expect(json.keys,
          containsAll(['title', 'folder', 'date', 'uid', 'document']));
    });
  });
}
