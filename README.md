# CoinVault Flutter App

A Flutter mobile app for earning coins via tasks, offers, surveys, spin wheel, and scratch cards.

## Backend API

This app connects to the CoinVault backend:

- **Main API:** `https://coinvault-api.onrender.com`
- **Auth Worker:** `https://coinvault-auth.coinvault.workers.dev`

ApiBaseUrl is configured in `lib/core/api_config.dart` and can be overridden at build time:

```sh
flutter run --dart-define=API_BASE_URL=https://coinvault-api.onrender.com
```

## Getting Started

```sh
flutter pub get
flutter run
```

## Features

- Spin Wheel & Scratch Card games
- Task completion (app installs, registrations, etc.)
- Survey completion
- Referral rewards
- Daily check-in bonus
- UPI / Bank Transfer withdrawals
- Gift card redemptions (Amazon, Google Play)
- Real-time leaderboard
- Push notifications (Firebase)