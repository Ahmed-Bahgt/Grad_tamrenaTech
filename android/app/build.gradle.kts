plugins {
    id("com.android.application")
    id("kotlin-android")
    // إضافة Plugin الفايربيس هنا بالصيغة الصحيحة
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // تأكد أن هذا الاسم يطابق الموجود في Firebase Console
    namespace = "com.example.tamren_tech"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.tamren_tech"
        minSdk = flutter.minSdkVersion // يفضل تثبيته على 21 لدعم أغلب الأجهزة
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
