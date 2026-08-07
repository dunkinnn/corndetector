# Activity Log

## 2026-08-03: Scan screen offers Take Photo / Upload from Gallery choice

- Replaced the auto-opening camera with a bottom sheet (`_showImageSourceSheet`) offering "Take Photo" or "Upload from Gallery", triggered by tapping the photo tile, the "Change Photo" pill, or the FAB - the user picks the source instead of the camera opening automatically.
- Generalized `_captureFromCamera` into `_pickImage(ImageSource source)` shared by both paths, with the same re-entrancy guard and error handling (now also covers `photo_access_denied` for the gallery).

## 2026-08-03: Scan screen reworked to auto-open camera; fixed camera_access_denied

- Reworked `scan_screen.dart` to a capture-only flow (no gallery choice): camera opens automatically via `initState`'s post-frame callback, and again after "Scan Another Leaf".
- Removed `android.permission.CAMERA` from `AndroidManifest.xml` - image_picker launches the system Camera app via intent and doesn't need this permission; declaring it forced Android to require a runtime grant that nothing in the app requested, causing every capture to fail with `camera_access_denied`.
- Added a re-entrancy guard and try/catch with a SnackBar around the picker call so permission/hardware failures show a message instead of failing silently.

## 2026-08-03: Scan flow (Upload -> Analysis -> Result)

- Added `lib/screens/scan_screen.dart`: 3-step scan flow (upload photo via camera/gallery, simulated analysis, mocked deficiency result), reusing the existing `AppTopBar` header and the Home/Monitoring bottom nav + center FAB pattern.
- Added `image_picker` dependency for camera/gallery photo selection; added iOS `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` to `Info.plist`.
- Wired the center FAB on Home and Monitoring screens to navigate to `ScanScreen` (previously a no-op state change).
- Detection result is a mocked random pick (`_mockOutcomes` in `scan_screen.dart`) - no real model wired up yet (deferred, see TODO on `_analyze`).

## 2026-08-01: Sign up / login screens (UI only)

- Added `lib/app.dart` as the root widget (theme + initial route), replacing the default counter app in `main.dart`.
- Added `lib/core/validators.dart` with shared form validation (email, password, confirm password, name).
- Added `lib/screens/auth/login_screen.dart` and `lib/screens/auth/signup_screen.dart` with local form validation, no backend wired up yet.
- Added `lib/screens/home_screen.dart` as a placeholder landing screen after successful login/signup.
- No auth backend chosen yet (deferred: Firebase Auth vs local on-device auth vs other). Current submit handlers just validate and navigate.
