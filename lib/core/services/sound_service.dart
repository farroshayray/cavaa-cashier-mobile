import 'package:audioplayers/audioplayers.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playNotification() async {
    try {
      await _player.stop(); // hentikan kalau ada suara sebelumnya
      await _player.play(AssetSource('sounds/notify.mp3'));
    } catch (e) {
      // bisa log error kalau perlu
      print('Sound error: $e');
    }
  }
}