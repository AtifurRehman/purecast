import 'package:purecast/purecast.dart';
import 'package:mime/mime.dart';

class CastMedia {
  /// URL String of any mp4, webm, mp3 or jpg.
  String contentId;
  CastMediaMetadata metadata;
  bool autoPlay = true;
  double position;
  //contentType related to the contentId.
  String? contentType;
  CastStreamType streamType;

  /// Creates the [CastMedia] that will be sent to the chromecast.
  ///
  /// * [contentId] - The URL String of any mp4, webm, mp3 or jpg file.
  /// * [metadata] - The [CastMediaMetadata] metadata of the contentId.
  /// * [contentType] - Optional. The MIME type of the media. If null, it will be automatically determined based on the [contentId].
  /// * [autoPlay] - If the content should start playing automatically.
  /// * [position] - The position in seconds where the content should start playing.
  /// * [streamType] - The stream type of the content.
  ///
  CastMedia({
    required this.contentId,
    required this.metadata,
    this.contentType,
    this.autoPlay = true,
    this.position = 0.0,
    this.streamType = CastStreamType.buffered,
  }) {
    if (contentType == null) {
      contentType = lookupMimeType(contentId);
      if (contentType == null) {
        throw Exception('No content type found for $contentId');
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
        'contentId': contentId,
        'contentType': contentType!,
        'streamType': streamType.value,
        'metadata': metadata.toChromeCastMap(),
      }
    };
  }
}
