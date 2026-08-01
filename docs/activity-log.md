# Activity Log

## 2026-08-01: Sign up / login screens (UI only)

- Added `lib/app.dart` as the root widget (theme + initial route), replacing the default counter app in `main.dart`.
- Added `lib/core/validators.dart` with shared form validation (email, password, confirm password, name).
- Added `lib/screens/auth/login_screen.dart` and `lib/screens/auth/signup_screen.dart` with local form validation, no backend wired up yet.
- Added `lib/screens/home_screen.dart` as a placeholder landing screen after successful login/signup.
- No auth backend chosen yet (deferred: Firebase Auth vs local on-device auth vs other). Current submit handlers just validate and navigate.
