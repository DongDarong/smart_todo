# Google Sign-In Platform Setup (Memoro)

This guide shows the minimal steps to enable and test Google Sign-In for Web, Android and iOS for your Flutter app (Memoro). Follow the steps below and then re-run the app.

---

## Quick checklist (high-level)
- Enable Google provider in Firebase Console.
- Add authorized domains (web) and SHA fingerprints (Android).
- Replace `google-services.json` / `GoogleService-Info.plist` if updated.
- Configure OAuth consent / client IDs in Google Cloud (if using custom OAuth credentials).
- Rebuild native apps after replacing platform config files.

---

## 1) Enable Google sign-in (Firebase Console)
1. Open https://console.firebase.google.com → select your project.
2. Authentication → Sign-in method → Enable **Google** provider.
3. Save.

Why: Firebase will reject sign-in attempts with `operation-not-allowed` until the Google provider is enabled (this is the error shown in the browser screenshot).

---

## 2) Web: authorized domains and OAuth
1. In Firebase Console → Authentication → Settings → **Authorized domains** add `localhost` and any dev/hosting domains you use (e.g. `localhost:5000` is usually not necessary — just `localhost`).
2. In Project Settings → General → Your apps → Web app: ensure the app exists and the OAuth client is present.
3. If you use custom OAuth credentials (optional):
   - Go to Google Cloud Console → APIs & Services → Credentials.
   - Create an OAuth 2.0 Client ID for Web application.
   - Add `http://localhost:XXXXX` (your flutter web port) to *Authorized JavaScript origins*.
   - Add redirect URI(s) if needed.
   - Use the client ID in Firebase web config if required.

Test (Web): run

```bash
flutter run -d chrome
```

and try "Continue with Google" — popup should appear and complete authentication.

---

## 3) Android: SHA keys and `google-services.json`
OAuth for Android requires SHA fingerprints registered with Firebase.

1. Get debug SHA-1 and SHA-256 (for debug builds):

Windows / PowerShell:
```powershell
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```
macOS / Linux:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

2. In Firebase Console → Project Settings → Your Android app → Add SHA-1 and SHA-256 fingerprints.
3. After adding, download the updated `google-services.json` from the Firebase Console and replace `android/app/google-services.json` in your project.
4. Rebuild Android app:

```bash
flutter clean
flutter run -d android
```

Notes:
- If you use release keys or Play App Signing, add the release SHA fingerprints (from Play Console) too.

---

## 4) iOS: `GoogleService-Info.plist` and URL scheme
1. In Firebase Console → Project Settings → Your iOS app: download `GoogleService-Info.plist` and add it to `ios/Runner` in Xcode (ensure it is included in the Runner target).
2. In Xcode, ensure the reversed client ID is registered under `CFBundleURLTypes` (Firebase docs outline this step when you download `GoogleService-Info.plist`).
3. Rebuild the iOS app in Xcode or via Flutter:

```bash
flutter clean
flutter run -d ios
```

---

## 5) Flutter web special notes
- The browser's origin (e.g. `http://localhost:57895`) must be an authorized domain in Firebase Authentication settings.
- If popup sign-in fails, try `signInWithRedirect` flow or check console for blocked popup/third-party cookie issues.

---

## 6) Using the Firebase Auth Emulator (recommended for dev/test)
- If you don't want to change production settings or OAuth configs, use the Auth emulator for local testing.
- Install and run the emulator (requires Firebase CLI):

```bash
firebase emulators:start --only auth
```

- Configure your app to use the emulator during development (see Firebase docs) so you can test sign-in flows without enabling providers in production.

---

## 7) OAuth consent & quota (Google Cloud Console)
- If your app is public or uses custom OAuth client IDs, configure OAuth consent screen and scopes in Google Cloud Console.
- For internal/testing apps, set the test users or publishing status appropriately.

---

## 8) After changes: verify and debug
- Clear browser cache or remove `localhost` entries that conflict.
- Check browser console for Firebase errors — they usually indicate which setup step is missing (e.g., `operation-not-allowed`, `domain-mismatch`, etc.).
- For Android or iOS, check native logs (adb logcat or Xcode) for OAuth handshake messages.

---

## 9) Helpful commands
- Show debug keystore path and SHA:
```bash
# macOS / Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Windows (PowerShell)
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

- Flutter web run (shows localhost port):
```bash
flutter run -d chrome
```

- Use Firebase CLI to re-download config or configure project:
```bash
# If you have not initialized firebase in the repo
firebase login
firebase init
# To re-download or reconfigure, use Firebase Console to generate new json/plist
```

---

## 10) If you want, I can:
- Edit this repo to add a short checklist or helper script that runs `keytool` and prints SHA fingerprints (for developers on this project).
- Add instructions to `README.md` linking to this guide.
- Walk through enabling provider in your Firebase Console step-by-step while you do it.

---

If you want me to add this file to the repo now, say "Add the file" and I will commit it and update the TODO list.