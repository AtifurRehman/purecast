import 'package:purecast/purecast.dart';
import 'package:mime/mime.dart';

class CastMedia {
  String url;
  CastMediaMetadata metadata;
  bool autoPlay = true;
  double position;
  double? playbackRate;
  String? contentType;
  double? duration;
  Map<String, dynamic>? customData;
  CastMediaTextTrackStyle? textTrackStyle;
  List<CastMediaTrack>? tracks;
  List<int>? activeTrackIds;
  CastStreamType streamType;

  /// Creates the [CastMedia] media that will be sent to the [CastDevice].
  ///
  /// * [url] - The URL String of any mp4, webm, mp3 or jpg media file.
  /// * [metadata] - The [CastMediaMetadata] metadata of the contentId.
  /// * [contentType] - Optional. The MIME type of the media. If null, it will be automatically determined based on the [url].
  /// * [autoPlay] - If the content should start playing automatically.
  /// * [position] - The position in seconds where the content should start playing.
  /// * [streamType] - The [CastStreamType] stream type of the content.
  /// * [duration] - The duration of the content in seconds.
  /// * [customData] - Optional. Custom data.
  /// * [playbackRate] - Optional. The playback rate of the content.
  /// * [tracks] - Optional. The list of [CastMediaTrack] tracks of the content.
  /// * [textTrackStyle] - Optional. The [CastMediaTextTrackStyle] style of the text tracks.
  /// * [activeTrackIds] - Optional. The list of active track ids.
  ///
  CastMedia({
    required this.url,
    required this.metadata,
    this.contentType,
    this.duration,
    this.autoPlay = true,
    this.position = 0.0,
    this.customData,
    this.playbackRate,
    this.tracks,
    this.textTrackStyle,
    this.activeTrackIds,
    this.streamType = CastStreamType.BUFFERED,
  }) {
    if (contentType == null) {
      contentType = lookupMimeType(url);
      if (contentType == null) {
        throw Exception('No content type found for $url');
      }
    }
  }

  Map toChromeCastMap() {
    return {
      'type': 'LOAD',
      'autoPlay': autoPlay,
      'currentTime': position,
      'activeTracks': [],
      'media': {
        'contentId': url,
        'contentType': contentType!,
        'streamType': streamType.value,
        if (duration != null) 'duration': duration,
        if (customData != null) 'customData': customData,
        if (playbackRate != null) 'playbackRate': playbackRate,
        if (textTrackStyle != null)
          'textTrackStyle': textTrackStyle!.toChromeCastMap(),
        if (tracks != null)
          'tracks': tracks!.map((e) => e.toChromeCastMap()).toList(),
        if (activeTrackIds != null) 'activeTrackIds': activeTrackIds,
        'metadata': metadata.toChromeCastMap(),
      }
    };
  }
}
