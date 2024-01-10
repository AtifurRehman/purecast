import 'package:purecast/purecast.dart';

class CastSession {
  String? sourceId;
  String? destinationId;
  CastMediaStatus? castMediaStatus;
  CastDeviceStatus? castDeviceStatus;
  bool isConnected;

  CastSession(
      {this.sourceId,
      this.destinationId,
      this.castDeviceStatus,
      this.isConnected = false});

  // create from chromecast map
  void mergeWithChromeCastSessionMap({
    String? sourceId,
    String? transportId,
    String? sessionId,
  }) {
    this.isConnected = true;
    this.sourceId = sourceId ?? this.sourceId;
    this.destinationId = transportId ?? sessionId;
  }

  Map<String, String?> toMap() {
    return {
      'sourceId': sourceId,
      'destinationId': destinationId,
    };
  }
}
