# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class plugins.flutter.io.**  { *; }

# MediaPipe / tasks-genai missing classes
-dontwarn javax.lang.model.**
-keep class javax.lang.model.** { *; }

-dontwarn autovalue.shaded.com.squareup.javapoet.**
-keep class autovalue.shaded.com.squareup.javapoet.** { *; }

-dontwarn com.google.auto.value.**
-keep class com.google.auto.value.** { *; }

-dontwarn com.google.mediapipe.**
-keep class com.google.mediapipe.** { *; }

# Flutter Play Store Split Install (Deferred Components) missing classes
-dontwarn com.google.android.play.core.**
