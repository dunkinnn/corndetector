import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase project credentials. The publishable key is safe to ship in
// client code (paired with the RLS policies in supabase/schema.sql) -
// unlike the secret/service_role key, which must never appear here.
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = 'https://hhotqlrlyjnebzvxukoo.supabase.co';
  static const String publishableKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhob3RxbHJseWpuZWJ6dnh1a29vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY0MTcwMjEsImV4cCI6MjEwMTk5MzAyMX0.PLOenbrJtOr_2EJFYbf5wv3wG5hDudDDXGWfd_c1kzU';

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }
}

// Shorthand for the active Supabase client, used throughout the services.
SupabaseClient get supabase => Supabase.instance.client;
