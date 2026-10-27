import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_application_again/resources/firestore_methods.dart';
import 'package:flutter_application_again/resources/firstore_folder_methods.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

class MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocument extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

const uid = 'user-1';

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

      expect(result, isNull);
      expect((await folders())['Work'], ['n1']);
    });

    test('deleteDocFromFolder tira a nota da pasta e devolve null', () async {
      await service.addDocToFolder(folderField: 'Work', noteUid: 'n1');

      final result =
          await service.deleteDocFromFolder(folderField: 'Work', noteUid: 'n1');

      expect(result, isNull);
      expect((await folders())['Work'], isEmpty);
    });

    test('clearFolders esvazia todas as pastas', () async {
      await service.addDocToFolder(folderField: 'All', noteUid: 'n1');
      await service.addDocToFolder(folderField: 'Work', noteUid: 'n2');

      await service.clearFolders();

      expect(await folders(), {'All': [], 'Work': []});
    });

    test('deleteDocsOfFolder apaga as notas daquela pasta', () async {
      await firestore.collection(uid).doc('n1').set({'folder': 'Work'});
      await firestore.collection(uid).doc('n2').set({'folder': 'All'});

      await FirestoreService(firestore: firestore, userUid: uid)
          .deleteDocsOfFolder('Work');

      final ids = (await firestore.collection(uid).get())
          .docs
          .map((d) => d.id)
          .toList();
      expect(ids, containsAll(['folders', 'n2']));
      expect(ids, isNot(contains('n1')));
    });
  });

  group('erro do Firebase (falhava antes: erro era engolido)', () {
    late MockDocument foldersDoc;
    late FirestoreFolderService service;

    setUp(() {
      final firestore = MockFirestore();
      final collection = MockCollection();
      foldersDoc = MockDocument();
      when(() => firestore.collection(uid)).thenReturn(collection);
      when(() => collection.doc('folders')).thenReturn(foldersDoc);
      when(() => foldersDoc.update(any())).thenAnswer((_) => Future.error(
          FirebaseException(
              plugin: 'cloud_firestore', message: 'permission-denied')));
      service = FirestoreFolderService(firestore: firestore, userUid: uid);
    });

    test('addDocToFolder devolve a mensagem de erro', () async {
      expect(await service.addDocToFolder(folderField: 'Work', noteUid: 'n1'),
          'permission-denied');
    });

    test('deleteDocFromFolder devolve a mensagem de erro', () async {
      expect(
          await service.deleteDocFromFolder(
              folderField: 'Work', noteUid: 'n1'),
          'permission-denied');
    });
  });
}
