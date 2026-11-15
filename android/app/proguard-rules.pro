# R8 (the release code shrinker) rules for the app.

# ML Kit text recognition (receipt scanning): the Flutter plugin refers to the Chinese,
# Devanagari, Japanese and Korean recognizers, but we only ship the Latin one on purpose
# (smaller APK, Turkish receipts use Latin letters). Those classes are missing by design,
# so R8 must not stop the build because of them.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
