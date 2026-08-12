# Activity Log

## 2026-08-12: Fixed deprecated withOpacity() calls in profile_screen.dart

- Replaced 3 uses of the deprecated `Color.withOpacity()` with
  `Color.withValues(alpha:)` (background accent circle, avatar ring, card
  shadow) per the analyzer's `deprecated_member_use` warnings. Note: the
  file's `_buildUserHeader` was restructured (now `_buildModernUserHeader`,
  a hero-card style with badge overlay, edit access moved to the Account
  Management tile below) since the last entry - not this session's change.

## 2026-08-12: Profile header redesign

- `profile_screen.dart`, `_buildUserHeader`: bigger avatar (radius 28 -> 30),
  added `maxLines`/`overflow` to name and email so a long value truncates
  instead of wrapping and breaking the row layout, and replaced the cramped
  "Edit" text link with a rounded icon button (matches the icon-box style
  already used in the settings tiles below it).

## 2026-08-12: Home screen always shows "Farmer" instead of the real name

- `home_screen.dart`: removed the `ProfileService` lookup and the
  fallback-to-"Farmer" logic; `_displayName` is now a fixed `'Farmer'` string,
  per user request - the greeting no longer shows the signed-in user's real
  name.

## 2026-08-12: Verified Supabase wiring, fixed missing release INTERNET permission

- Confirmed `supabase-keys.json` and `lib/core/supabase_config.dart` hold matching
  project URL/publishable key, and `main.dart` calls `SupabaseConfig.initialize()`
  on startup - the app is wired to reach the Supabase project.
- Note: `supabase_config.dart` now hardcodes the URL/key instead of reading them
  via `String.fromEnvironment` from `--dart-define-from-file` as originally built
  on 2026-08-11 (see `docs/supabase-setup.md`). Left as-is since the publishable/
  anon key is safe to ship in client code, but flagged to the user as a deviation
  from the documented setup - worth reverting if `supabase-keys.json` should stay
  the single source of truth.
- Fixed `android/app/src/main/AndroidManifest.xml`: added the `INTERNET`
  permission. The debug/profile manifests already grant it (Flutter tooling
  adds it for hot reload), so `flutter run` worked, but release builds only use
  the main manifest and would have silently failed all Supabase network calls.
- Could not verify the `supabase/schema.sql` tables exist from this session -
  this sandbox's network is allowlisted and does not include `*.supabase.co`.
  User should confirm via the Supabase dashboard Table Editor.
- User ran `flutter pub get` and `flutter analyze` locally: clean resolve, no
  analyzer issues. Confirms the wiring compiles cleanly; still need to confirm
  it works at runtime against the live project.

## 2026-08-11: Supabase backend wired up (auth, scans, reference data)

- Added `supabase_flutter` dependency and `lib/core/supabase_config.dart`
  (client init from `--dart-define`, see `docs/supabase-setup.md`); credentials
  are never hardcoded.
- Added `supabase/schema.sql`: `profiles`, `scans`, `deficiency_reference`
  tables with row-level security, a `scan-photos` storage bucket, and a
  trigger that creates a profile row on sign up.
- Added service layer (`lib/services/`): `auth_service.dart`,
  `profile_service.dart`, `scan_service.dart`, `reference_data_service.dart`,
  and matching models in `lib/models/`.
- Wired `login_screen.dart`, `signup_screen.dart`, `forgot_password_screen.dart`
  to real Supabase Auth. Login no longer saves the password in
  `SharedPreferences` in plaintext - "Save Password" is now "Remember Email"
  and only stores the email; the session itself persists via Supabase's own
  secure local storage. `main.dart`/`app.dart` now initialize Supabase and
  route straight to Home if a session already exists.
- Wired `profile_screen.dart` (real name/email, logout calls
  `AuthService.signOut`) and `edit_profile_screen.dart` (loads/saves the real
  profile; removed the non-functional "Change Photo" button - avatar upload
  isn't implemented yet; email field is read-only since changing it needs a
  separate confirmation flow).
- `scan_screen.dart`: detection is still the existing mock (see its TODO -
  wiring a real model is a separate task), but each mocked result and photo
  now get saved to `scans` / `scan-photos` after analysis.
- `scan_history_screen.dart` and `deficiency_alerts_screen.dart` now list the
  signed-in user's real scans instead of a static empty state.
  `home_screen.dart`'s latest-detection card and scan counts now read from
  the same data instead of hardcoded placeholders.
- `nutrient_guide_screen.dart` and `fertilizer_recommendations_screen.dart`
  now read from the `deficiency_reference` table (seeded in schema.sql)
  instead of showing a static empty state.
- Not done: the actual Supabase project has to be created on supabase.com
  by the user (see `docs/supabase-setup.md`) - this can't be automated
  since it requires their account login.

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
