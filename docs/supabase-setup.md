# Supabase Setup

The app's code is wired for Supabase (auth, scan history, and reference data),
but the actual project has to be created on supabase.com - that step needs
your login, so it isn't something that can be automated.

## 1. Create the project

1. Go to https://supabase.com/dashboard and sign in (or create an account).
2. Click "New project", pick an organization, name it (e.g. `corn-detection`),
   set a database password (save it somewhere safe), and choose a region
   close to your users.
3. Wait for provisioning to finish (usually under two minutes).

## 2. Run the schema

1. In the project dashboard, open **SQL Editor > New query**.
2. Paste the contents of `supabase/schema.sql` (in this repo) and click Run.
   This creates the `profiles`, `scans`, and `deficiency_reference` tables,
   their row-level security policies, the `scan-photos` storage bucket, and
   seeds the reference data used by the Nutrient Guide and Fertilizer
   Recommendations screens.

## 3. Get your project keys

1. Open **Project Settings > API**.
2. Copy the **Project URL** and the **publishable** key (older projects may
   label this "anon public" instead - either way, it's the client-safe key,
   not the `secret` / `service_role` key, which must never go in the app).

## 4. Configure the app

Create a `supabase-keys.json` file at the repo root (it's already in
`.gitignore`, so it won't be committed):

```json
{
  "SUPABASE_URL": "https://YOUR-PROJECT-REF.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "YOUR-PUBLISHABLE-KEY"
}
```

Run or build the app with those values compiled in:

```bash
flutter run --dart-define-from-file=supabase-keys.json
```

Do the same for `flutter build` when producing a release build.

## 5. Email confirmation (optional, for local testing)

By default, Supabase requires users to confirm their email before they can
sign in. For quick local testing you can disable this in **Authentication >
Providers > Email > Confirm email**. Keep it enabled for production.

## What's wired up

- Login, sign up, forgot password: real Supabase Auth. Sign up also creates
  a matching row in `profiles` automatically (via a database trigger).
- Profile / Edit Profile: reads and updates the `profiles` row for the
  signed-in user. Email is shown but not editable (changing it needs a
  separate confirmation flow, not implemented).
- Scan: the detection itself is still the existing mock (see the TODO in
  `scan_screen.dart` - swapping in a real model is a separate task), but each
  mocked result and its photo are now saved to `scans` and
  `scan-photos` for the signed-in user.
- Scan History, Deficiency Alerts, Home dashboard: read the signed-in user's
  saved scans.
- Nutrient Guide, Fertilizer Recommendations: read the shared
  `deficiency_reference` table.
