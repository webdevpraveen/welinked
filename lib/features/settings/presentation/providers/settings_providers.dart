import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/features/auth/presentation/providers/auth_providers.dart';
import 'package:welinked/features/settings/data/settings_repository.dart';
import 'package:welinked/features/settings/domain/alert_settings.dart';

/// Stream of current settings
final alertSettingsProvider = StreamProvider<AlertSettings>((ref) {
  final uid = ref.watch(
    currentUserStreamProvider.select((userAsync) => userAsync.value?.uid),
  );
  if (uid == null) {
    return Stream.value(AlertSettings.defaults());
  }
  return ref.watch(settingsRepositoryProvider).watchSettings(uid);
});

class SettingsController {
  final SettingsRepository _repository;
  final Ref _ref;

  SettingsController(this._repository, this._ref);

  Future<void> updateSoundSetting(String settingKey, bool value) async {
    final user = _ref.read(currentUserStreamProvider).value;
    if (user == null) return;

    final currentSettings = _ref.read(alertSettingsProvider).value ?? AlertSettings.defaults();

    AlertSettings updated;
    switch (settingKey) {
      case 'red':
        updated = currentSettings.copyWith(redSoundEnabled: value);
        break;
      case 'green':
        updated = currentSettings.copyWith(greenSoundEnabled: value);
        break;
      case 'blue':
        updated = currentSettings.copyWith(blueSoundEnabled: value);
        break;
      case 'yellow':
        updated = currentSettings.copyWith(yellowSoundEnabled: value);
        break;
      default:
        return;
    }

    await _repository.updateSettings(user.uid, updated);
  }
}

final settingsControllerProvider = Provider<SettingsController>((ref) {
  return SettingsController(ref.read(settingsRepositoryProvider), ref);
});
