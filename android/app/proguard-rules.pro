# ProGuard rules for Flutter app - keep essential Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
-keepattributes *Annotation*

# Geolocator
-keep class com.baseflow.geolocator.** { *; }
-keep class com.google.android.gms.location.** { *; }

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Keep generated model classes (if using reflection)
-keepclassmembers class * {
    public <init>(...);
}

# Suppress R8 warnings for optional OpenTelemetry / Jackson classes
-dontwarn com.fasterxml.jackson.core.JsonFactory
-dontwarn com.fasterxml.jackson.core.JsonGenerator
-dontwarn com.google.auto.value.AutoValue$CopyAnnotations

# OneSignal — keep all SDK classes so background push works in release builds
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# flutter_background_service — keep background service classes for R8
-keep class id.flutter.flutter_background_service.** { *; }
-dontwarn id.flutter.flutter_background_service.**
