import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/temperature_reading.dart';
import 'settings_service.dart';
import 'sound_service.dart';

class TemperatureService extends ChangeNotifier {
  TemperatureReading? _currentReading;
  List<TemperatureReading> _history = [];
  bool _isLoading = false;
  String? _error;
  Timer? _updateTimer;
  final SettingsService _settingsService;
  final SoundService _soundService = SoundService();

  TemperatureService(this._settingsService) {
    _loadHistory();
    fetchTemperature();
    _startAutoUpdate();
    _settingsService.addListener(_onSettingsChanged);
  }

  TemperatureReading? get currentReading => _currentReading;
  List<TemperatureReading> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _onSettingsChanged() {
    _startAutoUpdate();
    if (_settingsService.apiEndpoint.isNotEmpty) {
      fetchTemperature();
    }
  }

  void _startAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(
      Duration(seconds: _settingsService.updateInterval),
      (_) => fetchTemperature(),
    );
  }

  Future<void> fetchTemperature({playSound = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final baseUrl = _settingsService.apiEndpoint;
      
      // Validate endpoint before making request
      if (baseUrl.isEmpty) {
        _error = 'API endpoint not configured';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      final separator = baseUrl.contains('?') ? '&' : '?';
      final url = '$baseUrl${separator}limit=${_settingsService.dataLimit}';

      print('Fetching from URL: $url');

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out after 10 seconds');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);

        List<dynamic> data;

        if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse.containsKey('data')) {
            data = jsonResponse['data'] as List<dynamic>;
          } else if (jsonResponse.containsKey('readings')) {
            data = jsonResponse['readings'] as List<dynamic>;
          } else {
            data = [jsonResponse];
          }
        } else if (jsonResponse is List<dynamic>) {
          data = jsonResponse;
        } else {
          _error = 'Unexpected response format';
          _isLoading = false;
          notifyListeners();
          return;
        }

        if (data.isEmpty) {
          _error = 'No data available from server';
        } else {
          final readings = data
              .map((item) => TemperatureReading.fromJson(item))
              .toList();

          readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          _currentReading = readings.first;
          _history = readings;

          // Remove duplicates based on timestamp
          final seenTimestamps = <DateTime>{};
          _history = _history.where((reading) {
            if (seenTimestamps.contains(reading.timestamp)) {
              return false;
            }
            seenTimestamps.add(reading.timestamp);
            return true;
          }).toList();

          // Keep all the data we fetched (up to dataLimit)
          // Only limit to what we actually requested from the API
          if (_history.length > _settingsService.dataLimit) {
            _history = _history.sublist(0, _settingsService.dataLimit);
          }

          await _saveHistory();
          _error = null;
          
          // Play refresh sound on successful data fetch
          if (playSound) {
            _soundService.playRefresh();
          }
        }
      } else if (response.statusCode == 404) {
        _error = 'Server endpoint not found';
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _error = 'Authentication failed - check API key';
      } else if (response.statusCode >= 500) {
        _error = 'Server error - please try again later';
      } else {
        _error = 'Failed to fetch temperature (${response.statusCode})';
      }
    } on TimeoutException catch (_) {
      _error = 'Request timed out - check your connection';
    } on FormatException catch (_) {
      _error = 'Invalid response from server';
    } catch (e) {
      _error = 'Network error: Unable to connect';
      print('Error fetching temperature: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  double getAverageTemperature() {
    if (_history.isEmpty) return 0;

    final now = DateTime.now();
    final windowDuration = Duration(hours: _settingsService.averageWindow);
    final cutoffTime = now.subtract(windowDuration);

    final recentReadings = _history
        .where((reading) => reading.timestamp.isAfter(cutoffTime))
        .toList();

    if (recentReadings.isEmpty) {
      final sum = _history.fold<double>(
          0, (sum, reading) => sum + reading.temperatureF);
      return sum / _history.length;
    }

    final sum = recentReadings.fold<double>(
        0, (sum, reading) => sum + reading.temperatureF);
    return sum / recentReadings.length;
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _history.map((r) => r.toJson()).toList();
    await prefs.setString('temperature_history', json.encode(historyJson));
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString('temperature_history');

    if (historyString != null) {
      try {
        final List<dynamic> historyJson = json.decode(historyString);
        _history = historyJson
            .map((j) => TemperatureReading.fromJson(j))
            .toList();

        _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (_history.isNotEmpty) {
          _currentReading = _history.first;
        }
        notifyListeners();
      } catch (e) {
        await prefs.remove('temperature_history');
      }
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }
}