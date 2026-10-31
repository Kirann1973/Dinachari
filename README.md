# Dinachari

A simple daily habit tracker (दिनचर्या, "daily routine") for Android, iOS,
macOS and Windows, with home-screen widgets.

## What works now (v0.2)

- Give each habit any look: any emoji (combine up to 3, like 🛁🧴), one of
  ~4,000 searchable icons, your own photo, or a few letters, plus a color
- Two kinds of habit: tick it off, or count it toward a daily goal
  (e.g. 8 glasses of water)
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

## Credits

Fonts: Inter and Space Grotesk (SIL Open Font License); icons: Material
Symbols (Apache 2.0). Licenses are in `assets/fonts/`.

## Stack

Flutter + Riverpod, Drift (SQLite), `home_widget`, Jetpack Glance (Android
widget), WidgetKit (iOS/macOS widget). Social features with Supabase later.
