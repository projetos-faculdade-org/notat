// Os dublês abaixo implementam Query (classe selada) só para simular o servidor.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_application_again/resources/firstore_folder_methods.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Json = Map<String, dynamic>;

const _uid = 'user-1';

/// Simula o que o Firestore real faz e o FakeFirebaseFirestore nao faz:
/// - a leitura padrao passa pelo servidor, e por isso demora;
/// - a leitura do cache local responde na hora;
/// - a escrita vale localmente assim que e feita, mas o Future dela so termina
///   quando o servidor confirma (sem internet, ele fica pendente).
class _SlowServerFirestore implements FirebaseFirestore {
  _SlowServerFirestore(this.local);

  final FakeFirebaseFirestore local;

  /// Resposta do servidor as leituras padrao.
  final serverRead = Completer<void>();

  /// Confirmacao do servidor as escritas.
  final serverAck = Completer<void>();

  /// Quando preenchido, a leitura do cache local falha com esta excecao.
  FirebaseException? cacheError;

  @override
  CollectionReference<_Json> collection(String path) =>
      _SlowCollection(this, local.collection(path));

  @override
  WriteBatch batch() => _SlowBatch(this, local.batch());

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _SlowCollection implements CollectionReference<_Json> {
  _SlowCollection(this.owner, this.inner);

  final _SlowServerFirestore owner;
  final CollectionReference<_Json> inner;

  @override
  DocumentReference<_Json> doc([String? path]) => inner.doc(path);

  @override
  Query<_Json> where(Object field,
          {Object? isEqualTo,
          Object? isNotEqualTo,
          Object? isLessThan,
          Object? isLessThanOrEqualTo,
          Object? isGreaterThan,
          Object? isGreaterThanOrEqualTo,
          Object? arrayContains,
          Iterable<Object?>? arrayContainsAny,
          Iterable<Object?>? whereIn,
          Iterable<Object?>? whereNotIn,
          bool? isNull}) =>
      _SlowQuery(owner, inner.where(field, isEqualTo: isEqualTo));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _SlowQuery implements Query<_Json> {
  _SlowQuery(this.owner, this.inner);

  final _SlowServerFirestore owner;
  final Query<_Json> inner;

  @override
  Future<QuerySnapshot<_Json>> get([GetOptions? options]) async {
    if (options?.source == Source.cache) {
      final error = owner.cacheError;
      if (error != null) throw error;
    } else {
      await owner.serverRead.future;
    }
    return inner.get();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _SlowBatch implements WriteBatch {
  _SlowBatch(this.owner, this.inner);

  final _SlowServerFirestore owner;
  final WriteBatch inner;

  @override
  void delete(DocumentReference document) => inner.delete(document);

  @override
  void update<T>(DocumentReference<T> document, T data) =>
      inner.update(document, data);

  @override
  Future<void> commit() async {
    await inner.commit();
    await owner.serverAck.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  late FakeFirebaseFirestore local;
  late _SlowServerFirestore firestore;
  late FirestoreFolderService service;

  Future<List<String>> notesIn(String folder) async {
    final snapshot = await local
        .collection(_uid)
        .where('folder', isEqualTo: folder)
        .get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<_Json> foldersDoc() async =>
      (await local.collection(_uid).doc('folders').get()).data()!;

  /// Da tempo para o fluxo avancar sem depender do servidor.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    local = FakeFirebaseFirestore();
    firestore = _SlowServerFirestore(local);
    service = FirestoreFolderService(firestore: firestore, userUid: _uid);

    final user = local.collection(_uid);
    await user.doc('folders').set({
      'All': ['n3'],
      'Faculdade': ['n1', 'n2'],
    });
    await user.doc('n1').set({'folder': 'Faculdade', 'uid': 'n1'});
    await user.doc('n2').set({'folder': 'Faculdade', 'uid': 'n2'});
    await user.doc('n3').set({'folder': 'All', 'uid': 'n3'});
  });

  group('esvaziar pasta', () {
    test('a lista fica vazia na hora, sem esperar resposta do servidor',
        () async {
      unawaited(service.emptyFolder('Faculdade'));
      await settle();

      expect(await notesIn('Faculdade'), isEmpty);
    });

    test('so apaga as notas da pasta e mantem a pasta, agora sem notas',
        () async {
      unawaited(service.emptyFolder('Faculdade'));
      await settle();

      expect(await notesIn('All'), ['n3']);
      final folders = await foldersDoc();
      expect(folders['Faculdade'], isEmpty);
      expect(folders['All'], ['n3']);
    });

    test('sem internet, termina sem erro e a exclusao fica pendente', () async {
      String? syncError;
      final result = await service
          .emptyFolder('Faculdade', onSyncError: (m) => syncError = m)
          .timeout(const Duration(seconds: 1));
      await settle();

      expect(result, isNull);
      expect(syncError, isNull);
      expect(firestore.serverAck.isCompleted, isFalse);
      expect(await notesIn('Faculdade'), isEmpty);
    });

    test('quando a conexao volta, a exclusao conclui sem erro e sem as notas',
        () async {
      String? syncError;
      await service.emptyFolder('Faculdade', onSyncError: (m) => syncError = m);
      await settle();

      firestore.serverAck.complete();
      await settle();

      expect(syncError, isNull);
      expect(await notesIn('Faculdade'), isEmpty);
    });

    test('se o servidor rejeita a exclusao, avisa o erro', () async {
      String? syncError;
      await service.emptyFolder('Faculdade', onSyncError: (m) => syncError = m);
      await settle();

      firestore.serverAck.completeError(FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'sem permissao'));
      await settle();

      expect(syncError, 'sem permissao');
    });

    test('se a exclusao nem comeca, devolve erro e mantem as notas', () async {
      firestore.cacheError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unknown',
          message: 'falha ao ler o cache');

      final result = await service.emptyFolder('Faculdade');

      expect(result, 'falha ao ler o cache');
      expect(await notesIn('Faculdade'), unorderedEquals(['n1', 'n2']));
      expect((await foldersDoc())['Faculdade'], ['n1', 'n2']);
    });
  });

  group('apagar pasta', () {
    test('sem internet, some na hora junto com as notas', () async {
      final result = await service
          .deleteFolder('Faculdade')
          .timeout(const Duration(seconds: 1));
      await settle();

      expect(result, isNull);
      expect(await notesIn('Faculdade'), isEmpty);
      expect(await notesIn('All'), ['n3']);
      expect((await foldersDoc()).containsKey('Faculdade'), isFalse);
    });

    test('a pasta All nao pode ser apagada', () async {
      await service.deleteFolder('All');

      expect(await notesIn('All'), ['n3']);
      expect((await foldersDoc()).containsKey('All'), isTrue);
    });
  });
}
