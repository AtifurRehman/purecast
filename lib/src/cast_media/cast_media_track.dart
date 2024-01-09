import 'package:purecast/purecast.dart';

enum CastMediaTrackType {
  TEXT('TEXT'),
  AUDIO('AUDIO'),
  VIDEO('VIDEO');

  /// The type of the [CastMediaTrack]. Must be one of the following:
  /// * [CastMediaTrackType.TEXT]
  /// * [CastMediaTrackType.AUDIO]
  /// * [CastMediaTrackType.VIDEO]
  const CastMediaTrackType(this.value);
  final String value;
}

/// WARNING: CEA608, TTML and TTML_MP4 ARE NOT TESTED
enum CastMediaTrackCaptionMimeType {
  CEA608('text/cea608'),
  TTML('application/ttml+xml'),
  VTT('text/vtt'),
  TTML_MP4('unknown');

  /// This represents the MIME type of the track content.
  /// For example, if the track is a VTT file, this will have the value ‘text/vtt’.
  /// This field is needed for out-of-band tracks, so it is usually provided if a trackContentId has also been provided.
  /// If the receiver has a way to identify the content from the trackContentId, this field is recommended but is not mandatory.
  /// The track content type, if provided, must be consistent with the track type.
  const CastMediaTrackCaptionMimeType(this.value);
  final String value;
}

class AudioTrackInfo {
  String? audioCodec; // The codec of the audio track.
  int? numAudioChannels; // The number of audio track channels.
  bool? spatialAudio; // True if the track content has spatial audio.

  /// Creates an [AudioTrackInfo] that will be sent with the [CastMediaTrack], if the track is an audio track.
  /// * [audioCodec] - The codec of the audio track.
  /// * [numAudioChannels] - The number of audio track channels.
  /// * [spatialAudio] - True if the track content has spatial audio.
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
  String trackURL;
  //TODO: Detect automatically the MIME type of the track content
  CastMediaTrackCaptionMimeType? trackContentType;

  /// * [trackId] - The unique identifier of the track.
  /// * [type] - The [CastMediaTrackType] type of the track.
  /// * [audioTrackInfo] - Optional. The [AudioTrackInfo] of the track, if the track is an audio track.
  /// * [customData] - Optional. Custom data of the track.
  /// * [isInband] - Optional. Indicates that the track is in-band and not a side-loaded track. Relevant only for text tracks.
  /// * [language] - Optional. The [RFC5646_Language] language of the track. If the track subtype is SUBTITLES, this field is mandatory.
  /// * [name] - Optional. A human-readable name of the track.
  /// * [roles] - Optional. The role(s) of the track. Value explanations described in ISO/IEC 23009-1, labeled "DASH role scheme"
  /// * [subtype] - Optional. For text tracks, the type of the text track.
  /// * [trackURL] - The URL of the track or any other identifier that allows the receiver to find the content.
  /// * [trackContentType] - Optional. The [CastMediaTrackCaptionMimeType] MIME type of the track content.
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
    //TODO: See possible values in https://developers.google.com/cast/docs/reference/web_receiver/cast.framework.messages.Track
    this.subtype = 'SUBTITLES',
    required this.trackURL,
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
      'trackContentId': trackURL,
      if (audioTrackInfo != null)
        'audioTrackInfo': audioTrackInfo!.toChromeCastMap(),
      if (trackContentType != null) 'trackContentType': trackContentType!.value,
      if (customData != null) 'customData': customData,
      if (isInband != null) 'isInband': isInband,
      if (language != null) 'language': language!.code,
      'name': name,
      if (roles != null) 'roles': roles,
      'subtype': subtype,
      if (customData != null) 'customData': customData,
    };
  }
}
