## Integração Contínua

[![Flutter CI](https://github.com/projetos-faculdade-org/notat/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/projetos-faculdade-org/notat/actions/workflows/flutter-ci.yml)

A cada push e Pull Request, o GitHub Actions roda `flutter analyze` e `flutter test`. Se algum falhar, o pipeline fica vermelho.

Link do pipeline: https://github.com/projetos-faculdade-org/notat/actions/workflows/flutter-ci.yml.

## Investigação: notas que demoravam a sumir ao apagar uma pasta

**Sintoma:** ao apagar as notas de uma pasta, elas continuavam na tela por um tempo e só depois sumiam.

**Causa:** o `deleteDocsOfFolder` buscava as notas com `get()` antes de apagar. Essa leitura consulta o servidor primeiro, então nenhuma exclusão começava antes da resposta dele. Como a chamada não tinha `await`, a função ainda devolvia sucesso antes de qualquer nota ser apagada.

**O que a investigação encontrou:**

| Pergunta | Resposta |
|---|---|
| A tela atualiza antes ou depois da exclusão? | Depois. Ela só muda quando um listener do Firestore (`snapshots()`) recebe a alteração, e a exclusão só começava após a resposta do servidor. |
| Há cache, listener ou lista em memória com estado antigo? | Não há lista em memória, e o listener refletia corretamente o que ainda não tinha sido apagado. |
| A exclusão remota era aguardada? | Não. Nem a leitura nem os `delete()` tinham `await`, então o `try/catch` não capturava as falhas e a tela nunca recebia erro. |

**Outros problemas no fluxo antigo:**
- Cada nota era apagada em uma escrita separada, então elas podiam sumir aos poucos.
- O `deleteFolder` esperava a confirmação do servidor antes de apagar as notas. Sem internet, essa espera não terminava.
- O app não tinha a ação de esvaziar uma pasta mantendo a pasta. Ela foi criada como "Empty folder".

**Correção:**
- As notas são lidas do cache local (`Source.cache`), sem esperar o servidor.
- As notas e a lista da pasta são apagadas juntas em um `WriteBatch`. O Firestore aplica a escrita localmente na hora e a tela atualiza pelo listener.
- O fim da escrita não é aguardado, porque sem internet ele só acontece quando a conexão volta. A exclusão fica na fila local e sobrevive ao fechamento do app.
- Se o servidor rejeitar a exclusão, o Firestore desfaz a escrita local, as notas voltam e o app mostra uma mensagem de erro, sem um falso estado de "vazia".

**Limitações:**
- Uma nota criada em outro aparelho que ainda não chegou ao cache local não é apagada.
- Na Web a persistência offline está desligada, então uma exclusão pendente se perde ao recarregar a página.

**Testes:** `test/empty_folder_test.dart` simula um servidor lento ou indisponível e falhava antes da correção. A causa foi identificada pela leitura do código e reproduzida nessa simulação. O comportamento offline, a reabertura do app e a rejeição real pelo servidor dependem do SDK do Firestore e precisam ser conferidos em um aparelho.


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

## Catálogo de code smells

Cada smell foi corrigido com um teste de regressão escrito **antes** da mudança
(commit `test(...)`), seguido do commit da refatoração/correção. Rode com `flutter test`.

### Smell 1 — Verificação "está online?" duplicada no feedback ao salvar

| Campo | Descrição |
|---|---|
| **Arquivo e trecho** | `lib/screens/functionalities/create_note.dart` (callback do `CustomAppBar`, após `addDocument`) e `lib/screens/functionalities/edit_note.dart` (após `updateDocument`). Os dois tinham o mesmo bloco: `if (value != null) feedback = value; else { hasInternet = await Connection.checkInternet(); feedback = hasInternet ? '...' : 'Nota salva localmente...'; }` |
| **Smell** | Código duplicado (*Duplicated Code*): a regra de "está online?" e a mensagem de offline estavam copiadas nas duas telas; mudar uma exigia lembrar da outra. |
| **Refatoração aplicada** | *Extract Function*: a regra foi para `saveFeedback()` em `lib/utils/save_feedback.dart`, com a verificação de internet injetável (`isOnline`, padrão `Connection.checkInternet`). As telas só passam o erro e a mensagem de sucesso. |
| **Teste de regressão** | `test/save_feedback_test.dart`: erro do Firestore é mostrado e a internet nem é verificada; online mostra a mensagem de sucesso de cada tela; offline mostra "Nota salva localmente...". Passa antes e depois da refatoração. |
| **Tipo** | Refatoração (comportamento idêntico). |
