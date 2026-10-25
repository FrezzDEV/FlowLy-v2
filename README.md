# FlowLy

Flutter mobile UI prototype for the FlowLy music app. The current phase is intentionally UI-only: catalogue, playback, mixes, profile data and search results are demonstration content. No external music provider or backend is called.

## Requirements
- Flutter stable (Dart 3.3+)
- Android SDK (for local APK builds)

## Run locally
```bash
flutter pub get
flutter run
```

## Build APK locally
```bash
flutter build apk --release
mv build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/FlowLy.apk
```
Artifact: `build/app/outputs/flutter-apk/FlowLy.apk`.

## Download APK

- **Latest stable build:** [Download FlowLy.apk](https://github.com/FrezzDEV/FlowLy-v2/releases/latest/download/FlowLy.apk)
- **Latest preview build:** [Download FlowLy.apk](https://github.com/FrezzDEV/FlowLy-v2/releases/download/preview/FlowLy.apk)

The feature-branch workflow publishes the APK as a direct release asset, so you do not need to download the ZIP-wrapped Actions artifact.

## GitHub Actions
Workflow `.github/workflows/android-apk.yml` runs on pushes, pull requests and manual dispatch. It resolves dependencies, runs static analysis and widget tests, builds a release APK and uploads it as the `FlowLy-release-apk` artifact. Open the Actions run and download the artifact.

## Structure
```
lib/
  app.dart
  main.dart
  core/network/api_client.dart
  features/
    home/home_screen.dart
    search/search_screen.dart
    library/library_screen.dart
    profile/profile_screen.dart
test/widget_test.dart
.github/workflows/android-apk.yml
```

## Future API boundary
Add repositories per feature (e.g. `HomeRepository`, `SearchRepository`, `LibraryRepository`, `ProfileRepository`) and inject an `ApiClient` when backend integration begins. Configure the base URL with `--dart-define=API_BASE_URL=https://your-api.example/api`. The placeholder defaults to `http://10.0.2.2:8000/api` for an Android emulator.

## UI notes
- Dark theme, responsive 3×3 quick-access grid, horizontally scrolling popular tracks and mixes, recent track list with context menus.
- Four working bottom tabs: Home, Search, Library, Profile.
- Playback, catalogue search and settings actions are deliberately placeholders until the UI is approved.
