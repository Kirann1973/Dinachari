# Dinachari

A simple daily habit tracker (दिनचर्या, "daily routine") for Android, iOS,
macOS and Windows, with home-screen widgets.

## What works now (v0.1)

- Add, edit, archive and delete habits, each with an emoji
- Tap a habit to check it off for today
- Current streak, best streak and total days per habit
- 12-week history grid; tap a past day to fix a missed check-in
- Everything is stored on the device (SQLite)
- Today's summary is shared with home-screen widgets (native widgets come next)

## Run it

```sh
flutter pub get
flutter run            # pick a connected phone, simulator or desktop
flutter test
```

After changing database tables, regenerate code with
`dart run build_runner build -d`.

## Stack

Flutter + Riverpod, Drift (SQLite), `home_widget`, Jetpack Glance (Android
widget), WidgetKit (iOS/macOS widget). Social features with Supabase later.
