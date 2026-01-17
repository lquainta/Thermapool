import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound_service.dart';

class SettingsService extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isCelsius = false;
  int _updateInterval = 1800; // seconds (30 minutes)
  int _averageWindow = 1; // hours - default to 1 hour
  String _apiEndpoint = 'https://us-central1-davepooltemp.cloudfunctions.net/get_pool_data?api_key=JsQH3ZkHTKHZLPhbDiUa11';
  int _dataLimit = 1000; // Increased to get more historical data
  
  final SoundService _soundService = SoundService();

  bool get isDarkMode => _isDarkMode;
  bool get isCelsius => _isCelsius;
  int get updateInterval => _updateInterval;
  int get averageWindow => _averageWindow;
  String get apiEndpoint => _apiEndpoint;
  int get dataLimit => _dataLimit;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _isCelsius = prefs.getBool('isCelsius') ?? false;
    _updateInterval = prefs.getInt('updateInterval') ?? 1800;
    _averageWindow = prefs.getInt('averageWindow') ?? 1;
    _apiEndpoint = prefs.getString('apiEndpoint') ?? 'https://us-central1-davepooltemp.cloudfunctions.net/get_pool_data?api_key=JsQH3ZkHTKHZLPhbDiUa11';
    _dataLimit = prefs.getInt('dataLimit') ?? 1000;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    _soundService.playSetting();
    notifyListeners();
  }

  Future<void> toggleTemperatureUnit() async {
    _isCelsius = !_isCelsius;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCelsius', _isCelsius);
    _soundService.playSetting();
    notifyListeners();
  }

  Future<void> setUpdateInterval(int seconds) async {
    _updateInterval = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('updateInterval', seconds);
    _soundService.playSetting();
    notifyListeners();
  }

  Future<void> setAverageWindow(int hours) async {
    _averageWindow = hours;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('averageWindow', hours);
    _soundService.playSetting();
    notifyListeners();
  }

  Future<void> setApiEndpoint(String endpoint) async {
    _apiEndpoint = endpoint;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiEndpoint', endpoint);
    _soundService.playSetting();
    notifyListeners();
  }

  Future<void> setDataLimit(int limit) async {
    _dataLimit = limit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dataLimit', limit);
    _soundService.playSetting();
    notifyListeners();
  }

  double convertTemperature(double fahrenheit) {
    if (_isCelsius) {
      return (fahrenheit - 32) * 5 / 9;
    }
    return fahrenheit;
  }

  String get temperatureUnit => _isCelsius ? '°C' : '°F';
}