# Glance creates widget tap handlers (ActionCallback) by class name, so keep
# the widget classes when release builds shrink the code.
-keep class com.kiran.dinachari.widget.** { *; }
-keep class * implements androidx.glance.appwidget.action.ActionCallback { *; }
