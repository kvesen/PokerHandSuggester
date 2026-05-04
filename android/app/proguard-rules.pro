# Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# TFLite Flutter plugin
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Hive
-keep class com.hivedb.** { *; }
-keep class ** implements com.hivedb.** { *; }

# Keep class names referenced by reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Standard Flutter ProGuard rules
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.**
