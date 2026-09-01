# CoinVault Flutter UI

Pure Flutter frontend rebuild of the provided CoinVault reference image.

## What is included
- Splash, onboarding, auth, home, earn, task list, task detail, surveys
- Spin wheel, scratch card, daily check-in, challenges, refer & earn
- Wallet, withdraw methods, withdraw to UPI, withdrawal history
- Notifications, leaderboard, history, profile, settings, help center
- Shared theme + reusable buttons/cards so text size issues do not shrink buttons unexpectedly
- Animated splash, page transitions, spin wheel, scratch card pulse, balance card motion

## Run
```bash
flutter pub get
flutter run
```

## Project structure
```text
lib/
├── core/
│   ├── app_colors.dart
│   └── app_theme.dart
├── data/
│   └── mock_data.dart
├── models/
│   └── ui_models.dart
├── screens/
│   └── preview_app.dart
├── widgets/
│   ├── mascot_bear.dart
│   └── ui_kit.dart
└── main.dart
```

## Notes
- No HTML used.
- No external package dependency is required.
- All main buttons use a fixed min height and width policy through `AppPrimaryButton`, so longer labels stay stable.
- Replace the generated mascot widget later with a PNG/SVG asset if you want exact brand artwork.
