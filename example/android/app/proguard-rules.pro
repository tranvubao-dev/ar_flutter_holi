# Sceneform & ARCore
-keep class com.google.ar.sceneform.** { *; }
-keep class com.google.ar.core.** { *; }

# Desugar
-keep class com.google.devtools.build.android.desugar.runtime.** { *; }

-dontwarn com.google.ar.sceneform.**
-dontwarn com.google.devtools.build.android.desugar.runtime.**
