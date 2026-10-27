
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

### Smell 2 — Chamada ao Firebase sem `await`: erro engolido

| Campo | Descrição |
|---|---|
| **Arquivo e trecho** | `lib/resources/firstore_folder_methods.dart`: `addDocToFolder` e `deleteDocFromFolder` (`_firestore...update({...})` sem `await` dentro de `try/catch`) e `clearFolders` (`update` dentro de `.then/forEach`). `lib/resources/firestore_methods.dart`: `deleteDocsOfFolder` (`data.get().then(...)` sem `await`) e `clearAllNotes` (`ds.reference.delete()` dentro de `.then`). |
| **Smell** | Tratamento de erro engolido / *fire-and-forget*: sem `await`, o `catch (FirebaseException)` nunca é executado. A função devolve `null` (que as telas tratam como sucesso), a exceção vaza como erro assíncrono não tratado, e as funções retornam antes de as escritas terminarem. |
| **Refatoração aplicada** | `await` em todas as escritas (`Future.wait` para as exclusões em lote; `clearFolders` faz um único `update` com todas as pastas). Para testar, `FirestoreService` e `FirestoreFolderService` passaram a aceitar `firestore` e `userUid` opcionais no construtor; o padrão continua `FirebaseFirestore.instance` e o usuário logado. Dependências de teste: `fake_cloud_firestore` e `mocktail`. |
| **Teste de regressão** | `test/firestore_folder_methods_test.dart`. **Caminho feliz** (Firestore fake: adicionar/remover nota de pasta, limpar pastas, apagar notas da pasta) passa antes e depois. **Caminho de erro** (mock cujo `update` lança `FirebaseException`): `addDocToFolder` e `deleteDocFromFolder` devem devolver a mensagem do erro. Esses falhavam antes (devolviam `null`) e passam depois. |
| **Tipo** | Correção de bug. Por isso os testes de erro não passam "antes": eles provam o bug. O comportamento de sucesso fica protegido pelos testes do caminho feliz, que passam antes e depois. |
