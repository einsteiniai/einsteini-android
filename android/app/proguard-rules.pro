# Flutter specific ProGuard rules
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }

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