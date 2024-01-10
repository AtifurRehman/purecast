enum CastReceivedMessageType {
  PING('PING'),
  PONG('PONG'),
  RECEIVER_STATUS('RECEIVER_STATUS'),
  GET_APP_AVAILABILITY('GET_APP_AVAILABILITY'),
  INVALID_REQUEST('INVALID_REQUEST'),
  MEDIA_STATUS('MEDIA_STATUS'),
  MULTIZONE_STATUS('MULTIZONE_STATUS'),
  CLOSE('CLOSE'),
  LOAD_FAILED('LOAD_FAILED'),
  LAUNCH_ERROR('LAUNCH_ERROR'),
  DEVICE_ADDED('DEVICE_ADDED'),
  DEVICE_UPDATED('DEVICE_UPDATED'),
  DEVICE_REMOVED('DEVICE_REMOVED'),
  LAUNCH_STATUS('LAUNCH_STATUS'),
  UNKNOWN('UNKNOWN');

  const CastReceivedMessageType(this.value);
  final String value;

  static CastReceivedMessageType fromString(String string) {
    switch (string) {
      case 'PING':
        return CastReceivedMessageType.PING;
      case 'PONG':
        return CastReceivedMessageType.PONG;
      case 'RECEIVER_STATUS':
        return CastReceivedMessageType.RECEIVER_STATUS;
      case 'GET_APP_AVAILABILITY':
        return CastReceivedMessageType.GET_APP_AVAILABILITY;
      case 'INVALID_REQUEST':
        return CastReceivedMessageType.INVALID_REQUEST;
      case 'MEDIA_STATUS':
        return CastReceivedMessageType.MEDIA_STATUS;
      case 'MULTIZONE_STATUS':
        return CastReceivedMessageType.MULTIZONE_STATUS;
      case 'CLOSE':
        return CastReceivedMessageType.CLOSE;
      case 'LOAD_FAILED':
        return CastReceivedMessageType.LOAD_FAILED;
      case 'LAUNCH_ERROR':
        return CastReceivedMessageType.LAUNCH_ERROR;
      case 'DEVICE_ADDED':
        return CastReceivedMessageType.DEVICE_ADDED;
      case 'DEVICE_UPDATED':
        return CastReceivedMessageType.DEVICE_UPDATED;
      case 'DEVICE_REMOVED':
        return CastReceivedMessageType.DEVICE_REMOVED;
      case 'LAUNCH_STATUS':
        return CastReceivedMessageType.LAUNCH_STATUS;
      default:
        return CastReceivedMessageType.UNKNOWN;
    }
  }
}

enum CastSentMessageType {
  PING('PING'),
  PONG('PONG'),
  CONNECT('CONNECT'),
  GET_STATUS('GET_STATUS'),
  GET_APP_AVAILABILITY('GET_APP_AVAILABILITY'),
  LAUNCH('LAUNCH'),
  STOP('STOP'),
  LOAD('LOAD'),
  PLAY('PLAY'),
  PAUSE('PAUSE'),
  SET_VOLUME('SET_VOLUME'),
  SEEK('SEEK'),
  VOLUME('VOLUME'),
  EDIT_TRACKS_INFO('EDIT_TRACKS_INFO'),
  CLOSE('CLOSE'),
  SET_PLAYBACK_RATE('SET_PLAYBACK_RATE');

  const CastSentMessageType(this.value);
  final String value;

  static CastSentMessageType fromString(String string) {
    for (var value in CastSentMessageType.values) {
      if (value.value == string) {
        return value;
      }
    }
    throw Exception('No CastSentMessageType supported for $string');
  }
}
