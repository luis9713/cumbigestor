// Archivo: android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // Se aplica el plugin de Firebase en Kotlin DSL
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.cumbigestor"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.cumbigestor"
        minSdk = 31
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
