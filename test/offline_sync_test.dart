import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_again/resources/firestore_methods.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/offline_firestore.dart';

const _uid = 'user-1';

void main() {
  late OfflineFirestore firestore;
  late FirestoreService service;
  final date = DateTime(2026, 11, 24);

  /// Da tempo para as escritas locais acontecerem.
  Future<void> settle() => pumpEventQueue();

  Future<List<QueryDocumentSnapshot<Json>>> notesOn(
          FirebaseFirestore store) async =>
      (await store.collection(_uid).get())
          .docs
          .where((d) => d.id != 'folders')
          .toList();

  Future<Json> foldersOn(FirebaseFirestore store) async =>
      (await store.collection(_uid).doc('folders').get()).data() ?? {};

  Future<String?> createNote({String? noteUid, String folder = 'All'}) =>
      service.addDocument(
          noteUid: noteUid,
          document: '[{"insert":"leite\\n"}]',
          title: 'Mercado',
          searchableDocument: '"leite\\n"',
          folder: folder,
          date: date);

  setUp(() async {
    firestore = OfflineFirestore();
    service = FirestoreService(firestore: firestore, userUid: _uid);
    // A lista de pastas ja existe nos dois lados, como depois do cadastro.
    for (final store in [firestore.local, firestore.server]) {
      await store
          .collection(_uid)
          .doc('folders')
          .set({'All': <String>[], 'Faculdade': <String>[]});
    }
  });

  group('nota criada offline', () {
    test('salvar nao trava esperando o servidor', () async {
      final result = await createNote().timeout(const Duration(seconds: 1));

      expect(result, isNull);
    });

    test('fica no aparelho e ainda nao foi enviada', () async {
      await createNote().timeout(const Duration(seconds: 1));
      await settle();

      expect(await notesOn(firestore.local), hasLength(1));
      expect(await notesOn(firestore.server), isEmpty);
      expect(firestore.pendingWrites, greaterThan(0));
    });

    test('e enviada ao reconectar', () async {
      // Sem await: antes da correcao a chamada so terminava com o servidor.
      final save = createNote();
      await settle();
      expect(await notesOn(firestore.server), isEmpty);

      await firestore.reconnect();
      await save.timeout(const Duration(seconds: 1));
      await settle();

      final notes = await notesOn(firestore.server);
      expect(notes, hasLength(1));
      expect((await foldersOn(firestore.server))['All'], [notes.single.id]);
      expect(firestore.pendingWrites, 0);
    });

    test('chega completa: nota e lista da pasta sobem no mesmo envio',
        () async {
      unawaited(createNote(folder: 'Faculdade'));
      await settle();
      await firestore.reconnect();
      await settle();

      final note = (await notesOn(firestore.server)).single;
      expect(note.data(), {
        'uid': note.id,
        'title': 'Mercado',
        'folder': 'Faculdade',
        'document': '[{"insert":"leite\\n"}]',
        'searchableDocument': '"leite "',
        'date': Timestamp.fromDate(date),
      });
      expect((await foldersOn(firestore.server))['Faculdade'], [note.id]);
      expect(firestore.serverCommits, 1,
          reason: 'nota e pasta precisam subir juntas (atomico), senao o '
              'outro aparelho pode ver a nota sem ela estar na pasta');
    });

    test('sobe mesmo que a lista de pastas ainda nao exista', () async {
      await firestore.local.collection(_uid).doc('folders').delete();
      await firestore.server.collection(_uid).doc('folders').delete();

      unawaited(createNote());
      await settle();
      await firestore.reconnect();
      await settle();

      final notes = await notesOn(firestore.server);
      expect(notes, hasLength(1));
      expect((await foldersOn(firestore.server))['All'], [notes.single.id]);
    });

    test('se o servidor rejeitar, o erro chega em onSyncError', () async {
      String? syncError;
      firestore.rejectWith = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'sem permissao');

      await service.addDocument(
          document: '[]',
          title: '',
          searchableDocument: '""',
          date: date,
          onSyncError: (m) => syncError = m);
      await firestore.reconnect();
      await settle();

      expect(syncError, 'sem permissao');
      expect(await notesOn(firestore.server), isEmpty);
    });
  });

  group('envio repetido nao gera duplicata', () {
    test('salvar duas vezes a mesma nota offline gera uma nota so', () async {
      // A tela gera o id uma vez e reusa em todo toque no "Save".
      await createNote(noteUid: 'nota-1');
      await createNote(noteUid: 'nota-1');
      await settle();

      await firestore.reconnect();
      await settle();

      final notes = await notesOn(firestore.server);
      expect(notes.map((n) => n.id), ['nota-1']);
      expect((await foldersOn(firestore.server))['All'], ['nota-1']);
      expect(await notesOn(firestore.local), hasLength(1));
    });

    test('reenviar depois de ja sincronizada nao duplica', () async {
      await firestore.reconnect();
      await createNote(noteUid: 'nota-1');
      await settle();
      await createNote(noteUid: 'nota-1');
      await settle();

      expect((await notesOn(firestore.server)).map((n) => n.id), ['nota-1']);
      expect((await foldersOn(firestore.server))['All'], ['nota-1']);
    });

    test('sem id informado, cada nota nova ganha um id proprio', () async {
      await createNote();
      await createNote();
      await firestore.reconnect();
      await settle();

      final ids = (await notesOn(firestore.server)).map((n) => n.id).toSet();
      expect(ids, hasLength(2));
    });
  });

  group('nota editada offline', () {
    Future<String?> editNote({required String from, required String to}) =>
        service.updateDocument(
            document: '[]',
            searchableDocument: '"pao"',
            title: 'Padaria',
            previousFolder: from,
            folder: to,
            noteUid: 'nota-1',
            date: date);

    setUp(() async {
      await firestore.reconnect();
      await createNote(noteUid: 'nota-1');
      await settle();
      firestore.online = false;
    });

    test('salvar nao trava e a edicao sobe ao reconectar', () async {
      final result = await editNote(from: 'All', to: 'All')
          .timeout(const Duration(seconds: 1));
      await settle();
      expect(result, isNull);
      expect((await notesOn(firestore.server)).single['title'], 'Mercado');

      await firestore.reconnect();
      await settle();

      final notes = await notesOn(firestore.server);
      expect(notes, hasLength(1));
      expect(notes.single['title'], 'Padaria');
    });

    test('trocar de pasta move a nota nas listas no mesmo envio', () async {
      final commitsBefore = firestore.serverCommits;
      await editNote(from: 'All', to: 'Faculdade');
      await firestore.reconnect();
      await settle();

      final folders = await foldersOn(firestore.server);
      expect(folders['All'], isEmpty);
      expect(folders['Faculdade'], ['nota-1']);
      expect(firestore.serverCommits - commitsBefore, 1);
    });
  });

  group('nota apagada offline', () {
    setUp(() async {
      await firestore.reconnect();
      await createNote(noteUid: 'nota-1');
      await settle();
      firestore.online = false;
    });

    test('some do aparelho na hora e do servidor ao reconectar', () async {
      final result = await service
          .deleteNote(uid: 'nota-1', folder: 'All')
          .timeout(const Duration(seconds: 1));
      await settle();

      expect(result, isNull);
      expect(await notesOn(firestore.local), isEmpty);

      await firestore.reconnect();
      await settle();

      expect(await notesOn(firestore.server), isEmpty);
      expect((await foldersOn(firestore.server))['All'], isEmpty);
    });
  });
}
