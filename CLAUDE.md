# Dinachari — rules for Claude

These are Kiran's standing rules for this repository. Follow them every time.

1. **Ask before every push.** Never push to this repository (any branch) without
   showing Kiran what will be pushed and getting a yes first.
2. **Every commit is authored only by Kiran.**
   - Author and committer: `Kiran <180390595+Kirann1973@users.noreply.github.com>`
   - No `Co-Authored-By` lines, no Claude / bot / GitHub Actions contributors,
     and no session or "Generated with" trailers in commit messages.

## Project

Dinachari is a daily habit tracker built with Flutter for Android, iOS, macOS
and Windows, with home-screen widgets.

- State: Riverpod (`lib/providers.dart`)
- Storage: Drift / SQLite (`lib/data/`). After changing tables run
  `dart run build_runner build -d` and bump `schemaVersion` with a migration.
- Widgets: `home_widget` bridge in `lib/services/widget_sync.dart`; native
  widgets are Jetpack Glance (Android) and WidgetKit (iOS/macOS). Windows uses a
  tray app instead.
- Checks before committing: `flutter analyze` and `flutter test`.
