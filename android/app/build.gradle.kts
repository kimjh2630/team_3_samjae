import java.util.Properties   // ← 최상단에 위치시킵니다

// local.properties 로부터 키를 읽어들입니다
val localProps = Properties().apply {
    val propFile = rootProject.file("local.properties")
    if (propFile.exists()) {
        propFile.inputStream().use { load(it) }
    }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.project"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.project"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName


        // manifestPlaceholders에 API 키·설정값 등록
        manifestPlaceholders["NAVER_MAP_API_KEY"]         = localProps.getProperty("NAVER_MAP_API_KEY", "")
        manifestPlaceholders["NAVER_LOGIN_CLIENT_ID"]     = localProps.getProperty("NAVER_LOGIN_CLIENT_ID", "")
        manifestPlaceholders["NAVER_LOGIN_CLIENT_SECRET"] = localProps.getProperty("NAVER_LOGIN_CLIENT_SECRET", "")
        manifestPlaceholders["NAVER_LOGIN_CLIENT_NAME"]   = localProps.getProperty("NAVER_LOGIN_CLIENT_NAME", "")
        manifestPlaceholders["KAKAO_SDK_APP_KEY"]         = localProps.getProperty("KAKAO_SDK_APP_KEY", "")


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
