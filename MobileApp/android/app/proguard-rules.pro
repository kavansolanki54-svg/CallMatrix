# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn androidx.appcompat.R$attr
-dontwarn androidx.appcompat.R$dimen
-dontwarn androidx.appcompat.R$id
-dontwarn androidx.appcompat.R$layout
-dontwarn androidx.appcompat.R$string
-dontwarn androidx.appcompat.R$style
-dontwarn androidx.appcompat.R$styleable
-dontwarn androidx.appcompat.resources.R$drawable
-dontwarn androidx.appcompat.resources.R$styleable
-dontwarn androidx.core.R$attr
-dontwarn androidx.core.R$id
-dontwarn androidx.core.R$styleable
-dontwarn androidx.preference.R$attr
-dontwarn androidx.preference.R$id
-dontwarn androidx.preference.R$layout
-dontwarn androidx.preference.R$string
-dontwarn androidx.preference.R$styleable
-dontwarn androidx.recyclerview.R$styleable
-dontwarn androidx.window.extensions.area.ExtensionWindowAreaPresentation
-dontwarn androidx.work.R$bool
-dontwarn id.flutter.flutter_background_service.R$drawable

# Keep native Callalyze app components to prevent R8 from renaming or stripping them
-keep class com.callalyze.call_alyze_mobile.CallSyncForegroundService { *; }
-keep class com.callalyze.call_alyze_mobile.CallEndedOverlayActivity { *; }
-keep class com.callalyze.call_alyze_mobile.CallStateReceiver { *; }
