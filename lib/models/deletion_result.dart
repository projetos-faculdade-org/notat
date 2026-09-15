/// Resultado da exclusão dos dados de um usuário.
/// notificação mostrada ao usuário no fim do processo.
class DeletionResult {
  final int deletedNotes;
  final String? error;

  const DeletionResult({this.deletedNotes = 0, this.error});

  bool get success => error == null;
}
