import 'package:mime/mime.dart';

class CastMediaMetadata {
  late int _metadataType;
  String title;
  List<Uri>? images;

  /// Creates the [CastMediaMetadata] representing the metadata of a [CastMedia].
  /// Will be used while the [CastMedia] is loading.
  ///
  /// * [title] - The title of the [CastMedia].
  /// * [images] - The list of images/thumbnails of the [CastMedia].
  ///
  CastMediaMetadata({required this.title, this.images}) {
    _metadataType = 0;
    if (null == images) {
      _metadataType = 3;
    } else {
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
    List<Map>? imagesMap;
    if (images != null) {
      imagesMap = [];
      images!.forEach((element) {
        imagesMap!.add({'url': element.toString()});
      });
    }
    return {
      'metadataType': _metadataType,
      'title': title,
      if (imagesMap != null) 'images': imagesMap,
    };
  }
}
