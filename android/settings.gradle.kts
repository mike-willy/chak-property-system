pluginManagement {
    val properties = java.util.Properties()
    val propertiesFile = java.io.File("local.properties")
    if (propertiesFile.exists()) {
        propertiesFile.inputStream().use { properties.load(it) }
    }

    val flutterSdkPath = properties.getProperty("flutter.sdk")
    if (flutterSdkPath != null) {
        includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    }

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.4.1" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
    id("com.google.gms.google-services") version "4.4.0" apply false
}

include(":app")