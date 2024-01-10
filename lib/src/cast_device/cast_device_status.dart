import 'package:purecast/src/cast_device/cast_device_application.dart';
import 'package:purecast/src/cast_device/cast_volume.dart';

/// The current ChromeCast device status.
class CastDeviceStatus {
  CastVolume? volume;
  List<CastDeviceApplication>? applications;
  bool? activeInput;
  bool? standBy;

  /// Creates the [CastDeviceStatus] status that represents the current ChromeCast device status.
  CastDeviceStatus({
    this.volume,
    this.applications,
    this.activeInput,
    this.standBy,
  });

  factory CastDeviceStatus.fromChromeCastMap(Map map) {
    return CastDeviceStatus(
      volume: CastVolume.fromChromeCastMap(map['volume']),
      applications: List<CastDeviceApplication>.from(map['applications']
          .map((e) => CastDeviceApplication.fromChromeCastMap(e))),
      activeInput: map['activeInput'],
      standBy: map['standBy'],
    );
  }

  Map toChromeCastMap() {
    return {
      if (volume != null) 'volume': volume!.toChromeCastMap(),
      if (applications != null)
        'applications': applications!.map((e) => e.toChromeCastMap()).toList(),
      if (activeInput != null) 'activeInput': activeInput,
      if (standBy != null) 'standBy': standBy,
    };
  }

  @override
  String toString() {
    return 'CastDeviceStatus{volume: $volume, applications: $applications, activeInput: $activeInput, standBy: $standBy}';
  }
}
