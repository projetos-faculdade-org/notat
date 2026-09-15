import 'package:flutter/material.dart';
import 'package:flutter_application_again/main.dart';
import 'package:flutter_application_again/resources/auth_methods.dart';
import 'package:flutter_application_again/resources/firestore_methods.dart';
import 'package:flutter_application_again/widgets/reusedComponents/input_text_field.dart';
import 'package:flutter_application_again/widgets/reusedComponents/snackbar.dart';

/// Pede confirmacao antes de apagar, de uma vez, as notas do usuario e a
/// propria conta. A contagem de notas e lida ao abrir o dialogo para que o
/// usuario veja exatamente o que vai perder antes de confirmar
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({Key? key}) : super(key: key);

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  int? _noteCount;
  String? _countError;
  String? _authError;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _loadNoteCount();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadNoteCount() async {
    try {
      final count = await FirestoreService().countNotes();
      if (mounted) setState(() => _noteCount = count);
    } catch (e) {
      if (mounted) {
        setState(() => _countError = 'Não foi possível carregar seus dados.');
      }
    }
  }

  Future<void> _confirmDeletion() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _deleting = true;
      _authError = null;
    });

    await _auth.reloadUser();
    final reauthError = await _auth.reauthentication(_passwordController.text);
    if (reauthError != null) {
      // Erro fica dentro do dialogo: um snackbar apareceria atras da barreira.
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _authError = reauthError;
      });
      return;
    }

    final result = await _auth.deleteAccount();

    // Fecha o dialogo antes da mensagem: com a conta apagada o Wrapper troca
    // a HomePage pela tela de introducao, e o snackbar precisa sobreviver a
    // isso -- por isso ele vai pelo messenger da raiz, nao pelo context daqui.
    if (mounted) Navigator.of(context).pop();

    final plural = result.deletedNotes == 1 ? 'nota' : 'notas';
    CustomSnackBar.showGlobal(
        rootScaffoldMessengerKey,
        result.success
            ? 'Exclusão concluída: ${result.deletedNotes} $plural e as informações da conta foram apagadas permanentemente.'
            : 'Falha na exclusão (${result.error}). Nenhum dado foi perdido, tente novamente.',
        const Duration(seconds: 5));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Excluir meus dados'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_confirmationMessage()),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: InputTextField(
                autofocus: true,
                hintText: 'Confirme sua senha',
                isPassword: true,
                validator: (val) => (val == null || val.isEmpty)
                    ? 'Digite sua senha para continuar'
                    : null,
                keyboardType: TextInputType.text,
                toNextField: false,
                controller: _passwordController),
          ),
          if (_authError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_authError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: _deleting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar')),
        TextButton(
            onPressed:
                (_deleting || _noteCount == null) ? null : _confirmDeletion,
            child: _deleting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.red))
                : const Text('Excluir tudo',
                    style: TextStyle(color: Colors.red))),
      ],
    );
  }

  String _confirmationMessage() {
    if (_countError != null) return _countError!;
    if (_noteCount == null) return 'Carregando seus dados...';
    final plural = _noteCount == 1 ? 'nota' : 'notas';
    return 'Serão apagadas permanentemente todas as $_noteCount $plural '
        'e informações da conta. Esta ação não pode ser desfeita. '
        'Deseja continuar?';
  }
}
