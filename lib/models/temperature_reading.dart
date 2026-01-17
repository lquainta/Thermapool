import 'package:intl/intl.dart';

class TemperatureReading {
  final String deviceId;
  final double temperatureC;
  final double temperatureF;
  final DateTime timestamp;

  TemperatureReading({
    required this.deviceId,
    required this.temperatureC,
    required this.temperatureF,
    required this.timestamp,
  });

  factory TemperatureReading.fromJson(Map<String, dynamic> json) {
    final timestampStr = json['timestamp'] as String?;
    final timestamp = timestampStr != null 
        ? DateTime.parse(timestampStr) 
        : DateTime.now();
    
    return TemperatureReading(
      deviceId: json['device_id'] ?? 'unknown',
      temperatureC: (json['temperature_c'] as num?)?.toDouble() ?? 0.0,
      temperatureF: (json['temperature_f'] as num?)?.toDouble() ?? 0.0,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'temperature_c': temperatureC,
      'temperature_f': temperatureF,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // For backwards compatibility - use Fahrenheit as the base temperature
  double get temperature => temperatureF;

  String getFormattedTime() {
    return DateFormat('MMM d, h:mm a').format(timestamp.toLocal());
  }

  String getFormattedDateTime() {
    final now = DateTime.now();
    final localTime = timestamp.toLocal();
    final difference = now.difference(localTime);
    
    if (difference.inDays == 0) {
      return 'Today at ${DateFormat('h:mm a').format(localTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('h:mm a').format(localTime)}';
    } else {
      return DateFormat('MMM d, yyyy • h:mm a').format(localTime);
    }
  }

  DateTime get dateTime => timestamp;
}