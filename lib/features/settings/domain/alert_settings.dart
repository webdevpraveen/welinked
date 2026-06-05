/// Alert sound settings per user.
/// Stored in Firestore `settings` collection. Persists across reinstalls.
class AlertSettings {
  final bool redSoundEnabled;
  final bool greenSoundEnabled;
  final bool blueSoundEnabled;
  final bool yellowSoundEnabled;

  const AlertSettings({
    this.redSoundEnabled = true,
    this.greenSoundEnabled = true,
    this.blueSoundEnabled = true,
    this.yellowSoundEnabled = true,
  });

  factory AlertSettings.fromMap(Map<String, dynamic> data) {
    return AlertSettings(
      redSoundEnabled: data['redSoundEnabled'] as bool? ?? true,
      greenSoundEnabled: data['greenSoundEnabled'] as bool? ?? true,
      blueSoundEnabled: data['blueSoundEnabled'] as bool? ?? true,
      yellowSoundEnabled: data['yellowSoundEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'redSoundEnabled': redSoundEnabled,
      'greenSoundEnabled': greenSoundEnabled,
      'blueSoundEnabled': blueSoundEnabled,
      'yellowSoundEnabled': yellowSoundEnabled,
    };
  }

  /// Returns the default settings (all sounds enabled).
  factory AlertSettings.defaults() {
    return const AlertSettings();
  }

  AlertSettings copyWith({
    bool? redSoundEnabled,
    bool? greenSoundEnabled,
    bool? blueSoundEnabled,
    bool? yellowSoundEnabled,
  }) {
    return AlertSettings(
      redSoundEnabled: redSoundEnabled ?? this.redSoundEnabled,
      greenSoundEnabled: greenSoundEnabled ?? this.greenSoundEnabled,
      blueSoundEnabled: blueSoundEnabled ?? this.blueSoundEnabled,
      yellowSoundEnabled: yellowSoundEnabled ?? this.yellowSoundEnabled,
    );
  }
}
