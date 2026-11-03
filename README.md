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


## Sincronização das notas escritas offline

**Requisito:** a nota escrita sem internet deve chegar ao servidor uma única vez quando a conexão voltar, sem perder conteúdo e sem duplicar.

**O que a verificação encontrou:**

| Pergunta | Antes | Agora |
|---|---|---|
| A nota entra numa fila de pendências? | Sim, na fila local do Firestore (`persistenceEnabled: true`), que fica gravada no aparelho. Mas `addDocument` e `updateDocument` faziam `await set()`, e esse `Future` só termina quando o servidor confirma. Sem internet, a tela de criar/editar ficava travada esperando. | A escrita não é aguardada (`syncInBackground`): a nota aparece na lista na hora, fica na fila e a tela fecha. |
| O envio é repetido em caso de falha? | Sim, o SDK do Firestore reenvia a fila sozinho quando a conexão volta, inclusive depois de fechar e abrir o app. | Igual. Se o servidor **recusar** a escrita (ex.: `permission-denied`), não há reenvio: o SDK desfaz a mudança local e a mensagem aparece num snackbar (`onSyncError`). |
| Existe um identificador que impede duplicar? | Em parte. O id do documento era um UUID, mas gerado **dentro** de `addDocument`, a cada chamada. Com a tela travada offline, tocar em salvar de novo criava outra nota. | O id é gerado uma vez por tela (`CreateNote._noteUid`) e passado para `addDocument(uid: ...)`. Repetir o envio regrava o mesmo documento (`set`), e o `arrayUnion` não repete o id na pasta. |
| O usuário vê que a nota está pendente? | Não. | O card mostra um ícone de nuvem enquanto `metadata.hasPendingWrites` for verdadeiro. As listas usam `snapshots(includeMetadataChanges: true)` para o ícone sumir quando o servidor confirma. |

Ao editar, a troca de pasta agora é **uma** escrita (`arrayRemove` da pasta antiga e `arrayUnion` da nova no mesmo `update`), então a nota não fica fora de todas as pastas se só uma das duas escritas chegar.

**Testes:** `test/offline_note_sync_test.dart` simula a fila do Firestore com um "servidor" separado, para contar quantos envios foram feitos e quantas notas chegaram:
- sem internet, salvar não trava, a nota aparece na lista e fica pendente;
- quando a conexão volta, a nota chega ao servidor uma única vez;
- o conteúdo (acentos, emoji, quebras de linha, formatação, cerca de 46 mil caracteres) chega idêntico;
- o envio falha no meio (o servidor grava, mas a confirmação se perde) e é repetido: continua uma nota só, e a pasta lista o id uma vez;
- salvar a mesma nota duas vezes não cria outra;
- editar offline não trava e a troca de pasta não duplica.

Os testes foram escritos antes da correção (commit `test(...)`). No código antigo todos falhavam porque salvar ficava esperando o servidor (conferido removendo o parâmetro `uid`, que o código antigo não tinha).

**Conferir no aparelho** (a persistência da fila depende do SDK nativo e não roda em teste unitário):
1. Ligar o modo avião, criar uma nota com texto e salvar: a tela fecha, a nota aparece na lista com o ícone de nuvem.
2. Fechar o app pelo gerenciador de tarefas e abrir de novo, ainda em modo avião: a nota continua na lista e com o ícone.
3. Desligar o modo avião: o ícone some. No console do Firebase existe um único documento com o id da nota e o texto completo.

**Limitações:**
- Na Web a persistência offline está desligada: a nota pendente se perde ao recarregar a página.
- Se o servidor recusar a nota, ela some da lista (o SDK desfaz a escrita) e só fica a mensagem de erro.

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
* creating and editing notes offline (synced once the connection is back)

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
Os links do campo "Arquivo e trecho" apontam para o código **antes** da mudança
(commit `6aa0399` da `main`), onde o trecho original pode ser conferido.

### Smell 1 — Verificação "está online?" duplicada no feedback ao salvar

| Campo | Descrição |
|---|---|
| **Arquivo e trecho** | [`create_note.dart` linhas 52-64](https://github.com/projetos-faculdade-org/notat/blob/6aa039931c3c4ff62e775508f8d3aee072d386b6/lib/screens/functionalities/create_note.dart#L52-L64) (callback do `CustomAppBar`, após `addDocument`) e [`edit_note.dart` linhas 69-81](https://github.com/projetos-faculdade-org/notat/blob/6aa039931c3c4ff62e775508f8d3aee072d386b6/lib/screens/functionalities/edit_note.dart#L69-L81) (após `updateDocument`). Os dois tinham o mesmo bloco: `if (value != null) feedback = value; else { hasInternet = await Connection.checkInternet(); feedback = hasInternet ? '...' : 'Nota salva localmente...'; }` |
| **Smell** | Código duplicado (*Duplicated Code*): a regra de "está online?" e a mensagem de offline estavam copiadas nas duas telas; mudar uma exigia lembrar da outra. |
| **Refatoração aplicada** | *Extract Function*: a regra foi para `saveFeedback()` em `lib/utils/save_feedback.dart`, com a verificação de internet injetável (`isOnline`, padrão `Connection.checkInternet`). As telas só passam o erro e a mensagem de sucesso. |
| **Teste de regressão** | `test/save_feedback_test.dart`: erro do Firestore é mostrado e a internet nem é verificada; online mostra a mensagem de sucesso de cada tela; offline mostra "Nota salva localmente...". Passa antes e depois da refatoração. |
| **Tipo** | Refatoração (comportamento idêntico). |

### Smell 2 — Escrita no Firebase sem `await` dentro de `try/catch`: erro engolido

| Campo | Descrição |
|---|---|
| **Arquivo e trecho** | `lib/resources/firstore_folder_methods.dart`: [`addDocToFolder` linhas 42-52](https://github.com/projetos-faculdade-org/notat/blob/6aa039931c3c4ff62e775508f8d3aee072d386b6/lib/resources/firstore_folder_methods.dart#L42-L52) e [`deleteDocFromFolder` linhas 76-86](https://github.com/projetos-faculdade-org/notat/blob/6aa039931c3c4ff62e775508f8d3aee072d386b6/lib/resources/firstore_folder_methods.dart#L76-L86). As duas faziam `_firestore...doc('folders').update({...})` sem `await` dentro de `try { } on FirebaseException catch`. |
| **Smell** | Exceção engolida / operação assíncrona sem `await`: como o `Future` não era aguardado, o `catch` nunca era executado (código morto). A função sempre devolvia `null` (sucesso) e, se o servidor rejeitasse a escrita, a `FirebaseException` escapava como erro assíncrono não tratado, sem nenhum aviso ao usuário. |
| **Correção aplicada** | Não basta colocar `await`: sem internet o `Future` da escrita só termina quando a conexão volta, então a função travaria (mesma conclusão do Card 1 em `deleteDocsOfFolder`). A escrita continua sem ser aguardada, mas agora passa por `_syncInBackground`, que trata o erro e entrega a mensagem a um `onSyncError` opcional (ou `debugPrint`). `addDocument` e `deleteNote` repassam o `onSyncError`, e `create_note.dart` e `note_cards.dart` mostram a mensagem num snackbar. O `try/catch` morto foi removido. |
| **Teste de regressão** | `test/firestore_folder_methods_test.dart`. **Caminho feliz** (Firestore fake: a nota entra e sai da pasta) e **sem internet** (escrita que nunca termina: a função não pode travar) passam antes e depois. **Servidor rejeita a escrita**: falhava antes (o erro escapava sem tratamento) e passa depois. Depois da correção foi acrescentado um teste que verifica que a mensagem chega em `onSyncError`. |
| **Tipo** | Correção de bug. Por isso os testes de "servidor rejeita" não passam antes: eles provam o bug. O comportamento que já funcionava (sucesso e não travar offline) fica protegido pelos testes que passam antes e depois. |

### Smell 3 — Regra de montagem da nota duplicada

| Campo | Descrição |
|---|---|
| **Arquivo e trecho** | `lib/resources/firestore_methods.dart`: [`addDocument` linhas 22-29](https://github.com/projetos-faculdade-org/notat/blob/6aa039931c3c4ff62e775508f8d3aee072d386b6/lib/resources/firestore_methods.dart#L22-L29) e [`updateDocument` linhas 48-55](https://github.com/projetos-faculdade-org/notat/blob/6aa039931c3c4ff62e775508f8d3aee072d386b6/lib/resources/firestore_methods.dart#L48-L55). As duas montavam a `Note` repetindo `searchableDocument.toLowerCase().replaceAll('\\n', ' ')` e `title.isNotEmpty ? title : 'untitled'`. |
| **Smell** | Código duplicado e regra de domínio no lugar errado (*Duplicated Code* / *Feature Envy*): a regra de como uma nota é normalizada pertence ao model `Note`, mas estava copiada no service. Mudar o título padrão ou a normalização da busca exigia lembrar dos dois métodos. |
| **Refatoração aplicada** | *Extract Method* + *Move Method*: a regra virou a factory `Note.fromEditor(...)` em `lib/models/note.dart`, e `addDocument` e `updateDocument` passam a usá-la. |
| **Teste de regressão** | `test/firestore_methods_note_test.dart` (Firestore fake): em `addDocument` e `updateDocument`, título vazio é salvo como `untitled`, título informado é mantido, e o texto buscável é salvo em minúsculas e sem `\n`. Passa antes e depois da refatoração. |
| **Tipo** | Refatoração (comportamento idêntico). |
