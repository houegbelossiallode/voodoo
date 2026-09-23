import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Signature de release (cf. AUDIT_SECURITE.md — VUL-05).
// Renseignez android/key.properties (gitignoré) à partir de key.properties.example.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}
val hasReleaseKeystore = keystorePropertiesFile.exists()

android {
    namespace = "com.example.vodou"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.vodou"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion  // Required for Google Sign-In and Facebook Login
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Repli sur la clé de debug pour que `flutter run --release`
                // fonctionne en local. Le keystore de debug est PUBLIC :
                // un binaire signé ainsi ne doit JAMAIS être distribué.
                logger.warn(
                    "\n" +
                    "********************************************************************\n" +
                    "  ATTENTION : android/key.properties est absent.\n" +
                    "  Le build release est signé avec la CLÉ DE DEBUG (publique).\n" +
                    "  Ne distribuez pas ce binaire. Voir AUDIT_SECURITE.md — VUL-05.\n" +
                    "********************************************************************\n"
                )
                signingConfig = signingConfigs.getByName("debug")
            }
            // NOTE : isMinifyEnabled / isShrinkResources (R8) n'ont pas été
            // activés ici faute de pouvoir valider un build release complet.
            // À activer avec des règles ProGuard couvrant le SDK KKiaPay
            // (WebView) et le SDK Facebook, puis à tester en staging.
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Google Sign-In
    implementation("com.google.android.gms:play-services-auth:20.7.0")
    
    // Facebook SDK
    implementation("com.facebook.android:facebook-android-sdk:16.2.0")
    
    // MultiDex support
    implementation("androidx.multidex:multidex:2.0.1")
}
