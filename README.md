# Dinachari

A simple daily habit tracker (दिनचर्या, "daily routine") for Android, iOS,
macOS and Windows, with home-screen widgets.

## What works now (v0.2)

- Habits with your own icon (36 to choose from, like gym, bath, water,
  meditate), a color, and a type: tick it off, or count it toward a daily
  goal (e.g. 8 glasses of water)
- Today screen in the mockup's style: navy background, white cards, big
  streak numbers, a "+1" button for counted habits, and a 15-week heatmap
- Habit page with current and best streak, days done, last-30-days
  consistency, and a heatmap where you can tap a past day to fix it
- Android home-screen widget: tap a habit to tick it (or +1), even with the
  app closed; the app picks up widget taps when it opens
- Everything is stored on the device (SQLite); upgrading keeps your habits

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
