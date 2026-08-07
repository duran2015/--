plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.currantmind.kelu"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // applicationId 与微信开放平台登记一致（com.currantmind.kelu），微信支付按包名+签名校验
        applicationId = "com.currantmind.kelu"
        // minSdk 24：对齐 xinyuAndroid/app/build.gradle（TRTC 咨询室链路要求）
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    packaging {
        jniLibs {
            // 强制从生成的 APK 中剔除 32 位 (armeabi-v7a / x86) 动态库，防止三方 AAR/Plugin 自动打入 32 位 so
            excludes.add("lib/armeabi-v7a/**")
            excludes.add("lib/x86/**")
        }
    }

    signingConfigs {
        create("release") {
            storeFile = file("../kelu_release.jks")
            storePassword = "123456"
            keyAlias = "kelu_key"
            keyPassword = "123456"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            ndk {
                // 发布包仅保留 64 位 ARM 架构以缩减 APK 包体积。
                abiFilters.clear()
                abiFilters.add("arm64-v8a")
            }
        }
        debug {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
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

dependencies {
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")

    // ================================================================
    // 网易云信 NIM 厂商混合推送 SDK（离线推送：App 进程被杀后由厂商通道投递）
    // ----------------------------------------------------------------
    // ⚠️ 仅在网易云信控制台「证书管理 → Android 第三方推送」开通了对应厂商后，
    //    才取消该厂商注释。确切 artifact 与版本号请以控制台「推送配置 → 下载 SDK」
    //    给出的 gradle 依赖为准（版本会更新）。证书名(certName) 在 Dart 侧 ImConfig 配置。
    //
    // —— 华为（HMS Push）——
    //   1) 根 settings.gradle.kts 的 pluginManagement / dependencies 加华为 gradle 插件源；
    //   2) 本文件顶部 plugins{} 加：id("com.huawei.agconnect.agcp") version "<见控制台>"
    //   3) 把华为控制台下载的 agconnect-services.json 放到 app/ 目录；
    //   4) 取消下行注释（版本以控制台为准）：
    // implementation("com.huawei.hms:push:<版本>")
    //
    // —— 小米 ——
    // implementation("com.xiaomi.mipush:xmpush:<版本>")
    // —— OPPO ——
    // implementation("com.heytap.msp:push:<版本>")
    // —— vivo ——
    // implementation("com.vivo.push:vivo-push:<版本>")
    // —— 魅族 ——
    // implementation("com.meizu.flyme.internet:push-internal:<版本>")
    // ================================================================
}
