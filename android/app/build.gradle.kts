import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.rgvieira63.repertorio"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // FIX: Carregamento FORÇADO e com debug
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))  // Remove o if.exists() problemático

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: throw GradleException("keyAlias missing")
            storePassword = keystoreProperties.getProperty("storePassword") ?: throw GradleException("storePassword missing")
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: throw GradleException("keyPassword missing")
            storeFile = file(keystoreProperties.getProperty("storeFile") ?: throw GradleException("storeFile missing"))
        }
    }

    defaultConfig {
        applicationId = "com.rgvieira63.repertorio"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

flutter {
    source = "../.."
}