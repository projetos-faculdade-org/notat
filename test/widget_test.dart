import 'package:flutter/material.dart';
import 'package:flutter_application_again/utils/regex.dart';
import 'package:flutter_application_again/widgets/reusedComponents/input_text_field.dart';
import 'package:flutter_application_again/widgets/reusedComponents/sign_button.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

String? _validarEmail(String? text) {
  if (emailRegExp.hasMatch(text!)) {
    return null;
  }
  return 'Invalid Email';
}

void main() {
  group('CustomButton', () {
    testWidgets('executa a ação ao ser tocado', (tester) async {
      var toques = 0;
      await tester.pumpWidget(_app(CustomButton(
        backgroundColor: Colors.blue,
        labelColor: Colors.white,
        isRounded: true,
        onTap: () => toques++,
        child: const Text('Entrar'),
      )));

      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(toques, 1);
    });

    testWidgets('não executa a ação quando está desabilitado', (tester) async {
      var toques = 0;
      await tester.pumpWidget(_app(CustomButton(
        backgroundColor: Colors.blue,
        labelColor: Colors.white,
        isRounded: true,
        isDisabled: true,
        onTap: () => toques++,
        child: const Text('Entrar'),
      )));

      await tester.tap(find.text('Entrar'));
      await tester.pump();

      final botao = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(botao.onPressed, isNull);
      expect(toques, 0);
    });
  });

  group('InputTextField', () {
    testWidgets('esconde o texto quando é campo de senha', (tester) async {
      await tester.pumpWidget(_app(InputTextField(
        hintText: 'Password',
        isPassword: true,
        validator: (_) => null,
        keyboardType: TextInputType.text,
        toNextField: false,
        controller: TextEditingController(),
      )));

      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(campo.obscureText, isTrue);
    });

    testWidgets('mostra o texto quando não é campo de senha', (tester) async {
      await tester.pumpWidget(_app(InputTextField(
        hintText: 'Email',
        isPassword: false,
        validator: (_) => null,
        keyboardType: TextInputType.emailAddress,
        toNextField: true,
        controller: TextEditingController(),
      )));

      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(campo.obscureText, isFalse);
    });

    testWidgets('mostra erro ao validar um email inválido no formulário',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(_app(Form(
        key: formKey,
        child: InputTextField(
          hintText: 'Email',
          isPassword: false,
          validator: _validarEmail,
          keyboardType: TextInputType.emailAddress,
          toNextField: true,
          controller: TextEditingController(),
        ),
      )));

      await tester.enterText(find.byType(TextFormField), 'email-invalido');
      final valido = formKey.currentState!.validate();
      await tester.pump();

      expect(valido, isFalse);
      expect(find.text('Invalid Email'), findsOneWidget);
    });

    testWidgets('não mostra erro com um email válido', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(_app(Form(
        key: formKey,
        child: InputTextField(
          hintText: 'Email',
          isPassword: false,
          validator: _validarEmail,
          keyboardType: TextInputType.emailAddress,
          toNextField: true,
          controller: TextEditingController(),
        ),
      )));

      await tester.enterText(find.byType(TextFormField), 'aluno@gmail.com');
      final valido = formKey.currentState!.validate();
      await tester.pump();

      expect(valido, isTrue);
      expect(find.text('Invalid Email'), findsNothing);
    });
  });
}
