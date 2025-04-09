# Flutter & Dio 등 HTTP 통신 관련 보존 설정
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**

-keep class retrofit2.** { *; }
-dontwarn retrofit2.**

-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Flutter Plugin 내부 클래스 유지
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.plugins.**

# Cloudinary 사용 시 필요
-keep class com.cloudinary.** { *; }
-dontwarn com.cloudinary.**
