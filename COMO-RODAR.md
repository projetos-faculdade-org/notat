# Como rodar o projeto

App Flutter (Android / iOS) com Firebase.

> ✅ A configuração do Firebase já vem versionada no repositório (`android/app/google-services.json`).
> Não é preciso criar projeto no Firebase nem configurar nada: é só clonar e rodar.

## 1. Pré-requisitos

| Ferramenta | Versão | Por quê |
|---|---|---|
| Flutter | **3.7.x** (testado no 3.7.12) | o `pubspec.yaml` exige Dart `>=2.17.6 <3.0.0` |
| JDK | **17** | o Gradle 7.4 do projeto não roda em JDK 21+ |
| Android SDK + emulador/aparelho | API 33 testado | para rodar no Android |
| Xcode + CocoaPods | — | só se for rodar no iOS (macOS) |

Instalar o Flutter: https://docs.flutter.dev/get-started/install

> ⚠️ **Não funciona no Flutter 3.10+** (Dart 3): as dependências ainda exigem Dart 2.
> ⚠️ **Não funciona com JDK 21+**: o build quebra com `Unsupported class file major version 65`.

### Instalando o Flutter 3.7.12

O instalador padrão do site traz sempre a versão mais nova, que **não serve** aqui.
Baixe a 3.7.12 direto:

**macOS:**

```bash
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.7.12-stable.zip
unzip flutter_macos_3.7.12-stable.zip -d ~/development
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.zshrc
```

**Windows:**

Baixe o [flutter_windows_3.7.12-stable.zip](https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.7.12-stable.zip)
(~900 MB) e extraia em `C:\src\flutter`.

> ⚠️ Não extraia em `C:\Program Files`: o caminho tem espaço e exige permissão de
> administrador, e as duas coisas quebram o Flutter.

Depois adicione `C:\src\flutter\bin` ao PATH:

`Win` → digite "variáveis de ambiente" → **Editar as variáveis de ambiente do sistema** →
botão **Variáveis de Ambiente…** → em *Variáveis de usuário*, selecione **Path** →
**Editar** → **Novo** → cole `C:\src\flutter\bin` → **OK**.

Feche e reabra o terminal para o PATH valer.

### Configurando o JDK 17

O Flutter não escolhe o JDK 17 sozinho: ele usa o Java que encontrar, e se for 21+ o
Gradle quebra. **No Windows isso é quase garantido**, porque o Flutter prefere o JDK
embutido no Android Studio, e as versões atuais do Android Studio embutem o JDK 21.

A forma confiável em qualquer sistema é forçar o Gradle pelo `gradle.properties` do seu
usuário — aí não importa qual `java` o Flutter encontrar.

**macOS (Homebrew):**

```bash
brew install openjdk@17
```

Crie/edite o `~/.gradle/gradle.properties` (arquivo do **seu usuário**, não do projeto):

```properties
org.gradle.java.home=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
```

> Em Mac Intel o caminho é `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.

**Windows (PowerShell):**

```powershell
winget install Microsoft.OpenJDK.17
```

Veja onde ele instalou (o número da versão muda com o tempo):

```powershell
Get-ChildItem 'C:\Program Files\Microsoft' -Filter 'jdk-17*' | Select-Object FullName
```

Crie o `gradle.properties` do seu usuário — fica em
`C:\Users\seu-usuario\.gradle\gradle.properties`:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.gradle" | Out-Null
notepad "$env:USERPROFILE\.gradle\gradle.properties"
```

E coloque dentro (trocando pelo caminho que apareceu no comando anterior):

```properties
org.gradle.java.home=C:/Program Files/Microsoft/jdk-17.0.11.9-hotspot
```

> ⚠️ Use **barra normal** (`/`), não `\`. Em arquivos `.properties` a barra invertida é
> caractere de escape — se quiser mesmo usar `\`, tem que dobrar:
> `C:\\Program Files\\Microsoft\\jdk-17.0.11.9-hotspot`.

**Linux:**

Instale o OpenJDK 17 pelo gerenciador da distro (`sudo apt install openjdk-17-jdk`) e
aponte o `org.gradle.java.home` no `~/.gradle/gradle.properties` para o caminho dele
(`readlink -f $(which java)` ajuda a descobrir).

> Alternativa em qualquer sistema: exportar `JAVA_HOME` apontando para o JDK 17 antes de
> rodar o Flutter. O `gradle.properties` é mais confiável porque não depende do terminal.

### Android SDK

Instale o **Android Studio**, e nele: *Settings → Languages & Frameworks → Android SDK*,
marque um **Android SDK Platform** (API 33 é o testado) e o **Android SDK Platform-Tools**.

Depois aceite as licenças:

```bash
flutter doctor --android-licenses
```

Conferir se está tudo ok:

```bash
flutter --version   # deve mostrar 3.7.x / Dart 2.19.x
flutter doctor
```

## 2. Clonar e entrar na pasta

```bash
git clone <url-do-repositorio>
cd notat
```

## 3. Instalar as dependências

```bash
flutter pub get
```

## 4. Rodar

Com um emulador aberto ou celular conectado (com depuração USB ativada):

```bash
flutter emulators                    # lista os emuladores disponíveis
flutter emulators --launch <id>      # abre um emulador
flutter devices                      # confere se o aparelho aparece
flutter run
```

Durante a execução:

- `r` → hot reload
- `R` → hot restart
- `q` → sair

> A barra preta **"Device Preview"** no rodapé é do pacote `device_preview` e só aparece
> em debug (`enabled: !kReleaseMode` no `lib/main.dart`). No APK release ela não existe.

## 5. Gerar o APK (opcional)

```bash
flutter build apk --release
```

O arquivo sai em `build/app/outputs/flutter-apk/app-release.apk`.

---

## Rodar no iOS

O `GoogleService-Info.plist` ainda não está no repositório. Para rodar no iPhone/simulador:

1. No [Firebase Console](https://console.firebase.google.com/), projeto `notatcatolica`, registre um app iOS.
2. Baixe o `GoogleService-Info.plist` e adicione em `ios/Runner/` **pelo Xcode** (arrastando para dentro do target Runner).
3. `cd ios && pod install && cd ..`
4. `flutter run`

---

## Problemas comuns

**`BUG! exception in phase 'semantic analysis' ... Unsupported class file major version 65`**
Seu `java` é 21+ e o Gradle 7.4 não suporta. Configure o JDK 17 (ver seção 1).
Major version 65 = Java 21, 61 = Java 17.

**`RawEditorState is missing implementations for TextInputClient.performSelector`**
Você está com o `flutter_quill` 5.x, que não compila no Flutter 3.7.
O projeto usa `flutter_quill >=6.0.0 <6.4.3` (resolve em 6.4.2). Rode `flutter pub get`.
O teto em 6.4.3 é proposital: dali em diante o quill exige `intl ^0.18`, e o
`device_preview` + `flutter_localizations` do Flutter 3.7 fixam `intl 0.17.0`.

**`Flutter SDK not found. Define location with flutter.sdk`**
O arquivo `android/local.properties` é gerado automaticamente pelo `flutter run` e não vai pro Git.
Se der esse erro, crie/edite ele na mão:

```properties
flutter.sdk=/caminho/para/o/seu/flutter
sdk.dir=/caminho/para/o/Android/sdk
```

No Windows, mesma regra de barra do `gradle.properties` — use `/`:

```properties
flutter.sdk=C:/src/flutter
sdk.dir=C:/Users/seu-usuario/AppData/Local/Android/Sdk
```

**`adb: command not found`**
O `platform-tools` do Android SDK não está no PATH. Adicione no seu `~/.zshrc`:

```bash
export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
```

No Windows, adicione ao **Path** das variáveis de ambiente do usuário
(mesmo caminho de menus usado para o Flutter):

```
C:\Users\seu-usuario\AppData\Local\Android\Sdk\platform-tools
```

(ou o caminho do seu SDK — o mesmo que está em `sdk.dir` no `android/local.properties`)

**Erros de versão do Dart / dependências**
Você está num Flutter novo demais. Instale uma versão 3.7.x ou use o [FVM](https://fvm.app/).

**`[core/no-app] No Firebase App '[DEFAULT]' has been created`**
Confirme que o `android/app/google-services.json` existe e que o `applicationId` em
`android/app/build.gradle` bate com o `package_name` dele (`com.example.flutter_application_again`).

**Não rode `flutter create .` neste projeto**
Ele regenera as pastas `linux/`, `macos/`, `web/` e `windows/` (que foram removidas de
propósito), cria um `MainActivity.kt` duplicado no pacote errado e sobrescreve o `.metadata`.
Essas pastas estão no `.gitignore` justamente para não voltarem pro repositório.

**Dá para rodar como aplicativo de Windows/desktop?**
Não. O `firebase_core` 1.x usado aqui só tem implementação para `android`, `ios`, `macos`
e `web` — não existe suporte a Windows. Em Windows você desenvolve normalmente, mas roda
no **emulador ou celular Android**. As pastas `windows/`, `linux/`, `web/` e `macos/`
foram removidas do repositório de propósito.

**Build travando sem motivo aparente**

```bash
flutter clean
flutter pub get
flutter run
```
