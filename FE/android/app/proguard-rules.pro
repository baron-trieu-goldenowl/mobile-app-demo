# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Gson (used by flutter_local_notifications)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# sensors_plus / image_picker / shared_preferences / timezone
-dontwarn com.google.android.play.core.**
