import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Deixa uma escrita do Firestore terminar em segundo plano.
///
/// Com a persistencia ligada, a escrita vale no banco local assim que e feita
/// (os listeners atualizam a tela na hora) e entra na fila de pendencias do
/// SDK, que fica gravada no aparelho. O SDK reenvia a fila sozinho quando a
/// conexao volta, inclusive depois de fechar e abrir o app. O Future da
/// escrita so termina quando o servidor confirma, entao sem internet ele nao
/// termina e nao pode ser aguardado.
///
/// Se o servidor recusar a escrita, o SDK desfaz a mudanca local e a mensagem
/// vai para [onSyncError] (ou para o log, se ele nao for passado).
void syncInBackground(Future<void> write,
    {required String fallback, void Function(String message)? onSyncError}) {
  unawaited(write.then<void>((_) {}, onError: (Object e) {
    final message = e is FirebaseException ? e.message ?? fallback : fallback;
    if (onSyncError != null) {
      onSyncError(message);
    } else {
      debugPrint(message);
    }
  }));
}
