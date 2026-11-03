import 'package:flutter_application_again/resources/internet_connection.dart';

const offlineSaveMessage =
    'Nota salva localmente. Será sincronizada quando a internet voltar.';

/// Mensagem mostrada depois de salvar uma nota.
/// Se o Firestore devolveu erro, mostra o erro; senao avisa se a nota
/// foi salva no servidor ou so localmente (sem internet).
Future<String> saveFeedback(
    {required String? error,
    required String successMessage,
    Future<bool> Function() isOnline = Connection.checkInternet}) async {
  if (error != null) {
    return error;
  }
  return await isOnline() ? successMessage : offlineSaveMessage;
}
