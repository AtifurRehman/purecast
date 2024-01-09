import 'package:purecast/purecast.dart';

enum CastMediaTrackType {
  TEXT('TEXT'),
  AUDIO('AUDIO'),
  VIDEO('VIDEO');

  const CastMediaTrackType(this.value);
  final String value;
}

/// WARNING: CEA608, TTML and TTML_MP4 ARE NOT TESTED
enum CastMediaTrackCaptionMimeType {
  CEA608('text/cea608'),
  TTML('application/ttml+xml'),
  VTT('text/vtt'),
  TTML_MP4('unknown');

  const CastMediaTrackCaptionMimeType(this.value);
  final String value;
}

class AudioTrackInfo {
  String? audioCodec; // The codec of the audio track.
  int? numAudioChannels; // The number of audio track channels.
  bool? spatialAudio; // True if the track content has spatial audio.

  AudioTrackInfo({
    this.audioCodec,
    this.numAudioChannels,
    this.spatialAudio,
  });

  Map toChromeCastMap() {
    return {
      if (audioCodec != null) 'audioCodec': audioCodec,
      if (numAudioChannels != null) 'numAudioChannels': numAudioChannels,
      if (spatialAudio != null) 'spatialAudio': spatialAudio,
    };
  }
}

class CastMediaTrack {
  final int trackId;
  final CastMediaTrackType type;
  AudioTrackInfo? audioTrackInfo;
  Map<String, dynamic>? customData;
  bool? isInband;
  RFC5646_Language? language;
  String? name;
  /*
  TODO: Implement roles as an enum and add validation
  The role(s) of the track. The following values for each media type are recognized, with value explanations described in ISO/IEC 23009-1, labeled "DASH role scheme":
  VIDEO: caption, subtitle, main, alternate, supplementary, sign, emergency
  AUDIO: main, alternate, supplementary, commentary, dub, emergency
  TEXT: main, alternate, subtitle, supplementary, commentary, dub, description, forced_subtitle
  */
  List<String>? roles;
  String subtype;

  /// The URL of the VTT.
  String trackContentId;
  CastMediaTrackCaptionMimeType trackContentType;

  /// Read: https://github.com/thibauts/node-castv2-client/wiki/How-to-use-subtitles-with-the-DefaultMediaReceiver-app
  CastMediaTrack({
    required this.trackId,
    required this.type,
    this.audioTrackInfo,
    this.customData,
    this.isInband,
    this.language,
    this.name,
    this.roles,
    this.subtype = 'SUBTITLES',
    required this.trackContentId,
    this.trackContentType = CastMediaTrackCaptionMimeType.VTT,
  }) {
    if (type == CastMediaTrackType.AUDIO && audioTrackInfo == null) {
      throw Exception('AudioTrackInfo is required for audio tracks');
    }
    if (this.subtype == 'SUBTITLES' && this.language == null) {
      throw Exception('language is required for subtitle tracks');
    }
  }
  Map toChromeCastMap() {
    return {
      'trackId': trackId,
      'type': type.value,
      'trackContentId': trackContentId,
      if (audioTrackInfo != null)
        'audioTrackInfo': audioTrackInfo!.toChromeCastMap(),
      'trackContentType': trackContentType.value,
      if (customData != null) 'customData': customData,
      if (isInband != null) 'isInband': isInband,
      if (language != null) 'language': language!.code,
      'name': name,
      if (roles != null) 'roles': roles,
      'subtype': subtype,
      if (customData != null) 'customData': customData,
    };
  }

  // Additional methods or logic can be added here.
}
