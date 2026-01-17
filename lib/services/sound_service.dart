import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playRefresh() async {
    try {
      await _player.play(AssetSource('sounds/refresh.wav'));
    } catch (e) {
      // Silently fail if sound doesn't load
    }
  }

  Future<void> playSetting() async {
    try {
      await _player.play(AssetSource('sounds/setting.wav'));
    } catch (e) {
      // Silently fail if sound doesn't load
    }
  }

  void dispose() {
    _player.dispose();
  }
}