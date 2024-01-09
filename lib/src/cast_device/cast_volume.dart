enum CastVolumeControlType {
  FIXED('FIXED'),
  ATTENUATION('ATTENUATION'),
  MASTER('MASTER');

  /// Describes types of volume control.
  const CastVolumeControlType(this.value);
  static CastVolumeControlType fromValue(String value) {
    switch (value) {
      case 'FIXED':
        return CastVolumeControlType.FIXED;
      case 'ATTENUATION':
        return CastVolumeControlType.ATTENUATION;
      case 'MASTER':
        return CastVolumeControlType.MASTER;
      default:
        return CastVolumeControlType.ATTENUATION;
    }
  }

  final String value;
}

class CastVolume {
  static const double _defaultIncrement = 0.05;
  double level;
  bool muted;
  double increment;
  double stepInterval;
  CastVolumeControlType controlType;
  CastVolume({
    this.level = -1,
    this.muted = false,
    this.increment = _defaultIncrement,
    this.stepInterval = _defaultIncrement,
    this.controlType = CastVolumeControlType.ATTENUATION,
  });

  Map toChromeCastMap() {
    return {
      'level': level,
      'muted': muted,
      'increment': increment,
      'stepInterval': stepInterval,
      'controlType': controlType.value,
    };
  }

  static CastVolume fromChromeCastMap(dynamic map) {
    return CastVolume(
      level: map['level'],
      muted: map['muted'],
      increment: map['increment'],
      stepInterval: map['stepInterval'],
      controlType: CastVolumeControlType.fromValue(map['controlType']),
    );
  }
}
