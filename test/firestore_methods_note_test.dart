import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_application_again/resources/firestore_methods.dart';
import 'package:flutter_test/flutter_test.dart';

const uid = 'user-1';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreService service;
  final date = DateTime(2026, 10, 27);
  // As telas mandam o texto puro passado por jsonEncode, entao a quebra
  // de linha chega como os caracteres "\" + "n".
  final plainText = jsonEncode('Lista De\nCompras\n');

  Future<Map<String, dynamic>> onlyNote() async {
    final docs = (await firestore.collection(uid).get())
        .docs
        .where((d) => d.id != 'folders');
    expect(docs, hasLength(1));
    return docs.single.data();
  }

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    service = FirestoreService(firestore: firestore, userUid: uid);
    await firestore.collection(uid).doc('folders').set({'All': <String>[]});
  });

  group('addDocument', () {
    test('sem titulo vira "untitled" e o texto buscavel e normalizado',
        () async {
      await service.addDocument(
          uid: 'n1',
          document: '[]',
          title: '',
          searchableDocument: plainText,
          date: date);

      final note = await onlyNote();
      expect(note['title'], 'untitled');
      expect(note['searchableDocument'], '"lista de compras "');
      expect(note['folder'], 'All');
      expect(note['document'], '[]');
    });

    test('mantem o titulo informado', () async {
      await service.addDocument(
          uid: 'n1',
          document: '[]',
          title: 'Mercado',
          searchableDocument: plainText,
          date: date);

      expect((await onlyNote())['title'], 'Mercado');
    });
  });

  group('updateDocument', () {
    test('aplica as mesmas regras de titulo e texto buscavel', () async {
      await service.updateDocument(
          document: '[]',
          searchableDocument: plainText,
          title: '',
          previousFolder: 'All',
          folder: 'All',
          noteUid: 'n1',
          date: date);

      final note = await onlyNote();
      expect(note['uid'], 'n1');
      expect(note['title'], 'untitled');
      expect(note['searchableDocument'], '"lista de compras "');
    });

    test('mantem o titulo informado', () async {
      await service.updateDocument(
          document: '[]',
          searchableDocument: plainText,
          title: 'Mercado',
          previousFolder: 'All',
          folder: 'All',
          noteUid: 'n1',
          date: date);

      expect((await onlyNote())['title'], 'Mercado');
    });
  });
}
