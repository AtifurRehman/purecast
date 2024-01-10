import 'package:purecast/src/cast_device/cast_volume.dart';

enum CastMediaPlayerState {
  /// The player is in the IDLE state.
  IDLE('IDLE'),

  /// The player is in the PLAYING state.
  PLAYING('PLAYING'),

  /// The player is in the PAUSED state.
  PAUSED('PAUSED'),

  /// The player is in the BUFFERING state.
  BUFFERING('BUFFERING'),

  /// The player is in the LOADING state.
  LOADING('LOADING'),

  /// The player is in the FINISHED state.
  FINISHED('FINISHED'),

  /// The player is in the CANCELLED state.
  CANCELLED('CANCELLED'),

  /// The player is in the ERROR state.
  ERROR('ERROR');

  const CastMediaPlayerState(this.value);
  final String value;

  static CastMediaPlayerState? fromString(String? value, String? idleReason) {
    if (value == null) return null;
    switch (value) {
      case 'PLAYING':
        return CastMediaPlayerState.PLAYING;
      case 'PAUSED':
        return CastMediaPlayerState.PAUSED;
      case 'BUFFERING':
        return CastMediaPlayerState.BUFFERING;
      case 'LOADING':
        return CastMediaPlayerState.LOADING;
      case 'IDLE':
        if (idleReason == 'FINISHED') {
          return CastMediaPlayerState.FINISHED;
        }
        if (idleReason == 'CANCELLED') {
          return CastMediaPlayerState.CANCELLED;
        }
        if (idleReason == 'ERROR') {
          return CastMediaPlayerState.ERROR;
        }
        return CastMediaPlayerState.IDLE;
      default:
        return CastMediaPlayerState.ERROR;
    }
  }
}

/// The current ChromeCast media status.
class CastMediaStatus {
  late final dynamic mediaSessionId;
  late final CastMediaPlayerState? playerState;
  late final CastVolume? volume;
  late final double? position;
  late final Map? media;

  CastMediaStatus.fromChromeCastMap(Map mediaStatus) {
    playerState = CastMediaPlayerState.fromString(
        mediaStatus['playerState'], mediaStatus['idleReason']);
    volume = mediaStatus['volume'] != null
        ? CastVolume.fromChromeCastMap(mediaStatus['volume'])
        : null;
    position = mediaStatus['currentTime']?.toDouble();
    media = mediaStatus['media'];
    mediaSessionId = mediaStatus['mediaSessionId'];
  }

  CastMediaStatus copy() {
    return CastMediaStatus.fromChromeCastMap({
      'playerState': this.playerState?.value,
      'volume': CastVolume.fromChromeCastMap({
        'level': this.volume?.level,
        'muted': this.volume?.muted,
        'stepInterval': this.volume?.stepInterval,
        'controlType': this.volume?.controlType?.value,
      }).toChromeCastMap(),
      'currentTime': this.position,
      'media': this.media,
      'mediaSessionId': this.mediaSessionId,
    });
  }

  @override
  String toString() {
    return 'CastMediaStatus{playerState: $playerState, volume: $volume, position: $position, media: $media, mediaSessionId: $mediaSessionId}';
  }
}
