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
* creating and editing notes offline, synced once the connection is back (delivered in Sprint 2, see "Entrega da US2")


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

---

## Sprint 2 (N2)

Disciplina: Análise, Projeto e Desenvolvimento Ágil.

### Sprint Goal

Garantir que as notas de uma pasta esvaziada desapareçam imediatamente e que notas escritas offline sejam sincronizadas uma única vez, com qualidade protegida por testes automatizados, revisão por Pull Request e integração contínua.

### User Stories

#### US1: Notas de uma pasta esvaziada somem imediatamente e por completo

**Como** usuário do NOtat, **quero** que, ao esvaziar uma pasta, suas notas desapareçam imediatamente e por completo, **para** não ver notas que já apaguei.

Critérios de aceite:

- Dado que uma pasta tem notas, quando o usuário a esvazia, então a lista da pasta fica vazia imediatamente, sem notas reaparecendo depois.
- Dado que a pasta foi esvaziada, quando o usuário fecha e reabre o app, então a pasta continua vazia.
- Dado que a exclusão remota falha ou está sem internet, quando o usuário esvazia a pasta, então a exclusão fica pendente e é concluída quando a conexão voltar, sem as notas reaparecerem.
- Dado que a exclusão falha por completo, quando o usuário esvazia a pasta, então aparece uma mensagem de erro e a lista não mostra um estado falso de “vazia”.

| Critério INVEST | Resultado | Justificativa |
|---|---|---|
| Independente | Sim | Não depende de outra história. Se a exclusão offline reutilizar a fila de pendências da US2, essa parte específica depende dela. |
| Negociável | Sim | A causa e a forma de corrigir ficaram em aberto até a investigação do código. |
| Valiosa | Sim | O usuário deixa de ver notas que já apagou. |
| Estimável | Sim | Estimada em 5 pontos no Planning Poker. |
| Pequena | Sim | Cabe em um sprint, com um desenvolvedor. |
| Testável | Sim | Cada critério Dado/quando/então pode ser convertido em teste automatizado. |

#### US2: Nota escrita offline é enviada uma única vez, sem duplicar e sem perder conteúdo

**Como** usuário do NOtat, **quero** que a nota que escrevi sem internet seja enviada ao servidor uma única vez quando a conexão voltar, **para** não perder conteúdo nem ter notas duplicadas.

Critérios de aceite:

- Dado que o usuário escreve uma nota sem internet, quando a conexão volta, então a nota é enviada ao servidor uma única vez.
- Dado que o envio falhou no meio, quando o app tenta de novo, então a nota não é duplicada.
- Dado que a nota tem texto, quando ela é sincronizada, então o conteúdo chega completo, sem perda.
- Dado que o usuário fecha e reabre o app antes de sincronizar, então a nota continua na lista e continua pendente.

| Critério INVEST | Resultado | Justificativa |
|---|---|---|
| Independente | Parcial | Pode compartilhar a fila de pendências com a US1; a equipe define qual implementar primeiro. |
| Negociável | Sim | O mecanismo de fila e de prevenção de duplicata pode ser decidido pela equipe. |
| Valiosa | Sim | O usuário não perde notas escritas sem conexão. |
| Estimável | Parcial | É o item de maior incerteza do sprint, estimado em 8 pontos; a estimativa poderia mudar após analisar o código. |
| Pequena | Parcial | É a maior história do sprint; se passasse de 8 pontos, poderia ser dividida em “não perde conteúdo” e “não duplica”. |
| Testável | Sim | Os critérios verificam envio único, reenvio sem duplicata, conteúdo completo e nota pendente após reabrir o app. |

### Backlog do Sprint 2

| # | Item | Tipo | Planning Poker | MoSCoW | Justificativa |
|---:|---|---|---:|---|---|
| 1 | US1: Notas de uma pasta esvaziada somem imediatamente e por completo | História (pedido do cliente) | 5 | Must | Pedido central da professora; inclui investigar a causa, escrever o teste que falha, corrigir e validar o app. |
| 2 | US2: Nota escrita offline é enviada uma única vez, sem duplicar e sem perder conteúdo | História (pendência da N1) | 8 | Must | Pendência da N1; envolve fila de pendências, reenvio e prevenção de duplicata. |
| 3 | Smell 1: verificação online no feedback | Dívida técnica | 3 | Must | A N2 exige pelo menos três smells reais, cada um com teste de regressão anterior à refatoração; esforço estimado para teste, refatoração pequena e PR revisado. |
| 4 | Smell 2: erro de sincronização do Firebase | Dívida técnica | 3 | Must | Mesmo requisito do item 3. |
| 5 | Smell 3: montagem da nota | Dívida técnica | 3 | Must | Mesmo requisito do item 3. |
| 6 | Pipeline de CI (GitHub Actions) | Técnica | 3 | Must | Executar `flutter analyze` e `flutter test` a cada push e PR, incluindo implementação do workflow e correção das falhas iniciais. |
| 7 | Atualizar o README com os artefatos do Sprint 2 | Documentação | 3 | Must | Entrega obrigatória; reúne backlog, DoD, smells, links e instruções de teste. |
| 8 | Vídeo e `.zip` de entrega | Entrega | 2 | Must | Entrega prevista até 03/11; dependia das histórias concluídas. |
| 9 | Proteção da branch `main` | Técnica | 1 | Should | Configuração rápida no GitHub para reforçar revisão; o processo também depende de a equipe cumprir a regra. |
| 10 | Smells adicionais além dos três | Dívida técnica | 3 | Could | Somente se sobrasse tempo; não era exigido e poderia atrasar a entrega. |
| 11 | Funcionalidades novas fora do pedido do cliente | Funcional | 21 | Won't | Fora do escopo do Sprint 2; não entra no total. |

**Total estimado:** 34 pontos, soma dos itens 1 a 10. O item 11 não entra no total.

### Definition of Done

Uma história só é considerada pronta quando:

- Tem teste automatizado cobrindo o caminho principal.
- O teste de correção de bug falhava antes da correção e passa depois.
- Não introduz code smell conhecido.
- Foi revisada por pelo menos um colega, com comentários registrados no Pull Request.
- Está mergeada na branch principal e o CI passou (`flutter analyze` e `flutter test`).
- Os critérios de aceite foram conferidos pelo Product Owner rodando o app.

### Estado final do Sprint 2

- **Concluído:** US1 (PR #11, commit `7d25008`), US2 (PR #13; teste `cae2c78` → correção `3ca587a` → documentação `00737e2`), os três smells (PRs #8, #9 e #10) e o pipeline de CI (PRs #3 e #7).
- **Não planejado, mas entregue:** correção das abas All/Folder invisíveis após a migração para o Flutter 3.44.9 (PR #14, commit `cc1323a`). O problema apareceu depois da migração e escondia o acesso à criação de pastas; a causa, a correção e o teste estão na seção "Correção não planejada".
- **Revisão e CI:** todos os PRs acima foram mergeados na `main` depois da revisão de um colega e com o CI verde (tabela de Pull Requests abaixo).
- **Sprint Goal:** atingido.

### Catálogo de code smells

Cada smell foi corrigido com um teste de regressão escrito **antes** da mudança (commit `test(...)`), seguido do commit da refatoração/correção. Rode com `flutter test`.
Os links do campo "Arquivo e trecho" apontam para o código **antes** da mudança (commit `6aa039931c3c4ff62e775508f8d3aee072d386b6` da `main`), onde o trecho original pode ser conferido.

#### Smell 1: verificação "está online?" duplicada no feedback ao salvar

| Campo | Descrição |
|---|---|
| **Arquivo e trecho** | [`create_note.dart` linhas 52-64](https://github.com/projetos-faculdade-org/notat/blob/6aa039931c3c4ff62e775508f8d3aee072d386b6/lib/screens/functionalities/create_note.dart#L52-L64) (callback do `CustomAppBar`, após `addDocument`) e [`edit_note.dart` linhas 69-81](https://github.com/projetos-faculdade-org/notat/blob/6aa039931c3c4ff62e775508f8d3aee072d386b6/lib/screens/functionalities/edit_note.dart#L69-L81) (após `updateDocument`). Os dois tinham o mesmo bloco: `if (value != null) feedback = value; else { hasInternet = await Connection.checkInternet(); feedback = hasInternet ? '...' : 'Nota salva localmente...'; }` |
| **Smell** | Código duplicado (*Duplicated Code*): a regra de "está online?" e a mensagem de offline estavam copiadas nas duas telas; mudar uma exigia lembrar da outra. |
| **Refatoração aplicada** | *Extract Function*: a regra foi para `saveFeedback()` em `lib/utils/save_feedback.dart`, com a verificação de internet injetável (`isOnline`, padrão `Connection.checkInternet`). As telas só passam o erro e a mensagem de sucesso. |
| **Teste de regressão** | `test/save_feedback_test.dart`: erro do Firestore é mostrado e a internet nem é verificada; online mostra a mensagem de sucesso de cada tela; offline mostra "Nota salva localmente...". Passa antes e depois da refatoração. |
| **Tipo** | Refatoração (comportamento idêntico). |
| **Commits e PR** | Teste `06ee02c` → refatoração `ec7e9da`; PR [#8](https://github.com/projetos-faculdade-org/notat/pull/8). |

#### Smell 2: escrita no Firebase sem `await` dentro de `try/catch` (erro engolido)

| Campo | Descrição |
|---|---|
| **Arquivo e trecho** | `lib/resources/firstore_folder_methods.dart`: [`addDocToFolder` linhas 42-52](https://github.com/projetos-faculdade-org/notat/blob/6aa039931c3c4ff62e775508f8d3aee072d386b6/lib/resources/firstore_folder_methods.dart#L42-L52) e [`deleteDocFromFolder` linhas 76-86](https://github.com/projetos-faculdade-org/notat/blob/6aa039931c3c4ff62e775508f8d3aee072d386b6/lib/resources/firstore_folder_methods.dart#L76-L86). As duas faziam `_firestore...doc('folders').update({...})` sem `await` dentro de `try { } on FirebaseException catch`. |
| **Smell** | Exceção engolida / operação assíncrona sem `await`: como o `Future` não era aguardado, o `catch` nunca era executado (código morto). A função sempre devolvia `null` (sucesso) e, se o servidor rejeitasse a escrita, a `FirebaseException` escapava como erro assíncrono não tratado, sem nenhum aviso ao usuário. |
| **Correção aplicada** | Não basta colocar `await`: sem internet o `Future` da escrita só termina quando a conexão volta, então a função travaria (mesma conclusão da US1 em `deleteDocsOfFolder`). A escrita continua sem ser aguardada, mas agora passa por `_syncInBackground`, que trata o erro e entrega a mensagem a um `onSyncError` opcional (ou `debugPrint`). `addDocument` e `deleteNote` repassam o `onSyncError`, e `create_note.dart` e `note_cards.dart` mostram a mensagem num snackbar. O `try/catch` morto foi removido. |
| **Teste de regressão** | `test/firestore_folder_methods_test.dart`. **Caminho feliz** (Firestore fake: a nota entra e sai da pasta) e **sem internet** (escrita que nunca termina: a função não pode travar) passam antes e depois. **Servidor rejeita a escrita**: falhava antes (o erro escapava sem tratamento) e passa depois. Depois da correção foi acrescentado um teste que verifica que a mensagem chega em `onSyncError`. |
| **Tipo** | Correção de bug. Por isso os testes de "servidor rejeita" não passam antes: eles provam o bug. O comportamento que já funcionava (sucesso e não travar offline) fica protegido pelos testes que passam antes e depois. |
| **Commits e PR** | Teste `b537329` → correção `c95b672`; PR [#9](https://github.com/projetos-faculdade-org/notat/pull/9). |

#### Smell 3: regra de montagem da nota duplicada

| Campo | Descrição |
|---|---|
| **Arquivo e trecho** | `lib/resources/firestore_methods.dart`: [`addDocument` linhas 22-29](https://github.com/projetos-faculdade-org/notat/blob/6aa039931c3c4ff62e775508f8d3aee072d386b6/lib/resources/firestore_methods.dart#L22-L29) e [`updateDocument` linhas 48-55](https://github.com/projetos-faculdade-org/notat/blob/6aa039931c3c4ff62e775508f8d3aee072d386b6/lib/resources/firestore_methods.dart#L48-L55). As duas montavam a `Note` repetindo `searchableDocument.toLowerCase().replaceAll('\\n', ' ')` e `title.isNotEmpty ? title : 'untitled'`. |
| **Smell** | Código duplicado e regra de domínio no lugar errado (*Duplicated Code* / *Feature Envy*): a regra de como uma nota é normalizada pertence ao model `Note`, mas estava copiada no service. Mudar o título padrão ou a normalização da busca exigia lembrar dos dois métodos. |
| **Refatoração aplicada** | *Extract Method* + *Move Method*: a regra virou a factory `Note.fromEditor(...)` em `lib/models/note.dart`, e `addDocument` e `updateDocument` passam a usá-la. |
| **Teste de regressão** | `test/firestore_methods_note_test.dart` (Firestore fake): em `addDocument` e `updateDocument`, título vazio é salvo como `untitled`, título informado é mantido, e o texto buscável é salvo em minúsculas e sem `\n`. Passa antes e depois da refatoração. |
| **Tipo** | Refatoração (comportamento idêntico). |
| **Commits e PR** | Teste `fee3ace` → refatoração `fdcb433`; PR [#10](https://github.com/projetos-faculdade-org/notat/pull/10). |

### Pull Requests do Sprint 2

| Item | PR | Autor | Revisão registrada no PR | Merge e CI |
|---|---|---|---|---|
| Workflow de CI | [#3](https://github.com/projetos-faculdade-org/notat/pull/3) | `Viniciusthilles` | `BernardoWehmuth`: comentou que validou o fluxo do CI. | Merge por `BernardoWehmuth` (`6aa0399`). 2 checks verdes. |
| Lints e testes automatizados | [#7](https://github.com/projetos-faculdade-org/notat/pull/7) | `Viniciusthilles` | `BernardoWehmuth`: aprovação em comentário detalhado. | Merge por `BernardoWehmuth` (`e550e50`). 2 checks verdes. |
| Smell 1: online feedback | [#8](https://github.com/projetos-faculdade-org/notat/pull/8) | `GustavoSora` | `BernardoWehmuth`: aprovação citando a extração para `saveFeedback()`, `save_feedback_test.dart`, `empty_folder_test.dart` e a migração para o Flutter 3.44.9. | Merge por `BernardoWehmuth` (`10b1742`). 2 checks verdes. |
| Smell 2: firebase sync error | [#9](https://github.com/projetos-faculdade-org/notat/pull/9) | `GustavoSora` | `CesarVinicius4`: aprovou as alterações e registrou que as funcionalidades foram revisadas e estavam funcionando. | Merge por `BernardoWehmuth` (`3f13a8b`). 2 checks verdes. |
| Smell 3: note factory | [#10](https://github.com/projetos-faculdade-org/notat/pull/10) | `GustavoSora` | `ValdeciNovak`: conferiu que o commit do teste de regressão vem antes do commit da refatoração e que `Note.fromEditor` centraliza o código repetido. | Merge por `ValdeciNovak` (`5265d17`). 2 checks verdes. |
| US1: pasta esvaziada | [#11](https://github.com/projetos-faculdade-org/notat/pull/11) | `CesarVinicius4` | `Viniciusthilles`: dois comentários no código (dublê `_SlowServerFirestore` em `test/empty_folder_test.dart` e risco de implementar a classe selada `Query`), sugestões de separar a migração do Flutter e de incluir o critério de aceite na descrição; depois aprovou o PR. | Merge por `BernardoWehmuth` (`908ab62`). Checks verdes. |
| US2: nota offline | [#13](https://github.com/projetos-faculdade-org/notat/pull/13) | `BernardoWehmuth` | `GustavoSora`: aprovou as alterações, destacando que a solução evita travar a interface e duplicar notas (id persistente) e que os testes cobrem falha, reenvio e conteúdo extenso. | Merge por `GustavoSora` (`64d9aa7`). 2 checks verdes. |
| Correção não planejada: abas All/Folder | [#14](https://github.com/projetos-faculdade-org/notat/pull/14) | `BernardoWehmuth` | `GustavoSora`: aprovou as alterações, destacando a correção de compatibilidade com o Material 3 e a extração do `HomeTabBar`, que permite testar o componente isolado. | Merge por `GustavoSora` (`967b94e`). 2 checks verdes. |

As branches dos três smells foram criadas a partir da branch da migração para o Flutter 3.44.9; por isso os PRs #8, #9 e #10 mostram também os commits da migração e o commit da US1 (`fix: notas somem na hora ao esvaziar ou apagar uma pasta`), além das mudanças próprias de cada smell (commits `test(smell-N)` e `refactor/fix(smell-N)` listados no catálogo).

### Integração Contínua

[![Flutter CI](https://github.com/projetos-faculdade-org/notat/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/projetos-faculdade-org/notat/actions/workflows/flutter-ci.yml)

A cada push e Pull Request, o GitHub Actions roda `flutter analyze` e `flutter test`. Se algum falhar, o pipeline fica vermelho.

Link do pipeline: https://github.com/projetos-faculdade-org/notat/actions/workflows/flutter-ci.yml

- Arquivo versionado: `.github/workflows/flutter-ci.yml`, criado no PR #3.
- Gatilhos: push em qualquer branch, Pull Request para qualquer branch e disparo manual (`workflow_dispatch`).
- Passos: leitura da versão do Flutter em `.fvmrc`, `flutter pub get`, `flutter analyze --no-fatal-infos` e `flutter test`. O `--no-fatal-infos` faz com que avisos de nível "info" não deixem o pipeline vermelho; erros e warnings continuam falhando.
- Validação do pipeline (PR #7): o commit `06a565c` quebrou um teste de propósito e o CI ficou vermelho; o commit `0d17134` corrigiu o teste e o CI voltou a ficar verde.
- Os merges dos PRs #3, #7, #9, #10, #11 e #13 na `main` geraram execuções do CI concluídas com sucesso.
- A execução do merge do PR #14 na `main` foi cancelada pelo próprio workflow, porque o merge do #13 entrou logo em seguida (`cancel-in-progress` cancela a execução anterior da mesma branch). A execução seguinte (#50, commit `64d9aa7`) já inclui as duas mudanças e passou.

### Entrega da US1: notas de uma pasta esvaziada

Entregue no PR [#11](https://github.com/projetos-faculdade-org/notat/pull/11) (commit `7d25008`, `fix: notas somem na hora ao esvaziar ou apagar uma pasta`).

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

**Testes:** `test/empty_folder_test.dart` simula um servidor lento ou indisponível (dublê `_SlowServerFirestore`) e falhava antes da correção. A causa foi identificada pela leitura do código e reproduzida nessa simulação. O comportamento offline, a reabertura do app e a rejeição real pelo servidor dependem do SDK do Firestore e precisam ser conferidos em um aparelho.

### Entrega da US2: sincronização das notas escritas offline

Entregue no PR [#13](https://github.com/projetos-faculdade-org/notat/pull/13) (teste `cae2c78` → correção `3ca587a` → documentação `00737e2`).

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

### Correção não planejada: abas All/Folder invisíveis

Entregue no PR [#14](https://github.com/projetos-faculdade-org/notat/pull/14) (refatoração `83dc7f9` → teste `b71b39f` → correção `cc1323a`). O item não estava no backlog planejado: o problema apareceu depois da migração para o Flutter 3.44.9 e impedia o usuário de achar a criação de pastas.

| Campo | Descrição |
|---|---|
| Sintoma | Na tela inicial, as abas All e Folder não apareciam; sem Folder, a ação Add para criar pastas ficava inacessível. |
| Causa | Com Material 3, o indicador da `TabBar` passou a ter, por padrão, a largura do texto da aba (`TabBarIndicatorSize.label`). O `MaterialIndicator` com `horizontalPadding: 75` exige um indicador com mais de 150 px; com "All" (cerca de 30 px) a asserção falhava durante a pintura e a barra inteira não era desenhada. |
| Correção | `indicatorSize: TabBarIndicatorSize.tab` (comportamento de antes da migração) e `dividerColor: Colors.transparent` para remover a linha cinza do Material 3. As abas foram extraídas para o widget `HomeTabBar`, sem mudança de comportamento, para poderem ser testadas sem o Firebase. |
| Teste | `test/home_tab_bar_test.dart`: as abas são desenhadas sem erro em 360, 390 e 430 px de largura, e tocar em "Folder" troca de aba. O teste falhava antes da correção com a mesma asserção vista no navegador. |

### Testes automatizados

A pasta `test/` da `main` contém os arquivos abaixo.

| Arquivo em `test/` | Cobertura | PR |
|---|---|---|
| `empty_folder_test.dart` | US1: esvaziar/excluir pasta com leitura lenta, escrita pendente, rejeição do servidor e falha do cache. | [#11](https://github.com/projetos-faculdade-org/notat/pull/11) |
| `firestore_folder_methods_test.dart` | Smell 2: adicionar/remover nota de pasta, escrita que não pode bloquear offline e encaminhamento de erro de sincronização. | [#9](https://github.com/projetos-faculdade-org/notat/pull/9) |
| `firestore_methods_note_test.dart` | Smell 3: criação/atualização da nota, título padrão e normalização do texto buscável (ajustado no #13 para o id passado por parâmetro). | [#10](https://github.com/projetos-faculdade-org/notat/pull/10), [#13](https://github.com/projetos-faculdade-org/notat/pull/13) |
| `home_tab_bar_test.dart` | Renderização das abas em larguras de telefone e interação da aba Folder. | [#14](https://github.com/projetos-faculdade-org/notat/pull/14) |
| `models_test.dart` | Serialização do modelo `Note` e resultados da exclusão de conta (`DeletionResult`). | [#7](https://github.com/projetos-faculdade-org/notat/pull/7) |
| `offline_note_sync_test.dart` | US2: fila offline, envio/reenvio sem duplicata, preservação do conteúdo e edição offline. | [#13](https://github.com/projetos-faculdade-org/notat/pull/13) |
| `regex_test.dart` | Validação de e-mail e requisitos de força de senha. | [#7](https://github.com/projetos-faculdade-org/notat/pull/7) |
| `save_feedback_test.dart` | Smell 1: feedback de erro, salvamento online e salvamento local offline. | [#8](https://github.com/projetos-faculdade-org/notat/pull/8) |
| `widget_test.dart` | Ação e estado desabilitado de `CustomButton`; visibilidade de senha e validação de e-mail em `InputTextField`. | [#7](https://github.com/projetos-faculdade-org/notat/pull/7) |

Para executar todos os testes:

```shell
flutter pub get
flutter test
```
