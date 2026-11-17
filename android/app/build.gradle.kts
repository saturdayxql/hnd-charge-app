import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Local paths and alias stay in an ignored file; passwords come from this process only.
val releasePropertiesFile = rootProject.file("key.properties")
val releaseProperties = Properties()
if (releasePropertiesFile.isFile) {
    releasePropertiesFile.inputStream().use { releaseProperties.load(it) }
}
val releaseStoreFile = releaseProperties.getProperty("storeFile")
    ?.takeIf { it.isNotBlank() }
    ?.let { rootProject.file(it) }
val releaseKeyAlias = releaseProperties.getProperty("keyAlias")
val releaseStoreType = releaseProperties.getProperty("storeType") ?: "PKCS12"
val releasePassword = providers.environmentVariable("HENONG_SIGNING_PASSWORD").orNull

val validateReleaseSigningInputs = tasks.register("validateReleaseSigningInputs") {
    group = "verification"
    description = "Require the private release key and session password; never fall back to debug signing."
    doLast {
        if (!releasePropertiesFile.isFile) {
            throw GradleException("Missing android/key.properties. Copy key.properties.example and configure your private keystore.")
        }
        if (releaseStoreFile == null || !releaseStoreFile.isFile) {
            throw GradleException("Release keystore not found. Create the long-term signing key before a release build.")
        }
        if (releaseKeyAlias.isNullOrBlank()) {
            throw GradleException("Missing keyAlias in android/key.properties.")
        }
        if (releasePassword.isNullOrBlank()) {
            throw GradleException("Set HENONG_SIGNING_PASSWORD in the current terminal before a release build. Do not put the password in source files.")
        }
    }
}

// Debug development remains available without release credentials.
tasks.configureEach {
    if (name in setOf("preReleaseBuild", "validateSigningRelease", "packageRelease", "assembleRelease", "bundleRelease")) {
        dependsOn(validateReleaseSigningInputs)
    }
}

android {
    namespace = "io.github.saturdayxql.henongcharge"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.saturdayxql.henongcharge"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = releaseStoreFile
            storeType = releaseStoreType
            keyAlias = releaseKeyAlias
            storePassword = releasePassword
            // The PKCS12 signing key uses the same password as its keystore.
            keyPassword = releasePassword
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// Reduce the sideload APK download size. Android extracts these libraries at install time.
// Keep debug packaging unchanged; this setting does not change the native code itself.
androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        variant.packaging.jniLibs.useLegacyPackaging.set(true)
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
