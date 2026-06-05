import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/core/constants/alert_constants.dart';
import 'package:welinked/features/settings/presentation/providers/settings_providers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final Ref _ref;

  AudioService(this._ref);

  Future<void> playAlertAudio(AlertType type) async {
    // Read user settings state
    final settings = _ref.read(alertSettingsProvider).value;
    
    // Check toggle before playing
    bool soundEnabled = true;
    if (settings != null) {
      switch (type) {
        case AlertType.red:
          soundEnabled = settings.redSoundEnabled;
          break;
        case AlertType.green:
          soundEnabled = settings.greenSoundEnabled;
          break;
        case AlertType.blue:
          soundEnabled = settings.blueSoundEnabled;
          break;
        case AlertType.yellow:
          soundEnabled = settings.yellowSoundEnabled;
          break;
      }
    }

    if (!soundEnabled) return;

    try {
      await _player.stop();
      // Assets are loaded from custom asset folders
      await _player.play(AssetSource(type.audioFile));
    } catch (e) {
      // Audio load error handled silently
    }
  }

  Future<void> stopAudio() async {
    try {
      await _player.stop();
    } catch (e) {
      // Audio stop error handled silently
    }
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService(ref);
});
