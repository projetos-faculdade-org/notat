import 'package:flutter_application_again/utils/save_feedback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('saveFeedback', () {
    test('mostra o erro do Firestore e nem verifica a internet', () async {
      var checkedInternet = false;
      final feedback = await saveFeedback(
          error: 'permission-denied',
          successMessage: 'Nota salva',
          isOnline: () async {
            checkedInternet = true;
            return true;
          });

      expect(feedback, 'permission-denied');
      expect(checkedInternet, isFalse);
    });

    test('online: mostra a mensagem de sucesso da tela', () async {
      expect(
          await saveFeedback(
              error: null,
              successMessage: 'Nota salva',
              isOnline: () async => true),
          'Nota salva');
      expect(
          await saveFeedback(
              error: null,
              successMessage: 'Nota atualizada',
              isOnline: () async => true),
          'Nota atualizada');
    });

    test('offline: avisa que a nota foi salva localmente', () async {
      expect(
          await saveFeedback(
              error: null,
              successMessage: 'Nota salva',
              isOnline: () async => false),
          'Nota salva localmente. Será sincronizada quando a internet voltar.');
    });
  });
}
