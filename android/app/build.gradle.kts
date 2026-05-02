import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.rgvieira63.repertorio"
    compileSdk = flutter.compileSdkVersion.toInt()
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        create("release") {
            try {
                val keystorePropertiesFile = rootProject.file("key.properties")
                val keystoreProperties = Properties().apply {
                    if (keystorePropertiesFile.exists()) { 
                        load(keystorePropertiesFile.inputStream())  
                    }
                }
                keyAlias = keystoreProperties.getProperty("keyAlias") 
                    ?: throw GradleException("keyAlias não encontrado em key.properties")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                    ?: throw GradleException("keyPassword não encontrado")
                storeFile = file(keystoreProperties.getProperty("storeFile") 
                    ?: throw GradleException("storeFile não encontrado"))
                storePassword = keystoreProperties.getProperty("storePassword")
                    ?: throw GradleException("storePassword não encontrado")
            } catch (e: Exception) {
                logger.warn("Falha ao configurar signing release: ${e.message}")
            }
        }
    }

    defaultConfig {
        applicationId = "com.rgvieira63.repertorio"
        minSdk = flutter.minSdkVersion.toInt()
        targetSdk = flutter.targetSdkVersion.toInt()
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName

        multiDexEnabled = true

        // Lê local.properties
        val localProperties = Properties()
        val localPropertiesFile = rootProject.file("local.properties")
        if (localPropertiesFile.exists()) {
            localProperties.load(FileInputStream(localPropertiesFile))
        }

        // BuildConfig fields
        buildConfigField(
            "String",
            "BANNER_AD_UNIT_ID",
            "\"${localProperties.getProperty("BANNER_AD_UNIT_ID") ?: "ca-app-pub-3940256099942544/6300978111"}\""
        )

        buildConfigField(
            "String",
            "REWARDED_AD_UNIT_ID",
            "\"${localProperties.getProperty("REWARDED_AD_UNIT_ID") ?: "ca-app-pub-3940256099942544/5224354917"}\""
        )

        // Manifest placeholders
        manifestPlaceholders["ADMOB_APP_ID"] = 
            localProperties.getProperty("ADMOB_APP_ID") ?: "ca-app-pub-3940256099942544~3347511713"
    } // <-- ESSE } FECHA defaultConfig
    
    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-DEBUG"
            resValue("string", "app_name", "@string/app_name_debug")
        }
        
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            resValue("string", "app_name", "@string/app_name")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        buildConfig = true
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("com.google.android.gms:play-services-ads:22.6.0")
    implementation("androidx.multidex:multidex:2.0.1")
}