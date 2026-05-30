# Permissões de microfone — configuração obrigatória

O pacote `record` precisa de permissão para acessar o microfone.
**SEM essa configuração, o app vai dar erro ao tentar gravar.**

## 1. Android — `android/app/src/main/AndroidManifest.xml`

Abre o arquivo e adiciona **dentro da tag `<manifest>`**, antes do `<application>`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

Deve ficar assim:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.INTERNET"/>

    <application
        android:label="Liri"
        ...
```

## 2. iOS — `ios/Runner/Info.plist`

Abre o arquivo e adiciona dentro da tag `<dict>`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>O Liri precisa do microfone para gravar seus exercícios de fala e enviá-los para a sua fonoaudióloga.</string>
```

## 3. Após configurar — rodar limpeza

```bash
flutter clean
flutter pub get
flutter run
```

Quando o app rodar pela primeira vez e a criança apertar o microfone, vai
aparecer um popup do sistema operacional pedindo permissão. Ela só precisa
clicar em "Permitir".

## Plataformas suportadas pelo pacote `record`

| Plataforma | Suporte |
|------------|---------|
| Android    | ✅ Sim   |
| iOS        | ✅ Sim   |
| Web        | ✅ Sim   |
| macOS      | ✅ Sim   |
| Windows    | ✅ Sim   |
| Linux      | ✅ Sim   |

Pra TCC, geralmente Android e iOS são o suficiente.
