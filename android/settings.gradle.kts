pluginManagement {
    try {
        val peClass = Class.forName("java.lang.ProcessEnvironment")
        val field = peClass.getDeclaredField("theEnvironment")
        field.isAccessible = true
        @Suppress("UNCHECKED_CAST")
        val env = field.get(null) as MutableMap<String, String>
        env.remove("ANDROID_PREFS_ROOT")
        env.remove("ANDROID_SDK_HOME")

        val ciField = peClass.getDeclaredField("theCaseInsensitiveEnvironment")
        ciField.isAccessible = true
        @Suppress("UNCHECKED_CAST")
        val ciEnv = ciField.get(null) as MutableMap<String, String>
        ciEnv.remove("ANDROID_PREFS_ROOT")
        ciEnv.remove("ANDROID_SDK_HOME")
    } catch (e: Exception) {
        println("Env fix note: $e")
    }
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
