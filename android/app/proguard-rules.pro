# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Provider
-keep class com.example.pomodoro_flutter.models.** { *; }

# Awesome Notifications
-keep class me.carda.awesome_notifications.** { *; }
-keep class androidx.core.app.** { *; }
-keep class android.app.** { *; }

# SharedPreferences
-keep class android.app.SharedPreferences { *; }

# Keep all native methods, their classes and any class in the same package
-keepclasseswithmembers class * {
    native <methods>;
}

# Keep all classes in the app package
-keep class com.example.pomodoro_flutter.** { *; }

# Keep all Kotlin classes
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Keep all classes that might be used in XML layouts
-keep public class * extends android.view.View
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Keep all parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep all serializables
-keep class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
