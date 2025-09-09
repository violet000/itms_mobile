# Flutter相关规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# 保持Flutter引擎相关类
-keep class io.flutter.embedding.** { *; }

# 保持自定义的库位可视化相关类
-keep class com.example.itms_mobile.** { *; }

# 保持所有native方法
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保持枚举类
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 保持特定的枚举类不被混淆
-keep class * extends java.lang.Enum {
    <fields>;
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 保持LandmarkStatus等关键枚举
-keep class com.example.itms_mobile.core.constants.constant.LandmarkStatus { *; }
-keep class com.example.itms_mobile.core.constants.constant.PalletStatus { *; }
-keep class com.example.itms_mobile.core.constants.constant.LocationType { *; }
-keep class com.example.itms_mobile.core.constants.constant.LandmarkType { *; }

# 保持Serializable类
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# 保持Parcelable类
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# 保持R类
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# 保持第三方库
-keep class com.google.** { *; }
-keep class androidx.** { *; }

# 防止混淆可能导致的问题
-dontwarn com.google.**
-dontwarn androidx.**
-dontwarn io.flutter.**

# 优化选项
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# 保持行号信息用于调试
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile