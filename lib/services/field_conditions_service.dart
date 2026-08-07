import 'dart:convert';
import 'dart:io';

import '../models/field_conditions.dart';

// Fetches current field conditions from Open-Meteo, which needs no API key.
// Uses dart:io directly so the project avoids an extra HTTP dependency.
class FieldConditionsService {
  // TODO: replace with the device location once a GPS permission flow exists.
  static const double _latitude = 14.6;
  static const double _longitude = 121.0;

  static const Duration _cacheTtl = Duration(minutes: 15);
  static const Duration _timeout = Duration(seconds: 10);

  FieldConditions? _cached;
  DateTime? _cachedAt;

  // Returns cached conditions when they are still fresh, otherwise refetches.
  // Throws on network or parse failure so the caller can show an error state.
  Future<FieldConditions> fetch() async {
    final cached = _cached;
    final cachedAt = _cachedAt;
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$_latitude',
      'longitude': '$_longitude',
      'current':
          'temperature_2m,relative_humidity_2m,soil_moisture_0_to_1cm',
      'timezone': 'auto',
    });

    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.getUrl(uri).timeout(_timeout);
      final response = await request.close().timeout(_timeout);

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Open-Meteo returned ${response.statusCode}', uri: uri);
      }

      final body = await response.transform(utf8.decoder).join().timeout(_timeout);
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Unexpected Open-Meteo response');
      }

      final conditions = FieldConditions.fromOpenMeteo(decoded);
      _cached = conditions;
      _cachedAt = DateTime.now();
      return conditions;
    } finally {
      client.close();
    }
  }
}
