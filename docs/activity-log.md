# Activity Log

## 2026-08-12: Center scan button redesigned to sit flush in the navbar notch

- User reported the camera FAB looked like it was "floating"/loose instead
  of anchored to the bottom bar - not an actual layout bug (position was
  identical and static across Home/Profile/Scan, all three use the same
  `FloatingActionButtonLocation.centerDocked` + `AppScanButton` wiring),
  just a visual read.
- `lib/widgets/app_bottom_nav.dart`, `AppScanButton`: replaced the oversized
  76dp translucent green halo (`_primaryColor` alpha 0.15 circle with a
  blurred colored shadow) with a 68dp solid white ring matching the bar's
  own surface color, a subtle neutral shadow (black alpha 0.08 instead of
  colored), and lower elevation (2 -> 1) on the inner button. The white
  ring reads as a continuation of the bar surface wrapping the notch,
  instead of a separate glowing circle hovering above it. Icon size
  26 (was 32) to match the smaller button.

## 2026-08-12: Multi-detection support (multiple leaves/regions per scan)

- Follow-up to the bounding box entry below - user asked what happens with
  "too many leaves" in one photo, then chose full multi-result support:
  each detected region gets its own label/confidence/box/recommendation,
  saved per region instead of per scan.
- `lib/models/scan_result.dart`: reworked. Added `Detection` (label,
  confidence, symptom, fertilizer, rate, timing, note, optional
  `DetectionBox`) and `DetectionBox` (fractional left/top/width/height).
  `ScanResult` is now id/createdAt/imagePath/`List<Detection> detections`
  (previously the single-detection fields lived directly on ScanResult).
  Added `ScanResult.isHealthy` (true only if every detection is Healthy)
  and `ScanResult.primaryDetection` (highest-confidence non-healthy
  detection, or the first one if the whole scan is healthy) for callers
  that need one representative result.
- `supabase/schema.sql`: `scans` is now photo-level only (id, user_id,
  image_path, created_at). Added `scan_detections` (one row per detected
  region: label, confidence, symptom, fertilizer, rate, timing, note,
  box_left/top/width/height, scan_id FK, user_id denormalized for RLS).
  Added `supabase/migrations/002_multi_detection_scans.sql` for the
  already-deployed project - backfills existing `scans` rows into
  `scan_detections` (box_* left null, no detection had a location before
  this) before dropping the old columns from `scans`. Safe to run twice.
  **User must run this migration manually in the Supabase SQL Editor -
  this session cannot reach *.supabase.co (see the 2026-08-12 Supabase
  wiring entry below).** Existing scan history is preserved by the
  backfill, not lost.
- `lib/services/scan_service.dart`: `saveScan` now takes
  `List<Detection> detections` and writes one `scans` row plus a batch
  insert into `scan_detections`. `getHistory` now selects
  `'*, scan_detections(*)'` so each `ScanResult` comes back with its full
  detection list already joined.
- `lib/screens/scan_screen.dart`: `_analyze()` now calls
  `_pickMockOutcomes()` instead of picking one outcome. Healthy is still
  never mixed with a deficiency (a photo is either all-healthy, 35% odds,
  or has 1-3 distinct deficiency detections - kept distinct so their fixed
  mock boxes, one per label, don't sit on top of each other; a real
  YOLOv8 model would give each detection its own real box instead).
  `_outcome` (single) is now `_outcomes` (list) throughout. Analysis and
  result steps draw one bounding box per outcome. Result step shows a
  "N regions detected" heading (only when >1) then one classification +
  recommendation card pair per detection; extracted the classification
  summary into `_buildOutcomeCard` so it can repeat per detection.
- `lib/screens/scan_history_screen.dart`: each history card now shows a
  Wrap of one chip per detection (label + confidence) instead of a single
  label/confidence pair.
- `lib/screens/deficiency_alerts_screen.dart`: alerts are now flattened to
  one card per non-healthy detection across all scans (new private
  `_AlertItem` pairing a `Detection` with its parent scan's date), instead
  of one card per non-healthy scan - a scan with one healthy and one
  deficient detection now correctly surfaces the deficient one here.
- `lib/screens/home_screen.dart`: `_latestResult`/`_latestConfidence` now
  read `_scans.first.primaryDetection` instead of fields that no longer
  exist directly on `ScanResult`. `_latestResult` appends `+N` when the
  latest scan has more than one detection (e.g. "Nitrogen Deficiency +1").
  `_healthyCount`/`_deficientCount` are unchanged (still scan-level via
  `ScanResult.isHealthy`, which now means "every detection in the scan is
  healthy").
- Not done / worth flagging: no dedicated UI yet for a scan that mixes a
  healthy leaf with a deficient one in the same photo (currently just
  shows both cards) - fine for a thesis-scope mock, worth a design pass
  once the real YOLOv8 model can actually produce this mix. Also, this
  sandbox cannot run `flutter analyze` (Flutter/Dart not installed here) -
  changes were checked by hand (brace/paren balance, grep for stale
  references to the old single-detection fields) but not compiled; run
  `flutter analyze` locally before trusting this fully.

## 2026-08-12: Mocked bounding box overlay + bigger scan-screen image

- User asked for the scan screen to show a bounding box drawn directly on the
  photo, and for the photo display to be bigger from the capture step through
  the result step so the box is clearly visible. The paper (`CORNLEAFNUTRIENTDEFICIENCIESDETECTIONPAPER.pdf`)
  specifies YOLOv8 for real detection/localization + EfficientNetB0 for
  classification, but neither is wired up yet - `_analyze()` is still the
  existing mock (random pick from `_mockOutcomes`, see its TODO). There is no
  real detection output to draw a box from yet.
- Added `_BoundingBox` (fractional left/top/width/height, 0.0-1.0) and a
  `box` field on `_ScanOutcome`, with one hand-picked mock rect per outcome
  (healthy/N/P/K) in `scan_screen.dart`. `_analyze()` now picks the outcome
  upfront instead of after the fake delay, so the box is already known while
  the analysis step "runs", not just at the result step.
- Added `_buildBoundingBoxOverlay` (LayoutBuilder + Positioned + Container
  border, no new dependency) drawn on top of the photo in both the analysis
  and result steps, with a colored label chip matching the outcome.
- Enlarged the photo container across all three steps: capture 260 -> 320,
  analysis 240 -> 320, result 200 -> 300 (now a Stack instead of a bare
  `Image.file` so the overlay can sit on top).
- Not real detection: the box position is a fixed mock per outcome, not
  computed from the photo. Swapping `_analyze()` for a real YOLOv8 call
  (per the TODO) should return real bounding box coordinates and populate
  `_ScanOutcome.box` (or a separate per-scan box) from that instead of the
  hand-picked mock values here.

## 2026-08-12: Replaced camera capture with in-app live preview (camera package)

- Root cause of a long-running bug: "Take Photo" used image_picker's
  `ImageSource.camera`, which launches the system Camera app via intent and
  backgrounds this app while it's open. Android was killing the app's
  process while backgrounded (common on real devices, not just an emulator
  quirk), losing the in-progress navigation state and the captured photo.
  Two rounds of trying to recover from this after the fact (a pending-capture
  flag + `ImagePicker().retrieveLostData()` in `home_screen.dart`, then
  dropping the picker's `maxWidth`/`imageQuality` resize) did not make
  recovery reliable - confirmed by testing on-device.
- Fix: added `lib/screens/scan/camera_capture_screen.dart`, a full-screen
  live preview using the `camera` package. `scan_screen.dart`'s "Take Photo"
  now pushes this screen and gets the file back via `Navigator.pop`, instead
  of calling the picker with `ImageSource.camera`. This keeps the app in the
  foreground for the whole capture, so there's no external app to lose focus
  to and nothing to recover - Android has no reason to kill it.
- Removed the now-unnecessary recovery plumbing: `ScanScreen.initialImage`,
  `HomeScreen._recoverLostCapture`/`_checkingRecovery` and its loading
  screen, and `lib/core/pending_capture.dart` (now unused - **should be
  deleted manually**, this session can't delete files on the user's machine).
  Gallery upload (`_pickFromGallery`) is unchanged and still uses image_picker.
- Added `camera: ^0.12.0+2` to `pubspec.yaml`.
- Re-added `android.permission.CAMERA` to `AndroidManifest.xml`. Note this
  directly reverses the 2026-08-03 entry below ("Removed
  `android.permission.CAMERA`...") - that removal was correct for the old
  intent-based capture, which delegated permission handling to the system
  Camera app. The `camera` package opens the hardware directly from within
  this app, so it now needs and must request this permission itself. If a
  future change reintroduces intent-based capture, re-remove it as before.
- Also fixed a separate, unrelated UI bug found during this work: the
  camera FAB (`AppScanButton` in `app_bottom_nav.dart`) twitched when
  navigating between screens because every instance shared Flutter's
  default `heroTag`. Fixed with `heroTag: null`.
- Not yet done: no flash toggle or front/back camera switch in the new
  camera screen (kept minimal - back camera only, matches the leaf-scanning
  use case). Photos are captured at full camera resolution (no
  resize/compress before upload) - worth revisiting if upload size/time to
  Supabase becomes a problem.

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
