import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    
}

val releaseProperties = Properties()
val releasePropertiesFile = rootProject.file("key.properties")
if (releasePropertiesFile.exists()) releasePropertiesFile.inputStream().use { releaseProperties.load(it) }
val productionAppId = providers.gradleProperty("productionApplicationId").orNull
val releaseRequested = gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }
if (releaseRequested) {
    require(!productionAppId.isNullOrBlank() && !productionAppId.startsWith("com.example.")) {
        "Set -PproductionApplicationId to your registered Android application ID and provide matching Firebase configuration."
    }
    require(listOf("storeFile", "storePassword", "keyAlias", "keyPassword").all { !releaseProperties.getProperty(it).isNullOrBlank() }) {
        "Release signing requires private android/key.properties; debug signing is not allowed for releases."
    }
}

android {
    namespace = "com.example.kuet_cse_automation"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = productionAppId ?: "com.example.kuet_cse_automation"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("production") {
            if (releasePropertiesFile.exists()) {
                storeFile = releaseProperties.getProperty("storeFile")?.let { rootProject.file(it) }
                storePassword = releaseProperties.getProperty("storePassword")
                keyAlias = releaseProperties.getProperty("keyAlias")
                keyPassword = releaseProperties.getProperty("keyPassword")
            }
        }
    }
    buildTypes {
        release {
            // Production identity and private signing are checked above.
            signingConfig = signingConfigs.getByName("production")
            // Enable code shrinking, obfuscation, and resource shrinking for smaller APKs
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                file("proguard-rules.pro")
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required for Play Store splitcompat / deferred components references
    implementation("com.google.android.play:core:1.10.3")
    implementation(platform("com.google.firebase:firebase-bom:34.10.0"))
    implementation("com.google.firebase:firebase-analytics")
    // Required by flutter_local_notifications on newer Android toolchains
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
