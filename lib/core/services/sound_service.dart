import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  DateTime? _lastPlayedAt;
  Future<void>? _playInFlight;

  Future<void> playNotification() async {
    final now = DateTime.now();
    if (_lastPlayedAt != null &&
        now.difference(_lastPlayedAt!) < const Duration(milliseconds: 900)) {
      return;
    }

    if (_playInFlight != null) {
      return _playInFlight;
    }

    _playInFlight = _playNotificationInternal().whenComplete(() {
      _playInFlight = null;
    });

    return _playInFlight;
  }

  Future<void> _playNotificationInternal() async {
    try {
      _lastPlayedAt = DateTime.now();
      await _player.stop();
      await _player.play(AssetSource('sounds/notify.mp3'));
    } catch (e) {
      debugPrint('Sound error: $e');
    }
  }
}