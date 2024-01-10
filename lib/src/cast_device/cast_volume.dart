enum CastVolumeControlType {
  FIXED('FIXED'),
  ATTENUATION('ATTENUATION'),
  MASTER('MASTER');

  /// Describes types of volume control.
  const CastVolumeControlType(this.value);
  static CastVolumeControlType fromValue(String value) {
    for (CastVolumeControlType type in CastVolumeControlType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return CastVolumeControlType.ATTENUATION;
  }

  final String value;
}

class CastVolume {
  static const double _defaultIncrement = 0.05;
  double level;
  bool muted;
  double stepInterval;
  CastVolumeControlType? controlType;
  CastVolume({
    this.level = -1.0,
    this.muted = false,
    this.stepInterval = _defaultIncrement,
    this.controlType,
  });

  Map toChromeCastMap() {
    return {
      'level': level,
      'muted': muted,
      'stepInterval': stepInterval,
      if (controlType != null) 'controlType': controlType!.value,
    };
  }

  static CastVolume fromChromeCastMap(dynamic map) {
    return CastVolume(
      level: double.tryParse(map['level'].toString()) ?? -1.0,
      muted: map['muted'],
      stepInterval: map['stepInterval'] ?? _defaultIncrement,
      controlType: map['controlType'] != null
          ? CastVolumeControlType.fromValue(map['controlType'])
          : null,
    );
  }
}
