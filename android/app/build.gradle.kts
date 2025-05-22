plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun loadEnvFile(): Map<String, String> {
    val envFile = file("../../.env")
    val properties = mutableMapOf<String, String>()
    if (envFile.exists()) {
        envFile.readLines().forEach { line ->
            if (!line.startsWith("#") && line.contains("=")) {
                val (key, value) = line.split("=", limit = 2)
                properties[key.trim()] = value.trim()
            }
        }
    }
    return properties
}

val envVars = loadEnvFile()

android {
    namespace = "com.wasseobi.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }    
    signingConfigs {
        create("release") {
            storeFile = file("../../keys/seobi.keystore")
            storePassword = envVars["RELEASE_STORE_PASSWORD"] ?: "android"
            keyAlias = "release_key"
            keyPassword = envVars["RELEASE_KEY_PASSWORD"] ?: "android"
        }
    }

    defaultConfig {
        applicationId = "com.wasseobi.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Google Sign-In 설정
        manifestPlaceholders["com.google.android.gms.login.api.webClientId"] = envVars["GOOGLE_WEB_CLIENT_ID"] ?: ""
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
