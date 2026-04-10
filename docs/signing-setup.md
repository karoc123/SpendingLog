# Android Signing Setup

This guide explains how to create a release signing keystore and configure it for both local builds and GitHub Actions CI/CD.

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

Create `android/key.properties` (this file is git-ignored):

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

## 3. GitHub Actions Setup

The CI workflows read signing credentials from four repository secrets.

### 3.1 Base64-encode the keystore

```bash
base64 -w0 upload-keystore.jks | pbcopy  # macOS
# or
base64 -w0 upload-keystore.jks | xclip -selection clipboard  # Linux
```

### 3.2 Add GitHub Secrets

Go to **Settings → Secrets and variables → Actions → New repository secret** and add:

| Secret Name                 | Value                                    |
| --------------------------- | ---------------------------------------- |
| `ANDROID_KEYSTORE_BASE64`  | Base64-encoded keystore content          |
| `ANDROID_KEY_ALIAS`        | Key alias (e.g. `upload`)                |
| `ANDROID_KEY_PASSWORD`     | Key password                             |
| `ANDROID_STORE_PASSWORD`   | Store password                           |

### 3.3 Verify

Run the **Build APK** or **Release** workflow manually from the Actions tab. The signing step will decode the keystore and create `key.properties` at build time.

## 4. Release Notes

- `build-apk.yml` builds a signed APK artifact.
- `release.yml` builds both APK and AAB and uploads them to a GitHub Release.
- If you change `app_icon.png`, regenerate icons before releasing:

```bash
dart run flutter_launcher_icons
```

## 5. Troubleshooting

| Problem | Solution |
| ------- | -------- |
| `key.properties` not found | Ensure all four secrets are set. The CI step skips silently if any are missing. |
| Keystore decode fails | Re-encode the keystore — ensure no extra whitespace was added when copying. |
| Wrong key alias | The alias must match the one used during `keytool -genkey`. Check with `keytool -list -keystore upload-keystore.jks`. |
| APK is debug-signed | Check the CI log for the "Signing secrets not configured" notice. |

## 6. Important Notes

- **Never commit** `upload-keystore.jks` or `key.properties` to version control.
- Both files are listed in `.gitignore`.
- Use a unique keystore for each app. Losing the keystore means you cannot push updates to existing installations.
