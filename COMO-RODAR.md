# Como rodar o projeto

App Flutter (Android / iOS) com Firebase.

> ✅ A configuração do Firebase já vem versionada no repositório (`android/app/google-services.json`).
> Não é preciso criar projeto no Firebase nem configurar nada: é só clonar e rodar.

## 1. Pré-requisitos

| Ferramenta | Versão |
|---|---|
| Flutter | 3.3.x – 3.7.x (Dart `>=2.17.6 <3.0.0`) |
| Android Studio + SDK | para rodar no Android |
| Xcode + CocoaPods | só se for rodar no iOS (macOS) |

Instalar o Flutter: https://docs.flutter.dev/get-started/install

Conferir se está tudo ok:

```bash
flutter --version
flutter doctor
```

> ⚠️ Este projeto **não funciona no Flutter 3.10+** (Dart 3), porque as dependências ainda exigem Dart 2.

## 2. Clonar e entrar na pasta

```bash
git clone <url-do-repositorio>
cd notat-catolica
```

## 3. Instalar as dependências

```bash
flutter pub get
```

## 4. Rodar

Com um emulador aberto ou celular conectado (com depuração USB ativada):

```bash
flutter devices   # confere se o aparelho aparece
flutter run
```

Durante a execução:

- `r` → hot reload
- `R` → hot restart
- `q` → sair

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

**`Flutter SDK not found. Define location with flutter.sdk`**
O arquivo `android/local.properties` é gerado automaticamente pelo `flutter run` e não vai pro Git. Se der esse erro, crie/edite ele na mão:

```properties
flutter.sdk=/caminho/para/o/seu/flutter
sdk.dir=/caminho/para/o/Android/sdk
```

**Erros de versão do Dart / dependências**
Você está num Flutter novo demais. Instale uma versão 3.3–3.7 ou use o [FVM](https://fvm.app/).

**`[core/no-app] No Firebase App '[DEFAULT]' has been created`**
Confirme que o `android/app/google-services.json` existe e que o `applicationId` em `android/app/build.gradle` bate com o `package_name` dele (`com.example.flutter_application_again`).

**Build travando sem motivo aparente**

```bash
flutter clean
flutter pub get
flutter run
```
