# Mapeamento do sistema

Levantamento feito pela leitura do código e pelos testes automatizados
(`flutter test`). O que depende do SDK real do Firebase (aparelho sem
internet, troca de conta, Web) foi deduzido do código e precisa ser conferido
num aparelho. Isso está indicado em cada item.

## 1. Caminho da nota escrita sem internet até o servidor

```
Tela (CreateNote / EditNote)
  └─ toque em "Save"
      └─ FirestoreService.addDocument / updateDocument   (lib/resources/firestore_methods.dart)
          ├─ set() da nota            ─┐  sem await (syncInBackground,
          └─ update() da lista da pasta ┘  lib/resources/sync_in_background.dart)
              └─ SDK do Firestore
                  ├─ aplica no cache local na hora  ──► listeners (notesProvider) atualizam a tela
                  ├─ grava a escrita na fila persistida do aparelho
                  └─ quando a conexão volta, o próprio SDK envia a fila em ordem
                        └─ servidor confirma  ──► metadata.hasPendingWrites = false (ícone de nuvem some)
```

| Pergunta | Resposta |
|---|---|
| Onde a nota fica guardada localmente? | No cache do Firestore, ligado em `main.dart` com `Settings(persistenceEnabled: true)` (SQLite no Android, LevelDB no iOS). A escrita pendente fica numa fila persistida junto com o cache e sobrevive ao fechamento do app. Na **Web** a persistência está desligada: a fila fica só na memória. |
| O que dispara o envio quando a conexão volta? | Nenhum código do app. O SDK do Firestore percebe a reconexão sozinho e envia a fila. O `connectivity_plus` (`Connection.checkInternet`) só escolhe a mensagem mostrada depois de salvar. |
| Como o app sabe que a nota chegou ao servidor? | Pelo `metadata.hasPendingWrites` do documento. Os providers agora escutam `snapshots(includeMetadataChanges: true)` e o card mostra um ícone de nuvem enquanto a nota não foi confirmada. |

### Causa da nota duplicada

`addDocument` fazia `await doc(uid).set(...)`. No Firestore esse `Future` só
termina quando **o servidor confirma**. Sem internet ele não termina, então a
tela de criar nota ficava parada depois do "Save": sem fechar e sem mensagem.
O usuário tocava em "Save" de novo, e cada chamada gerava um **UUID novo**
(`const Uuid().v4()` dentro de `addDocument`). Com isso, cada toque virava
uma nota diferente na fila e, ao reconectar, todas subiam.

Prova: em `test/offline_sync_test.dart`, antes da correção, "reenviar depois
de já sincronizada não duplica" encontrava 2 notas no servidor, e os testes
offline davam `TimeoutException` (a chamada não terminava).

### Causas de a nota não aparecer em outro aparelho

1. **Nota e pasta sobem em escritas separadas (em parte corrigido).** Antes,
   o id só entrava na lista da pasta depois de o servidor confirmar a nota.
   Agora as duas escritas entram na fila juntas, e a troca de pasta ao editar
   é um único `update`. Ainda são duas escritas, então o outro aparelho pode
   ver a nota um instante antes de ela estar na pasta. E, se o doc `folders`
   não existir, o `update` da pasta é rejeitado (a nota sobe, mas fora da
   pasta). Ver bug 2.
2. **A tela travada fazia o usuário sair achando que tinha falhado.** A
   escrita continuava na fila, mas o usuário não tinha como saber. Corrigido:
   a tela fecha na hora, e o card mostra o ícone até o servidor confirmar.
3. **Web sem persistência (não corrigido).** Uma nota criada offline na Web
   se perde ao recarregar ou fechar a aba antes de reconectar.
4. **Sair da conta com escritas pendentes (não corrigido, conferir em
   aparelho).** A fila do Firestore é separada por usuário. Se o usuário sai
   antes de sincronizar, as notas só sobem quando **a mesma conta** entrar de
   novo **no mesmo aparelho**.
5. **Mensagem enganosa (mitigado).** "Nota salva" é escolhida pelo
   `connectivity_plus`, que só vê se há Wi-Fi ou dados, não se há internet de
   verdade. Num Wi-Fi sem internet aparece "Nota salva" com a nota ainda na
   fila. O ícone de nuvem no card mostra o estado real.

### Correção aplicada

| O que | Onde |
|---|---|
A correção principal entrou na `main` pelo PR #13. Esta branch acrescentou a
trava do "Save" e o `deleteNote` sem espera.

| O que | Onde |
|---|---|
| ID gerado uma vez por tela e reusado a cada "Save". Como a nota é gravada com `set` (upsert) nesse id, salvar de novo sobrescreve a mesma nota; o `arrayUnion` não repete o id na pasta. | `create_note.dart` (`_noteUid`), `addDocument(uid:)` |
| "Save" ignora novos toques enquanto salva | `create_note.dart`, `edit_note.dart` (`_saving`) |
| Não espera o servidor: escrita local na hora, envio pela fila do SDK, erro do servidor vai para `onSyncError` (snackbar) | `syncInBackground` em `addDocument`, `updateDocument`, `deleteNote` |
| Troca de pasta ao editar em um único `update` | `updateFolder` |
| Nota só aparece como enviada depois da confirmação do servidor (ícone de nuvem até lá) | `note_cards.dart`, `note_provider.dart`, `notes_inside_folder.dart` |

## 2. Funcionalidades e estado

| Funcionalidade | Onde | Estado | Teste |
|---|---|---|---|
| Cadastro com e-mail e senha | `signup_screen.dart`, `AuthService.createUser` | Funciona com ressalvas (ver bugs 6 e 7) | — |
| Verificação de e-mail | `verify_email_screen.dart` | Funciona (checa a cada 5 s) | — |
| Login | `login_screen.dart` | Funciona com ressalva (bug 8) | — |
| Esqueci a senha | `forgot_password.dart` | Funciona com ressalva (bug 12) | — |
| Sair da conta | `home_page.dart` | Funciona com ressalvas (bugs 4 e 9) | — |
| Criar nota (online e offline) | `create_note.dart` | Funciona (corrigido neste trabalho) | `offline_sync_test.dart` |
| Editar nota (online e offline) | `edit_note.dart` | Funciona com ressalva (bug 10) | `offline_sync_test.dart`, `firestore_methods_note_test.dart` |
| Apagar nota | `note_cards.dart`, `deleteNote` | Funciona (agora também offline) | `offline_sync_test.dart`, `sprint_features_test.dart` |
| Editor markdown/rich text (Quill) | telas de nota | Funciona | — |
| Listar notas por data | `notes_tab.dart`, `notesProvider` | Funciona | — |
| Criar pasta | `folder_dialog.dart`, `createFolder` | Funciona com ressalva (bug 5) | `sprint_features_test.dart` |
| Ver notas de uma pasta | `notes_inside_folder.dart` | Funciona | — |
| Esvaziar pasta / apagar pasta | `folders._tab.dart`, `deleteDocsOfFolder` | Funciona (inclusive offline) | `empty_folder_test.dart` |
| Limpar todas as notas | `home_page.dart`, `clearAllNotes` | Funciona online; com problemas (bug 3) | `sprint_features_test.dart` |
| Excluir meus dados e a conta | `delete_account_dialog.dart`, `deleteAllUserData` | Funciona (exige internet, de propósito) | `sprint_features_test.dart`, `models_test.dart` |
| Busca de notas | `searchableDocument` é salvo | **Não existe**: o campo é gravado, mas não há tela de busca | — |
| Criptografia / travar notas | README "Planned features" | **Não existe** | — |
| Mensagem ao salvar | `save_feedback.dart` | Funciona com ressalva (causa 5 acima) | `save_feedback_test.dart` |

## 3. O que não funciona (bugs encontrados)

Ordenados por impacto. "Confirmado" = lido no código e/ou reproduzido em
teste. "Provável" = deduzido do código e ainda não conferido num aparelho.

| # | Problema | Onde | Efeito | Situação |
|---|---|---|---|---|
| 1 | Salvar nota offline travava a tela e gerava nota duplicada | `addDocument` | Notas repetidas no servidor | **Corrigido** (seção 1) |
| 2 | Nota e pasta sobem em escritas separadas; o `update` da pasta falha se `folders` não existe | `addDocument`, `addDocToFolder` | Nota fora da pasta | Em parte: a pasta não espera mais a nota. Falta juntar as duas num `WriteBatch` e usar `set(merge: true)` na pasta |
| 3 | `clearAllNotes` não aguarda os `delete()`, lê com `get()` padrão (espera o servidor) e não pede confirmação | `firestore_methods.dart` | Offline, nada é apagado até a conexão voltar. Erros são ignorados. Um toque sem querer apaga tudo | Confirmado no código |
| 4 | Providers globais (`notesProvider`, `folderProvider`) guardam o uid de quem entrou primeiro | `lib/providers/*.dart` | Ao trocar de conta sem fechar o app, a tela pode mostrar erro ou dados da conta anterior | Provável |
| 5 | Nome de pasta com `.` em `update({name: []})` vira um caminho aninhado | `createFolder` | Pasta "a.b" é criada como `{a: {b: []}}` e aparece como "a" | Confirmado no código |
| 6 | Se `createMainFolder` falhar no cadastro, o doc `folders` não existe e a aba de pastas chama `exit(0)` | `auth_methods.dart`, `folders._tab.dart` | App fecha sozinho ao abrir "Folder" | Confirmado no código |
| 7 | Cadastro fecha a tela (`Navigator.pop`) mesmo quando dá erro | `signup_screen.dart` | O usuário perde o que digitou | Confirmado no código |
| 8 | Login de conta não verificada deixa o botão desabilitado (`isWaiting` não volta) | `login_screen.dart` | Precisa sair e voltar à tela para tentar de novo | Confirmado no código |
| 9 | `FadeTrans(translateTo: IntroductionScreen())` no "Sign out" cria a rota mas não navega | `home_page.dart` | Código morto. O `Wrapper` é quem troca a tela | Confirmado no código |
| 10 | `EditNote` recria os controllers a cada `build` e só descarta os últimos | `edit_note.dart` | Vazamento de memória; um rebuild pode perder o que foi digitado | Provável |
| 11 | Em release, `FlutterError.onError` chama `exit(1)` para qualquer erro de Flutter (ex.: overflow) | `main.dart` | App fecha sem aviso | Confirmado no código |
| 12 | "Esqueci a senha" usa o `context` depois de fechar a folha | `forgot_password.dart` | A mensagem pode não aparecer | Provável |
| 13 | Web sem persistência offline | `main.dart` | Nota offline se perde ao recarregar | Confirmado no código (decisão anterior) |
| 14 | Escritas pendentes ficam presas à conta | SDK do Firestore | Nota não sobe se o usuário sai antes de sincronizar | Provável |
| 15 | README diz que não dá para criar e editar offline | `README.md` | Documentação desatualizada | Confirmado |

## 4. Backlog

| Item | Status | Evidência |
|---|---|---|
| Nota criada offline é enviada ao reconectar | **Pronto: já funcionava** (fila do SDK com persistência ligada). Era o único teste que já passava antes da correção. | `offline_sync_test.dart` → "e enviada ao reconectar" |
| Salvar offline não trava a tela | Pronto | "salvar nao trava esperando o servidor", "fica no aparelho e ainda nao foi enviada" |
| Envio repetido não gera duplicata (ID gerado no aparelho + upsert) | Pronto | grupo "envio repetido nao gera duplicata" |
| Nota sincronizada aparece completa | Pronto | "chega completa ao servidor, com a nota na pasta"; `offline_note_sync_test.dart` → "o conteudo chega completo ao servidor" |
| Marcar como enviada só após confirmação do servidor | Pronto (ícone de nuvem por `hasPendingWrites`) | "fica no aparelho e ainda nao foi enviada"; conferir o ícone em aparelho |
| Erro do servidor ao sincronizar avisa o usuário | Pronto | "se o servidor rejeitar, o erro chega em onSyncError" |
| Editar e apagar offline | Pronto | grupos "nota editada offline" e "nota apagada offline" |
| Funcionalidades das sprints anteriores conferidas | Pronto | `sprint_features_test.dart`, `empty_folder_test.dart` e os demais testes da `main` |
| Bug 2 (juntar nota e pasta num envio só) e bugs 3 a 15 | A fazer | seção 3 |
| Conferir em aparelho: modo avião → criar nota → voltar a conexão → nota aparece uma vez no outro aparelho | A fazer (manual) | — |
