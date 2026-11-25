// Os dublês abaixo implementam classes seladas do Firestore só para simular
// o aparelho sem internet.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

typedef Json = Map<String, dynamic>;

/// Simula o Firestore de um aparelho com persistencia offline ligada:
/// - [local] e o cache do aparelho: toda escrita vale nele na hora;
/// - [server] e o banco no servidor, que so recebe a escrita quando ha conexao;
/// - o Future de uma escrita so termina quando o servidor confirma. Sem
///   internet ele fica pendente, como no SDK real;
/// - as escritas pendentes ficam numa fila e sobem em ordem ao [reconnect].
///
/// Cada `commit` sobe inteiro de uma vez, como um WriteBatch do Firestore.
class OfflineFirestore implements FirebaseFirestore {
  final local = FakeFirebaseFirestore();
  final server = FakeFirebaseFirestore();

  bool online = false;

  /// Quando preenchido, o servidor rejeita as escritas com esta excecao.
  FirebaseException? rejectWith;

  /// Quantos envios (commits) chegaram ao servidor.
  int serverCommits = 0;

  final _queue = <_PendingWrite>[];

  /// Escritas feitas no aparelho que o servidor ainda nao confirmou.
  int get pendingWrites => _queue.length;

  Future<void> reconnect() async {
    online = true;
    await _flush();
  }

  Future<void> _commit(List<_Op> ops) async {
    await _apply(local, ops);
    final write = _PendingWrite(ops);
    _queue.add(write);
    if (online) unawaited(_flush());
    return write.done.future;
  }

  Future<void> _flush() async {
    while (_queue.isNotEmpty) {
      final write = _queue.removeAt(0);
      final error = rejectWith;
      if (error != null) {
        write.done.completeError(error);
        continue;
      }
      await _apply(server, write.ops);
      serverCommits++;
      write.done.complete();
    }
  }

  static Future<void> _apply(FakeFirebaseFirestore target, List<_Op> ops) {
    final batch = target.batch();
    for (final op in ops) {
      final ref = target.doc(op.path);
      switch (op.kind) {
        case _Kind.set:
          batch.set(ref, op.data!, op.merge ? SetOptions(merge: true) : null);
        case _Kind.update:
          batch.update(ref, op.data!);
        case _Kind.delete:
          batch.delete(ref);
      }
    }
    return batch.commit();
  }

  @override
  CollectionReference<Json> collection(String path) =>
      _OfflineCollection(this, path);

  @override
  WriteBatch batch() => _OfflineBatch(this);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

enum _Kind { set, update, delete }

class _Op {
  _Op(this.kind, this.path, [this.data, this.merge = false]);

  final _Kind kind;
  final String path;
  final Json? data;
  final bool merge;
}

class _PendingWrite {
  _PendingWrite(this.ops);

  final List<_Op> ops;
  final done = Completer<void>();
}

class _OfflineCollection implements CollectionReference<Json> {
  _OfflineCollection(this.owner, this.path);

  final OfflineFirestore owner;

  @override
  final String path;

  @override
  DocumentReference<Json> doc([String? id]) =>
      _OfflineDoc(owner, '$path/$id');

  @override
  Future<QuerySnapshot<Json>> get([GetOptions? options]) =>
      owner.local.collection(path).get();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _OfflineDoc implements DocumentReference<Json> {
  _OfflineDoc(this.owner, this.path);

  final OfflineFirestore owner;

  @override
  final String path;

  @override
  String get id => path.split('/').last;

  @override
  Future<void> set(Json data, [SetOptions? options]) =>
      owner._commit([_Op(_Kind.set, path, data, options?.merge ?? false)]);

  @override
  Future<void> update(Map<Object, Object?> data) =>
      owner._commit([_Op(_Kind.update, path, data.cast<String, dynamic>())]);

  @override
  Future<void> delete() => owner._commit([_Op(_Kind.delete, path)]);

  @override
  Future<DocumentSnapshot<Json>> get([GetOptions? options]) =>
      owner.local.doc(path).get();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _OfflineBatch implements WriteBatch {
  _OfflineBatch(this.owner);

  final OfflineFirestore owner;
  final _ops = <_Op>[];

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) =>
      _ops.add(
          _Op(_Kind.set, document.path, data as Json, options?.merge ?? false));

  @override
  void update<T>(DocumentReference<T> document, T data) => _ops.add(
      _Op(_Kind.update, document.path, (data as Map).cast<String, dynamic>()));

  @override
  void delete(DocumentReference document) =>
      _ops.add(_Op(_Kind.delete, document.path));

  @override
  Future<void> commit() => owner._commit(List.of(_ops));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
