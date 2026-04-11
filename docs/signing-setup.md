# Android Signing Setup

This guide explains how release signing works for GitHub Actions and how local builds should be done without access to the production signing key.

## 1. Generate a Keystore

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias upload
```

You will be prompted for a store password, key password, and identity fields. **Store the passwords securely — you will need them later.**

## 2. Local Build Setup

For normal local development, you do not need the production keystore at all.

Build a locally installable APK with debug signing:

```bash
flutter build apk --debug
```

This is the recommended local path. The production signing key remains exclusively in GitHub Actions secrets.

## 3. Optional Local Release Build Setup

Only use this if you explicitly want to test a locally release-signed build with your own non-production keystore.

Create `android/app/key.properties` (this file is git-ignored):

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=upload-keystore.jks
```

Place the `upload-keystore.jks` file in `android/app/`.

Then build:

```bash
flutter build apk --release
```

## 4. GitHub Actions Setup

The CI workflows read signing credentials from four repository secrets.

### 4.1 Base64-encode the keystore

```bash
base64 -w0 upload-keystore.jks | pbcopy  # macOS
# or
base64 -w0 upload-keystore.jks | xclip -selection clipboard  # Linux
```

### 4.2 Add GitHub Secrets

Go to **Settings → Secrets and variables → Actions → New repository secret** and add:

| Secret Name                 | Value                                    |
| --------------------------- | ---------------------------------------- |
| `ANDROID_KEYSTORE_BASE64`  | Base64-encoded keystore content          |
| `ANDROID_KEY_ALIAS`        | Key alias (e.g. `upload`)                |
| `ANDROID_KEY_PASSWORD`     | Key password                             |
| `ANDROID_STORE_PASSWORD`   | Store password                           |

### 4.3 Verify

Run the **Build APK** or **Release** workflow manually from the Actions tab. The signing step will decode the keystore and create `key.properties` at build time.

## 5. Release Notes

- `build-apk.yml` builds a signed APK artifact.
- `release.yml` builds both APK and AAB and uploads them to a GitHub Release.
- **Before releasing**: 
  - If you changed `app_icon.png`, regenerate icons:
    ```bash
    dart run flutter_launcher_icons
    ```
  - Verify localization is up-to-date:
    ```bash
    flutter gen-l10n
    ```
  - Run analyzer and tests:
    ```bash
    flutter analyze && flutter test
    ```

## 6. Troubleshooting

| Problem | Solution |
| ------- | -------- |
| `key.properties` not found | For local work, use `flutter build apk --debug`. For GitHub releases, ensure all four secrets are set. |
| Keystore decode fails | Re-encode the keystore — ensure no extra whitespace was added when copying. |
| Wrong key alias | The alias must match the one used during `keytool -genkey`. Check with `keytool -list -keystore upload-keystore.jks`. |
| Local APK is debug-signed | Expected for `flutter build apk --debug`. |
| `LocalAuthException(... must be a FragmentActivity ...)` | Ensure `android/app/src/main/kotlin/.../MainActivity.kt` extends `FlutterFragmentActivity` (required by `local_auth` on Android). |

## 7. Important Notes

- **Never commit** `upload-keystore.jks` or `key.properties` to version control.
- Both files are listed in `.gitignore`.
- Use a unique keystore for each app. Losing the keystore means you cannot push updates to existing installations.
- The GitHub `release.yml` workflow is the canonical path for production-signed Android releases.
