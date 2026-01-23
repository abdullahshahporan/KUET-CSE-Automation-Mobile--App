# ProGuard rules for Flutter app - keep essential Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
-keepattributes *Annotation*

# Keep generated model classes (if using reflection)
-keepclassmembers class * {
    public <init>(...);
}
