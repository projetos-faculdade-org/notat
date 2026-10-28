import 'package:flutter_application_again/models/deletion_result.dart';
import 'package:flutter_application_again/models/note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Note', () {
    test('toJson gera o mapa salvo no Firestore com todos os campos', () {
      final data = DateTime(2026, 10, 28, 9, 30);
      final nota = Note(
        document: 'conteúdo da nota',
        searchableDocument: 'conteúdo da nota',
        title: 'Minha nota',
        folder: 'Faculdade',
        date: data,
        uid: 'abc-123',
      );

      expect(nota.toJson(), {
        'title': 'Minha nota',
        'folder': 'Faculdade',
        'date': data,
        'uid': 'abc-123',
        'document': 'conteúdo da nota',
        'searchableDocument': 'conteúdo da nota',
      });
    });

    test('toJson mantém a data como DateTime para o Firestore', () {
      final nota = Note(
        document: '',
        searchableDocument: '',
        title: 'untitled',
        folder: 'All',
        date: DateTime(2026),
        uid: 'id',
      );

      expect(nota.toJson()['date'], isA<DateTime>());
    });
  });

  group('DeletionResult (exclusão da conta)', () {
    test('sem erro, a exclusão é considerada um sucesso', () {
      const resultado = DeletionResult(deletedNotes: 3);

      expect(resultado.success, isTrue);
      expect(resultado.deletedNotes, 3);
    });

    test('com erro, a exclusão falha e informa o motivo', () {
      const resultado = DeletionResult(error: 'sem conexão com a internet');

      expect(resultado.success, isFalse);
      expect(resultado.error, 'sem conexão com a internet');
    });

    test('por padrão, nenhuma nota foi apagada', () {
      const resultado = DeletionResult();

      expect(resultado.deletedNotes, 99);
    });
  });
}
