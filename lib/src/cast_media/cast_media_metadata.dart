import 'package:mime/mime.dart';

enum CastMediaMetadataType {
  GENERIC,
  MOVIE,
  TV_SHOW,
  MUSIC_TRACK,
  PHOTO,
}

class CastMediaMetadata {
  CastMediaMetadataType type;
  String title;
  String? albumName;
  String? albumArtist;
  String? artist;
  DateTime? releaseDate;
  List<Uri>? images;

  /// Creates the [CastMediaMetadata] representing the metadata of a [CastMedia].
  /// Will be used while the [CastMedia] is loading.
  ///
  /// * [type] - The [CastMediaMetadataType] type of the [CastMedia].
  /// * [title] - The title of the [CastMedia].
  /// * [images] - The list of images/thumbnails of the [CastMedia].
  /// * [albumName] - The album name of the [CastMedia].
  /// * [albumArtist] - The album artist of the [CastMedia].
  /// * [artist] - The artist of the [CastMedia].
  /// * [releaseDate] - The release date of the [CastMedia].
  ///
  CastMediaMetadata(
      {required this.title,
      this.type = CastMediaMetadataType.GENERIC,
      this.images}) {
    if (images != null) {
      images!.forEach((element) {
        String? mimeType = lookupMimeType(element.toString());
        if (mimeType == null) {
          throw Exception('No content type found for $element');
        }
        if (!mimeType.startsWith('image/')) {
          throw Exception('Invalid content type found for $element');
        }
      });
    }
  }
  Map toChromeCastMap() {
    Map metadata = {
      'metadataType': type.index,
      'title': title,
    };
    if (images != null) {
      List<Map>? imagesMap = [];
      images!.forEach((element) {
        imagesMap.add({'url': element.toString()});
      });
      metadata['images'] = imagesMap;
    } else {
      metadata['images'] = [
        {'url': ''}
      ];
    }
    if (releaseDate != null) {
      metadata['releaseDate'] = releaseDate!.toIso8601String();
    }
    if (albumName != null) {
      metadata['albumName'] = albumName;
    }
    if (albumArtist != null) {
      metadata['albumArtist'] = albumArtist;
    }
    if (artist != null) {
      metadata['artist'] = artist;
    }
    return metadata;
  }
}
