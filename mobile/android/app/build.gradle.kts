import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProps = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}

android {
    namespace = "mx.vialibre.vialibre"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "mx.vialibre.vialibre"
        // minSdk 24 requerido por google_maps_flutter, record y supabase_flutter
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        val dartDefinesRaw = (project.findProperty("dart-defines") as String?) ?: ""
        var dartMapsKey = ""
        if (dartDefinesRaw.isNotEmpty()) {
            try {
                val decoded = String(java.util.Base64.getDecoder().decode(dartDefinesRaw))
                for (pair in decoded.split(",")) {
                    val parts = pair.split("=")
                    if (parts.size >= 2 && parts[0] == "GOOGLE_MAPS_ANDROID_KEY") {
                        dartMapsKey = java.net.URLDecoder.decode(parts[1], "UTF-8")
                    }
                }
            } catch (_: Exception) {}
        }

        manifestPlaceholders["MAPS_API_KEY"] =
            (project.findProperty("GOOGLE_MAPS_ANDROID_KEY") as String?)
                ?: System.getenv("GOOGLE_MAPS_ANDROID_KEY")
                ?: localProps.getProperty("MAPS_API_KEY")
                ?: (if (dartMapsKey.isNotEmpty()) dartMapsKey else "")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}



flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.gms:play-services-maps:19.0.0")
}
