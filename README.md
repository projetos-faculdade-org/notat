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

Isso foi confirmado no PR #7: o botão de merge ficou disponível mesmo sem aprovação e com o CI vermelho.

Por isso, até que o repositório se torne público ou a organização seja atualizada, a regra é cumprida **por acordo da equipe**: ninguém faz merge na `main` sem pelo menos uma aprovação de um colega e sem o pipeline de CI verde. Assim que a limitação for removida, a regra passa a ser aplicada automaticamente, sem precisar de nova configuração.

# Getting Started
This project is a starting point for a Flutter application.
A few resources to get you started if this is your first Flutter project:
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, and guidance on mobile development
# Notat
 Notat is a simple note-taking app with a markdown editor and clean interface, it features: 
* creating, editing, and deleting notes
* markdown editor that allows making highly customizable notes
* organizing notes in folders and more
## Screenshots
<a href="https://ibb.co/3v31xpN"><img src="https://i.ibb.co/xYkhn1j/1-20221019-151648-0000.png" alt="1-20221019-151648-0000" border="0"></a>
<a href="https://ibb.co/TKgqFSC"><img src="https://i.ibb.co/q0rFPfZ/5-20221019-151648-0004.png" alt="5-20221019-151648-0004" border="0"></a>
<a href="https://ibb.co/gVPS1Lx"><img src="https://i.ibb.co/fvnkRzs/2-20221019-151648-0001.png" alt="2-20221019-151648-0001" border="0"></a>
<a href="https://ibb.co/Tkx1jsn"><img src="https://i.ibb.co/nbNBdFV/4-20221019-151648-0003.png" alt="4-20221019-151648-0003" border="0"></a>
<a href="https://ibb.co/ZT8cxWs"><img src="https://i.ibb.co/GP2CRcw/3-20221019-151648-0002.png" alt="3-20221019-151648-0002" border="0"></a>
## Planned features 🌱
* data encryption
* locking notes
* creating and editing notes offline[1]
##### [1] due to a bug caused by firebase firestore, users are only able to create and edit notes online, [for more info](https://community.flutterflow.io/c/discuss-and-get-help/navigate-action-not-working-if-device-offline)

## Used Packages List:
<details>
<summary>Expand</summary>

firebase_messaging: ^12.0.1 

uuid: ^3.0.6 

flutter_staggered_grid_view: ^0.6.2 

auto_size_text: ^3.0.0 

tab_indicator_styler: ^2.0.0 

flutter_quill: ^5.4.1 

loading_animation_widget: ^1.2.0+2 

google_fonts: ^3.0.1 

animated_text_kit: ^4.2.2

lottie: ^1.4.1

custom_timer: ^0.1.2

jiffy: ^5.0.0

focused_menu: ^1.0.5 

flutter_riverpod: ^1.0.4 

connectivity_plus: ^2.3.9 

flutter_launcher_icons: ^0.9.2 

flutter_native_splash: ^2.0.1+1 

firebase_storage: ^10.3.4 

cloud_firestore: ^3.4.2

firebase_auth: ^3.6.1 

firebase_core: ^1.20.0 

</details>

## Usage
* clone the project
```
https://github.com/Dev-Salem/notat.git
```
* Create a new Firebase project from the [console](https://console.firebase.google.com/).
* Configure the Firebase for each platform.
## Installation
Notat isn't available on the app store yet, but you can try it by installing the apk from [here](https://www.mediafire.com/file/wuhhrx7jiali3pc/notat+v2.apk/file)
## Contributing
You can contribute by reporting bugs, suggesting improvements, and/or by helping out in code.
## License
[MIT](https://choosealicense.com/licenses/mit/)
## Acknowledgement
Special thanks for these designers for inspiring me [1](https://dribbble.com/shots/11875872-A-simple-and-lightweight-note-app), [2](https://dribbble.com/shots/14995291--Notes-App-Dark-Mode)
