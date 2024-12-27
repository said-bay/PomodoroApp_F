# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Awesome Notifications
-keep class me.carda.awesome_notifications.** { *; }

# Reflection
-keep class java.lang.reflect.** { *; }
-keep class sun.reflect.** { *; }
-keep class com.google.common.reflect.** { *; }

# SharedPreferences
-keep class android.content.SharedPreferences { *; }
-keep class androidx.preference.** { *; }

# Prevent proguard from stripping interface information from TypeAdapter, TypeAdapterFactory,
# JsonSerializer, JsonDeserializer instances (so they can be used in @JsonAdapter)
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep our interfaces so they can be used by other ProGuard rules
-keep,allowobfuscation interface com.google.gson.reflect.TypeToken
-keep,allowobfuscation class * implements com.google.gson.reflect.TypeToken

# Basic Android components
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.backup.BackupAgentHelper
-keep public class * extends android.preference.Preference

# Keep all classes in the app package
-keep class com.example.pomodoro_flutter.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep parcelables
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Don't warn about missing classes from common Android APIs
-dontwarn android.app.**
-dontwarn android.content.**
-dontwarn android.graphics.**
-dontwarn android.net.**
-dontwarn android.os.**
-dontwarn android.view.**
-dontwarn android.window.**

# Don't warn about missing Flutter classes
-dontwarn io.flutter.**
-dontwarn io.flutter.embedding.**
-dontwarn io.flutter.plugin.**
-dontwarn io.flutter.util.**
-dontwarn io.flutter.view.**

# Don't warn about google common classes
-dontwarn com.google.common.**
-dontwarn com.google.android.gms.**

# Keep important attributes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keepattributes EnclosingMethod
-keepattributes InnerClasses
