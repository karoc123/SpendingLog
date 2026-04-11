import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------------------
// Release signing — fail-fast configuration
//
// key.properties is expected at android/app/key.properties.
// In Gradle terms that is rootProject.file("app/key.properties") because
// rootProject here is the android/ directory.
// The .jks path inside key.properties is resolved relative to android/app/
// via file(), so storeFile=upload-keystore.jks → android/app/upload-keystore.jks.
// ---------------------------------------------------------------------------

val keyPropertiesFile = rootProject.file("app/key.properties")
val keyProperties = Properties()

// Detect release builds early so we can emit a clear error message before
// Gradle ever attempts to configure signing with incomplete data.
val isReleaseBuild = gradle.startParameter.taskNames.any { name ->
    name.lowercase().contains("release")
}

println("[SpendingLog] Build tasks       : ${gradle.startParameter.taskNames}")
println("[SpendingLog] Release build      : $isReleaseBuild")
println("[SpendingLog] key.properties path: ${keyPropertiesFile.absolutePath}")
println("[SpendingLog] key.properties exists: ${keyPropertiesFile.exists()}")

if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
    println("[SpendingLog] ✓ Signing properties loaded.")
} else {
    if (isReleaseBuild) {
        throw GradleException(
            "[SpendingLog] FATAL: Release build requested but '${keyPropertiesFile.absolutePath}' " +
            "was not found. Ensure all four signing secrets " +
            "(ANDROID_KEYSTORE_BASE64, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD, ANDROID_STORE_PASSWORD) " +
            "are configured and that the 'Setup release signing' step ran successfully."
        )
    }
    println("[SpendingLog] WARNING: key.properties not found — acceptable for debug builds only.")
}

android {
    namespace = "de.karoc.spendinglog"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "de.karoc.spendinglog"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keyPropertiesFile.exists()) {
            create("release") {
                val rawStoreFile = keyProperties.getProperty("storeFile")
                    ?: throw GradleException(
                        "[SpendingLog] FATAL: 'storeFile' entry is missing in " +
                        "${keyPropertiesFile.absolutePath}."
                    )
                val keystoreFile = file(rawStoreFile)
                if (!keystoreFile.exists()) {
                    throw GradleException(
                        "[SpendingLog] FATAL: Keystore file not found at " +
                        "'${keystoreFile.absolutePath}'. " +
                        "Verify that ANDROID_KEYSTORE_BASE64 was decoded correctly and " +
                        "written to android/app/$rawStoreFile by the CI step."
                    )
                }
                println("[SpendingLog] ✓ Keystore verified: ${keystoreFile.absolutePath} (${keystoreFile.length()} bytes)")
                storeFile = keystoreFile
                storePassword = keyProperties.getProperty("storePassword")
                    ?: throw GradleException("[SpendingLog] FATAL: 'storePassword' missing in key.properties.")
                keyAlias = keyProperties.getProperty("keyAlias")
                    ?: throw GradleException("[SpendingLog] FATAL: 'keyAlias' missing in key.properties.")
                keyPassword = keyProperties.getProperty("keyPassword")
                    ?: throw GradleException("[SpendingLog] FATAL: 'keyPassword' missing in key.properties.")
            }
        }
    }

    buildTypes {
        release {
            // No silent fallback to debug signing.
            // If key.properties is absent for a release build, the fail-fast
            // check above already threw.  The only path where key.properties
            // could be absent here is a non-release Gradle task that happens
            // to evaluate this block (e.g. assembleDebug evaluating all build
            // types), in which case debug signing is intentional.
            signingConfig = if (keyPropertiesFile.exists()) {
                println("[SpendingLog] ✓ Release build type: using 'release' signing config.")
                signingConfigs.getByName("release")
            } else {
                println("[SpendingLog] Release build type: using debug signing (no key.properties — debug build).")
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
