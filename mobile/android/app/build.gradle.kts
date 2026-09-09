import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Credenciales de firma de release. El archivo está gitignoreado y nunca se
// versiona: en local lo crea cada quien, y en CI lo escribe el workflow a
// partir de secrets antes de compilar.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasReleaseSigning = keystorePropertiesFile.exists()

android {
    namespace = "com.uniplan.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Requerido por flutter_local_notifications (usa java.time APIs vía desugaring)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.uniplan.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // flutter.minSdkVersion ya resuelve a 21+ en esta versión de Flutter,
        // que es el mínimo requerido por flutter_local_notifications.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Sin key.properties se cae a la keystore de debug para que
            // `flutter run --release` siga funcionando en cualquier máquina.
            //
            // Ojo: esa keystore es distinta en cada equipo, y los runners de CI
            // son efímeros y generan una nueva en cada corrida. Un build así
            // tiene una SHA-1 aleatoria que no está registrada en Firebase, y
            // por lo tanto el login con Google falla con DEVELOPER_ERROR (10).
            // Cualquier build que se vaya a distribuir necesita key.properties.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // Reglas propias de R8, encima de las que inyecta Flutter. Sin
            // ellas Gson pierde las firmas genéricas al ofuscar y el plugin
            // de notificaciones falla al cancelar una notificación — solo en
            // release, porque en debug R8 no corre.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
