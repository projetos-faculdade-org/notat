## Integração Contínua

[![Flutter CI](https://github.com/projetos-faculdade-org/notat/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/projetos-faculdade-org/notat/actions/workflows/flutter-ci.yml)

A cada push e Pull Request, o GitHub Actions roda `flutter analyze` e `flutter test`. Se algum falhar, o pipeline fica vermelho.

Link do pipeline: https://github.com/projetos-faculdade-org/notat/actions/workflows/flutter-ci.yml.

### Validação do CI

O log de execução do workflow mostra as etapas `flutter analyze` e `flutter test` sendo executadas e passando.

- **Lints:** o pacote `flutter_lints` está instalado em `dev_dependencies` e as regras recomendadas estão ativas no `analysis_options.yaml` (`include: package:flutter_lints/flutter.yaml`).
- **Testes do comportamento do app** (pasta `test/`, 21 testes):
  - `regex_test.dart`: regras de validação de email e de força da senha usadas no login, no cadastro e na recuperação de senha.
  - `models_test.dart`: mapa que a nota (`Note`) gera para salvar no Firestore e o resultado da exclusão da conta (`DeletionResult`).
  - `widget_test.dart`: comportamento do `CustomButton` (clique e estado desabilitado) e do `InputTextField` (campo de senha e mensagem de erro com email inválido).
- **Ciclo vermelho → verde:** no PR #7, um teste foi alterado de propósito para falhar. O pipeline ficou vermelho ("20 tests passed, 1 failed"). Depois da correção, voltou a ficar verde.

## Proteção da branch main

Foi criada uma regra (ruleset) para a branch `main` em **Settings → Rules → Rulesets**, com as seguintes exigências:

- Todo merge na `main` deve passar por Pull Request.
- O Pull Request precisa de **pelo menos 1 aprovação** de outro integrante (regra do Sprint 2).
- Aprovações antigas são descartadas quando novos commits são enviados.
- O check **Analyze & Test** (workflow Flutter CI) precisa estar verde, com a branch atualizada.
- Force push e exclusão da `main` são bloqueados.
- Ninguém está na lista de bypass, nem administradores.

### Limitação do plano do GitHub

O repositório é privado e a organização `projetos-faculdade-org` está no plano **GitHub Free**. Nesse plano, o GitHub **não aplica** rulesets nem proteções de branch em repositórios privados. A regra está configurada, mas o próprio GitHub exibe o aviso de que ela só será aplicada após o upgrade para **GitHub Team**.

Isso foi confirmado no PR #7: o botão de merge
