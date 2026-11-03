// Os dubles abaixo implementam classes seladas do Firestore so para simular
// a rede.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_application_again/resources/firestore_methods.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Json = Map<String, dynamic>;

const _user = 'user-1';

/// Uma escrita que o app fez e que o servidor ainda nao confirmou.
class _PendingWrite {
  _PendingWrite(this.path, this.apply);

  final String path;

  /// Repete a escrita em outro banco (aqui, no "servidor").
  final Future<void> Function(FirebaseFirestore db) apply;
  final ack = Completer<void>();
}

/// Simula o que o SDK do Firestore faz com persistencia ligada:
/// - a escrita vale no banco local na hora (a nota aparece na lista);
/// - ela entra numa fila de pendencias e o Future so termina quando o
///   servidor confirma;
/// - se a confirmacao nao chega, a escrita continua na fila e e reenviada
///   igual quando a conexao volta.
///
/// [local] e o que o app enxerga; [server] e o que chegou ao servidor.
class _Network implements FirebaseFirestore {
  _Network(this.local, this.server);

  final FakeFirebaseFirestore local;
  final FakeFirebaseFirestore server;

  /// Fila de pendencias, na ordem em que as escritas foram feitas.
  final pending = <_PendingWrite>[];

  /// Quantas escritas foram enviadas ao servidor, contando reenvios.
  int sends = 0;

  Future<void> _write(
      String path, Future<void> Function(FirebaseFirestore db) apply) {
    final write = _PendingWrite(path, apply);
    pending.add(write);
    return apply(local).then((_) => write.ack.future);
  }

  /// A conexao volta e a fila e enviada. Com [ackLost], o servidor grava,
  /// mas a confirmacao se perde no caminho: as escritas continuam na fila.
  Future<void> reconnect({bool ackLost = false}) async {
    for (final write in List.of(pending)) {
      sends++;
      await write.apply(server);
      if (!ackLost) {
        pending.remove(write);
        write.ack.complete();
      }
    }
  }

  /// O servidor recusa tudo o que esta na fila.
  void reject(FirebaseException error) {
    for (final write in pending) {
      write.ack.completeError(error);
    }
    pending.clear();
  }

  @override
  CollectionReference<_Json> collection(String path) =>
      _Collection(this, local.collection(path));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Collection implements CollectionReference<_Json> {
  _Collection(this.network, this.inner);

  final _Network network;
  final CollectionReference<_Json> inner;

  @override
  DocumentReference<_Json> doc([String? path]) =>
      _Document(network, inner.doc(path));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Document implements DocumentReference<_Json> {
  _Document(this.network, this.inner);

  final _Network network;
  final DocumentReference<_Json> inner;

  @override
  String get id => inner.id;

  @override
  String get path => inner.path;

  @override
  Future<void> set(_Json data, [SetOptions? options]) =>
      network._write(path, (db) => db.doc(path).set(data, options));

  @override
  Future<void> update(Map<Object, Object?> data) =>
      network._write(path, (db) => db.doc(path).update(data));

  @override
  Future<DocumentSnapshot<_Json>> get([GetOptions? options]) => inner.get();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeFirebaseFirestore local;
  late FakeFirebaseFirestore server;
  late _Network network;
  late FirestoreService service;
  final date = DateTime(2026, 11, 3);

  /// Notas (sem o doc 'folders') de [db], por id.
  Future<Map<String, _Json>> notesIn(FirebaseFirestore db) async {
    final docs = (await db.collection(_user).get()).docs;
    return {
      for (final doc in docs.where((d) => d.id != 'folders')) doc.id: doc.data()
    };
  }

  Future<_Json> foldersIn(FirebaseFirestore db) async =>
      (await db.collection(_user).doc('folders').get()).data()!;

  Future<String?> addNote(String uid,
          {String document = '[]',
          String title = 'Mercado',
          String folder = 'All',
          void Function(String message)? onSyncError}) =>
      service
          .addDocument(
              uid: uid,
              document: document,
              title: title,
              searchableDocument: jsonEncode('texto'),
              folder: folder,
              date: date,
              onSyncError: onSyncError)
          // Sem internet o servidor nao responde: salvar nao pode esperar.
          .timeout(const Duration(seconds: 1));

  /// Deixa terminar o que nao foi aguardado.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    local = FakeFirebaseFirestore();
    server = FakeFirebaseFirestore();
    network = _Network(local, server);
    service = FirestoreService(firestore: network, userUid: _user);
    // A lista de pastas ja estava sincronizada antes de cair a internet.
    for (final db in [local, server]) {
      await db
          .collection(_user)
          .doc('folders')
          .set({'All': <String>[], 'Faculdade': <String>[]});
    }
  });

  group('nota escrita sem internet', () {
    test(
        'salvar nao espera o servidor: a nota aparece na lista e fica pendente',
        () async {
      final result = await addNote('n1');
      await settle();

      expect(result, isNull);
      expect((await notesIn(local)).keys, ['n1']);
      expect((await foldersIn(local))['All'], ['n1']);
      expect(await notesIn(server), isEmpty);
      expect(network.pending.map((w) => w.path), contains('$_user/n1'));
    });

    test('quando a conexao volta, a nota e enviada ao servidor uma unica vez',
        () async {
      await addNote('n1');
      await settle();

      await network.reconnect();

      expect(network.pending, isEmpty);
      expect(network.sends, 2, reason: 'uma escrita da nota e uma da pasta');
      expect((await notesIn(server)).keys, ['n1']);
      expect((await foldersIn(server))['All'], ['n1']);
    });

    test('o conteudo chega completo ao servidor', () async {
      // Documento do editor com acentos, emoji, quebras de linha e formatacao,
      // grande o bastante para pegar qualquer corte.
      final document = jsonEncode([
        {
          'insert': 'Lista de compras ✅\n',
          'attributes': {'bold': true}
        },
        {'insert': 'pão, café, açúcar 🍞☕\n' * 2000},
        {'insert': 'fim "entre aspas" \\ barra\n'},
      ]);

      await addNote('n1',
          document: document, title: 'Ação: compras 🛒', folder: 'Faculdade');
      await settle();
      await network.reconnect();

      final note = (await notesIn(server))['n1']!;
      expect(note['document'], document);
      expect(note['title'], 'Ação: compras 🛒');
      expect(note['folder'], 'Faculdade');
      expect(note['uid'], 'n1');
      expect((note['date'] as Timestamp).toDate(), date);
      expect((await foldersIn(server))['Faculdade'], ['n1']);
    });

    test('se o servidor recusar, o erro chega em onSyncError', () async {
      final messages = <String>[];
      await addNote('n1', onSyncError: messages.add);
      await settle();

      network.reject(FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'sem permissao'));
      await settle();

      expect(messages, contains('sem permissao'));
    });
  });

  group('reenvio apos falha', () {
    test('o envio falha no meio e e repetido: a nota nao duplica', () async {
      await addNote('n1');
      await settle();

      // O servidor grava, mas a confirmacao nao chega ao app.
      await network.reconnect(ackLost: true);
      expect(network.pending, isNotEmpty);

      // A conexao volta de novo e a fila e reenviada.
      await network.reconnect();

      expect(network.pending, isEmpty);
      expect(network.sends, 4, reason: 'nota e pasta enviadas duas vezes');
      expect((await notesIn(server)).keys, ['n1']);
      expect((await foldersIn(server))['All'], ['n1']);
    });

    test('salvar a mesma nota de novo (mesmo id) nao cria outra', () async {
      // Ex.: o usuario toca em salvar mais de uma vez na mesma tela.
      await addNote('n1', title: 'primeira versao');
      await addNote('n1', title: 'segunda versao');
      await settle();
      await network.reconnect();

      final notes = await notesIn(server);
      expect(notes.keys, ['n1']);
      expect(notes['n1']!['title'], 'segunda versao');
      expect((await foldersIn(server))['All'], ['n1']);
      expect((await notesIn(local)).keys, ['n1']);
    });

    test('notas diferentes continuam separadas', () async {
      await addNote('n1');
      await addNote('n2');
      await settle();
      await network.reconnect(ackLost: true);
      await network.reconnect();

      expect((await notesIn(server)).keys, unorderedEquals(['n1', 'n2']));
      expect((await foldersIn(server))['All'], ['n1', 'n2']);
    });
  });

  group('editar nota sem internet', () {
    setUp(() async {
      for (final db in [local, server]) {
        await db.collection(_user).doc('n1').set({
          'uid': 'n1',
          'title': 'Mercado',
          'folder': 'All',
          'document': '[]'
        });
        await db.collection(_user).doc('folders').set({
          'All': ['n1'],
          'Faculdade': <String>[]
        });
      }
    });

    Future<String?> moveToFaculdade() => service
        .updateDocument(
            document: '[{"insert":"editada\\n"}]',
            searchableDocument: jsonEncode('editada'),
            title: 'Mercado',
            previousFolder: 'All',
            folder: 'Faculdade',
            noteUid: 'n1',
            date: date)
        .timeout(const Duration(seconds: 1));

    test('salvar nao espera o servidor e a mudanca aparece na hora', () async {
      expect(await moveToFaculdade(), isNull);
      await settle();

      expect((await notesIn(local))['n1']!['folder'], 'Faculdade');
      final folders = await foldersIn(local);
      expect(folders['All'], isEmpty);
      expect(folders['Faculdade'], ['n1']);
      expect((await notesIn(server))['n1']!['folder'], 'All');
    });

    test('com reenvio, a nota troca de pasta uma vez so e sem duplicar',
        () async {
      await moveToFaculdade();
      await settle();
      await network.reconnect(ackLost: true);
      await network.reconnect();

      final notes = await notesIn(server);
      expect(notes.keys, ['n1']);
      expect(notes['n1']!['document'], '[{"insert":"editada\\n"}]');
      final folders = await foldersIn(server);
      expect(folders['All'], isEmpty);
      expect(folders['Faculdade'], ['n1']);
    });
  });
}
