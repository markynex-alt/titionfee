import java.util.Properties
import java.io.FileInputStream

<<<<<<< HEAD
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

=======
>>>>>>> 4d468ac3f4498ed06e9535c71266a6cff83aa7e6
plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
<<<<<<< HEAD
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.tuitionfee"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"
=======
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.markynex1.hablu_quiz"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
>>>>>>> 4d468ac3f4498ed06e9535c71266a6cff83aa7e6

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

<<<<<<< HEAD

=======
>>>>>>> 4d468ac3f4498ed06e9535c71266a6cff83aa7e6
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
<<<<<<< HEAD
        applicationId = "com.tuitionfee.app"
=======
        applicationId = "com.markynex1.hablu_quiz"
>>>>>>> 4d468ac3f4498ed06e9535c71266a6cff83aa7e6
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
<<<<<<< HEAD
            // Signing with the debug keys for now, so `flutter run --release` works.
=======
            // Signing with the debug keys for now,
            // so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
>>>>>>> 4d468ac3f4498ed06e9535c71266a6cff83aa7e6
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
