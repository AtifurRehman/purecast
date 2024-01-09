import 'package:purecast/purecast.dart';
import 'package:purecast/src/cast_application.dart';

/// The current ChromeCast device status.
class CastStatus {
  CastVolume? volume;
  List<CastApplication>? applications;
  bool? activeInput;
  bool? standBy;

  /// Creates the [CastStatus] status that represents the current ChromeCast device status.
  CastStatus({
    this.volume,
    this.applications,
    this.activeInput,
    this.standBy,
  });

  factory CastStatus.fromChromeCastMap(Map map) {
    return CastStatus(
      volume: CastVolume.fromChromeCastMap(map['volume']),
      applications: List<CastApplication>.from(
          map['applications'].map((e) => CastApplication.fromChromeCastMap(e))),
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
    return 'CastStatus{volume: $volume, applications: $applications, activeInput: $activeInput, standBy: $standBy}';
  }
}
