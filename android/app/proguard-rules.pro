# Flutter specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }

# Flutter wrapper
-keep class io.flutter.plugin.editing.** { *; }

# Avoid stripping needed classes for Flutter
-keep class androidx.lifecycle.** { *; }
-keep class io.flutter.embedding.android.FlutterView { *; }
-keep class io.flutter.embedding.android.FlutterSurfaceView { *; }
-keep class io.flutter.embedding.android.FlutterTextureView { *; }
-keep class io.flutter.embedding.android.FlutterFragmentActivity { *; }
-keep class io.flutter.embedding.engine.** { *; }

# Flutter WebView
-keep class io.flutter.plugins.webviewflutter.** { *; }

# Flutter Security
-keepclassmembers class * {
    *** getFlutterEngine();
}

# Ignore missing Play Core classes for Flutter
-dontwarn com.google.android.play.core.tasks.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn com.google.android.play.core.splitinstall.**

# Keep Play Core feature-delivery classes
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.common.** { *; }
-keep class com.google.android.play.core.listener.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Resolve duplicate class issues
-dontnote com.google.android.play.core.**
-dontwarn com.google.android.play.core.**

# Kotlin serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

# Most of volatile fields are updated with AFU and should not be mangled
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# Keep native methods
-keepclasseswithmembers class * {
    native <methods>;
}

# Accessibility service
-keep class * extends android.accessibilityservice.AccessibilityService { *; }

# Service classes
-keep class com.einsteini.app.EinsteiniAccessibilityService { *; }
-keep class com.einsteini.app.EinsteiniOverlayService { *; }

# Prevent proguard from stripping interface information
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep setters in Views so that animations can still work.
-keepclassmembers public class * extends android.view.View {
   void set*(***);
   *** get*();
}

# For enumeration classes
-keepclassmembers enum * { *; }

# For JSON parsing
-keepattributes Signature
-keep class org.json.** { *; }

# Parcelable implementations are accessed by introspection
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep R classes
-keep class **.R
-keep class **.R$* {
    <fields>;
} 