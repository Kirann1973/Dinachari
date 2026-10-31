# Dinachari

A simple daily habit tracker (दिनचर्या, "daily routine") for Android, iOS,
macOS and Windows, with home-screen widgets.

## What works now (v0.4)

- Give each habit any look: any emoji (combine up to 3, like 🛁🧴), one of
  ~4,000 searchable icons, your own photo, or a few letters, plus a color
- Two kinds of habit: tick it off, or count it toward a daily goal
  (e.g. 8 glasses of water)
- Repeat days: every day, weekdays, weekends, or any days you pick. Days off
  don't break streaks
- Reminders at a set time or every few hours between two times, as
  notifications. Each habit can have its own sound: phone default, silent,
  six built-in sounds, or (on Android) any sound on your phone
- Today screen in the mockup's style, with this week's graph, a 15-week
  heatmap and Sprout, the streak plant
- A side menu (hide it on wide screens) with History (past days, weeks and
  months; fix past days), Graphs (weekly and monthly), Plant and Archived
  (restore or delete archived habits)
- Habit page with current and best streak, consistency, and a heatmap where
  you can tap a past day to fix it
- Android home-screen widget that scrolls: today's habits (tap to tick or
  +1, even with the app closed), then the week graph, heatmap and plant
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
