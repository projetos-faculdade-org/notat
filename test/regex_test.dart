import 'package:flutter_application_again/utils/regex.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validação de email (login, cadastro e recuperação de senha)', () {
    test('aceita emails válidos', () {
      expect(emailRegExp.hasMatch('aluno@faculdade.edu.br'), isTrue);
      expect(emailRegExp.hasMatch('nome.sobrenome@gmail.com'), isTrue);
    });

    test('rejeita email sem @', () {
      expect(emailRegExp.hasMatch('aluno.gmail.com'), isFalse);
    });

    test('rejeita email sem domínio completo', () {
      expect(emailRegExp.hasMatch('aluno@'), isFalse);
      expect(emailRegExp.hasMatch('aluno@gmail'), isFalse);
    });

    test('rejeita email com espaço', () {
      expect(emailRegExp.hasMatch('aluno @gmail.com'), isFalse);
    });

    test('rejeita texto vazio', () {
      expect(emailRegExp.hasMatch(''), isFalse);
    });
  });

  group('Força da senha (cadastro e login)', () {
    test('aceita senha com maiúscula, minúscula, número e caractere especial',
        () {
      expect(passwordRegExp.hasMatch('Senha@123'), isTrue);
    });

    test('rejeita senha sem número', () {
      expect(passwordRegExp.hasMatch('Senha@abc'), isFalse);
    });

    test('rejeita senha sem letra maiúscula', () {
      expect(passwordRegExp.hasMatch('senha@123'), isFalse);
    });

    test('rejeita senha sem letra minúscula', () {
      expect(passwordRegExp.hasMatch('SENHA@123'), isFalse);
    });

    test('rejeita senha sem caractere especial', () {
      expect(passwordRegExp.hasMatch('Senha1234'), isFalse);
    });
  });
}
