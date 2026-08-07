// Current field conditions shown on the Home dashboard.
class FieldConditions {
  const FieldConditions({
    this.temperatureC,
    this.humidityPercent,
    this.soilMoisture,
  });

  // Air temperature in degrees Celsius.
  final double? temperatureC;

  // Relative humidity as a percentage.
  final double? humidityPercent;

  // Volumetric soil water content of the top 1cm, in m3/m3.
  final double? soilMoisture;

  factory FieldConditions.fromOpenMeteo(Map<String, dynamic> json) {
    final current = json['current'];
    if (current is! Map<String, dynamic>) return const FieldConditions();

    return FieldConditions(
      temperatureC: _toDouble(current['temperature_2m']),
      humidityPercent: _toDouble(current['relative_humidity_2m']),
      soilMoisture: _toDouble(current['soil_moisture_0_to_1cm']),
    );
  }

  // Open-Meteo returns numbers, but a missing variable comes back as null.
  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String get temperatureLabel =>
      temperatureC == null ? '--' : '${temperatureC!.round()}°C';

  String get humidityLabel =>
      humidityPercent == null ? '--' : '${humidityPercent!.round()}%';

  // Volumetric water content mapped to plain words for the dashboard.
  // Wilting point sits near 0.10 and field capacity near 0.35 for most soils.
  String get soilMoistureLabel {
    final value = soilMoisture;
    if (value == null) return '--';
    if (value < 0.10) return 'Dry';
    if (value < 0.20) return 'Low';
    if (value < 0.35) return 'Optimal';
    return 'Wet';
  }
}
