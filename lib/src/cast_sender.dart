import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:collection/collection.dart';

import 'package:purecast/purecast.dart';
import 'package:purecast/src/cast_channel/connection_channel.dart';
import 'package:purecast/src/cast_channel/heartbeat_channel.dart';
import 'package:purecast/src/cast_channel/media_channel.dart';
import 'package:purecast/src/cast_channel/receiver_channel.dart';
import 'package:purecast/proto/cast_channel.pb.dart';
import 'package:purecast/src/cast_messages.dart';

import 'cast_device/cast_device_application.dart';

class CastSender extends Object {
  final CastDevice device;

  SecureSocket? _socket;

  ConnectionChannel? _connectionChannel;
  HeartbeatChannel? _heartbeatChannel;
  ReceiverChannel? _receiverChannel;
  MediaChannel? _mediaChannel;

  bool _connectionDidClose = false;

  //TODO: In the future, try to implement all of the streams like the ones provided by media kit
  late StreamController<bool> isConnectedStreamController;
  late StreamController<CastMediaPlayerState?> playerStateStreamController;
  late StreamController<double?> positionStreamController;
  late StreamController<Map?> mediaInfoStreamController;
  late StreamController<double?> volumeStreamController;

  late StreamController<CastMediaStatus?> _castMediaStatusController;
  late List<CastMedia> _contentQueue;
  CastMedia? _currentCastMedia;
  CastSession? _castSession;

  Timer? _mediaCurrentTimeTimer;

  DateTime? _lastPong, _lastPing;

  CastSender(this.device) {
    _contentQueue = [];
    _castMediaStatusController = StreamController<CastMediaStatus?>.broadcast();

    playerStateStreamController =
        StreamController<CastMediaPlayerState?>.broadcast();
    positionStreamController = StreamController<double?>.broadcast();
    mediaInfoStreamController = StreamController<Map?>.broadcast();
    volumeStreamController = StreamController<double?>.broadcast();
    isConnectedStreamController = StreamController<bool>.broadcast();
  }

  Future<bool> connect() async {
    _connectionDidClose = false;
    try {
      _castSession ??= CastSession(
          sourceId: 'client-${math.Random().nextInt(99999)}',
          destinationId: 'receiver-0');
      await _createSocket().onError((error, stackTrace) {
        print('Socket error: $error');
        print(stackTrace);
        throw Exception('Socket error: $error');
      });
      _connectionChannel!
          .sendMessage({'type': CastSentMessageType.CONNECT.value});
      _startHeartbeatPingPong();
      launch();
      return true;
    } catch (e) {
      print('Connection failed: $e');
      return false;
    }
  }

  Future<bool> reconnect({String? sourceId, String? destinationId}) async {
    _castSession =
        CastSession(sourceId: sourceId, destinationId: destinationId);
    bool connected = await connect();
    if (!connected) {
      return false;
    }
    _mediaChannel = MediaChannel.Create(
        socket: _socket, sourceId: sourceId, destinationId: destinationId);
    _mediaChannel!.sendMessage({'type': CastSentMessageType.GET_STATUS.value});
    CastMediaStatus? oldMediaStatus = _castSession?.castMediaStatus?.copy();
    // now wait for the media to actually get a status?
    bool didReconnect = await _waitForMediaStatus();
    if (didReconnect) {
      print('reconnecting successful!');
      try {
        CastMediaStatus? newMediaStatus = _castSession?.castMediaStatus;
        _castMediaStatusController.add(_castSession!.castMediaStatus);
        _upsertPublicStreams(oldMediaStatus, newMediaStatus, false);
      } catch (e) {
        print(
            "Could not add the CastMediaStatus to the CastSession Stream Controller: events will not be triggered");
        print(e.toString());
        print("Closed? ${_castMediaStatusController.isClosed}");
      }
    }
    return didReconnect;
  }

  void disconnect() {
    _connectionChannel?.sendMessage({
      'type': CastSentMessageType.CLOSE.value,
    });

    //TODO: Validate that this is the correct way to disconnect
    _castReceiverAction(CastSentMessageType.STOP, null);

    _dispose();
  }

  void launch({String? appId}) {
    _castReceiverAction(CastSentMessageType.LAUNCH, {
      'appId': appId ?? 'CC1AD845',
    });
  }

  /// ChromeCast does not allow you to jump levels too quickly to avoid blowing speakers.
  /// This method will increase/decrease the volume by the increment amount until it reaches the
  /// desired level.
  Future<void> setDeviceVolume(double level) async {
    var castMediaStatus = _castSession?.castMediaStatus;
    if (castMediaStatus == null || castMediaStatus.volume == null) return;

    var volume = castMediaStatus.volume!;
    if (volume.stepInterval <= 0) return;

    level = level.clamp(0.0, 1.0);
    while ((level - volume.level).abs() > volume.stepInterval) {
      volume.level = (volume.level +
              (level > volume.level
                  ? volume.stepInterval
                  : -volume.stepInterval))
          .clamp(0.0, 1.0);
      _castReceiverAction(
          CastSentMessageType.SET_VOLUME, volume.toChromeCastMap());
      await _updateVolumeStatus();
    }
  }

  Future<void> _updateVolumeStatus() async {
    _receiverChannel
        ?.sendMessage({'type': CastSentMessageType.GET_STATUS.value});
    await Future.delayed(const Duration(milliseconds: 100));
  }

  void load(CastMedia media, {forceNext = true}) {
    loadPlaylist([media], forceNext: forceNext);
  }

  void loadPlaylist(List<CastMedia> media,
      {append = false, forceNext = false}) {
    if (!append) {
      _contentQueue = media;
    } else {
      _contentQueue.addAll(media);
    }
    if (null != _mediaChannel) {
      _handleContentQueue(forceNext: forceNext || !append);
    }
  }

  void _castMediaAction(CastSentMessageType type, Map? params) {
    if (_receiverChannel == null) return;
    Map<dynamic, dynamic> map = {
      'type': type.value,
    };
    if (castSession?.castMediaStatus?.mediaSessionId != null) {
      map['mediaSessionId'] = castSession!.castMediaStatus!.mediaSessionId;
    }
    if (params != null) {
      map.addAll(params);
    }
    _mediaChannel!.sendMessage(map);
  }

  void _castReceiverAction(CastSentMessageType type, Map? params) {
    if (_receiverChannel == null) return;
    Map<dynamic, dynamic> map = {
      'type': type.value,
    };
    if (params != null) {
      map.addAll(params);
    }
    _receiverChannel!.sendMessage(map);
  }

  void play() {
    _castMediaAction(CastSentMessageType.PLAY, null);
    print('PLAY');
  }

  void pause() {
    _castMediaAction(CastSentMessageType.PAUSE, null);
    print('PAUSE');
  }

  void togglePause() {
    if (_castSession?.castMediaStatus == CastMediaPlayerState.PLAYING) {
      pause();
    } else if (_castSession?.castMediaStatus == CastMediaPlayerState.PAUSED) {
      play();
    }
  }

  void stop() {
    _castMediaAction(CastSentMessageType.STOP, null);
  }

  void seek(double time) {
    Map<String, dynamic> map = {'currentTime': time};
    _castMediaAction(CastSentMessageType.SEEK, map);
  }

  //TODO: Actually test this
  void setVolume(double volume) {
    Map<String, dynamic> map = {'volume': math.min(volume, 1)};
    _castMediaAction(CastSentMessageType.VOLUME, map);
  }

  void setPlayBackRate(double rate) {
    Map<String, dynamic> map = {'playbackRate': rate};
    _castMediaAction(CastSentMessageType.SET_PLAYBACK_RATE, map);
  }

  void setTrackId(int trackId) {
    Map<String, dynamic> map = {
      'activeTrackIds': [trackId]
    };
    _castMediaAction(CastSentMessageType.EDIT_TRACKS_INFO, map);
  }

  void clearTrackId() {
    Map<String, dynamic> map = {'activeTrackIds': []};
    _castMediaAction(CastSentMessageType.EDIT_TRACKS_INFO, map);
  }

  CastSession? get castSession => _castSession;

  // private

  Future<void> _createSocket() async {
    if (_socket != null) return;
    print('Connecting to ${device.host}:${device.port}');
    try {
      _socket = await SecureSocket.connect(
        device.host,
        device.port!,
        onBadCertificate: (X509Certificate certificate) => true,
        timeout: const Duration(seconds: 10),
      );
      print('Connected to ${device.host}:${device.port}');
      _initializeChannels();
      print('Socket initialized');
      _socket!.listen(_onSocketData, onDone: _dispose);
    } catch (e) {
      print('Could not connect to ${device.host}:${device.port}');
      print(e.toString());
      return Future.error(e);
    }
    return;
  }

  void _initializeChannels() {
    if (_castSession == null) throw StateError('CastSession not initialized.');

    _connectionChannel = ConnectionChannel.create(
      _socket!,
      sourceId: _castSession!.sourceId,
      destinationId: _castSession!.destinationId,
    );
    _heartbeatChannel = HeartbeatChannel.create(
      _socket!,
      sourceId: _castSession!.sourceId,
      destinationId: _castSession!.destinationId,
    );
    _receiverChannel = ReceiverChannel.create(
      _socket!,
      sourceId: _castSession!.sourceId,
      destinationId: _castSession!.destinationId,
    );
  }

  void _onSocketData(List<int> event) {
    List<int> slice = event.getRange(4, event.length).toList();

    CastMessage message = CastMessage.fromBuffer(slice);
    // handle the message
    Map<String, dynamic> payloadMap = jsonDecode(message.payloadUtf8);

    print('Received Socket Data: ${payloadMap.toString()}');
    CastReceivedMessageType messageType =
        CastReceivedMessageType.fromString(payloadMap['type'] ?? 'UNKNOWN');
    print('messageType: ${messageType.value}');
    switch (messageType) {
      case CastReceivedMessageType.PING:
        _lastPing = DateTime.now();
        if (_heartbeatChannel != null)
          _heartbeatChannel!
              .sendMessage({'type': CastSentMessageType.PONG.value});
        break;
      case CastReceivedMessageType.PONG:
        _lastPong = DateTime.now();
        break;
      case CastReceivedMessageType.CLOSE:
        _dispose();
        break;
      case CastReceivedMessageType.RECEIVER_STATUS:
        _handleReceiverStatus(payloadMap);
        break;
      case CastReceivedMessageType.MEDIA_STATUS:
        _handleMediaStatus(payloadMap);
        break;
      default:
        print(
            'Unknown message type received: ${messageType.value}, ${payloadMap.toString()}');
    }
  }

  void _handleReceiverStatus(Map payload) {
    print("Receiver status: ${payload.toString()}");
    if (true == payload['status']?.containsKey('applications')) {
      _castSession!.castDeviceStatus =
          CastDeviceStatus.fromChromeCastMap(payload['status']);
      // re-create the channel with the transportId the chromecast just sent us
      if (false == _castSession?.isConnected) {
        CastDeviceApplication? defaultMediaReceiverApp = castSession
                ?.castDeviceStatus?.applications
                ?.firstWhereOrNull((element) =>
                    element.appId ==
                    CastDeviceApplication.defaultMediaReceiverAppId) ??
            castSession?.castDeviceStatus?.applications?.first;
        _castSession!.mergeWithChromeCastSessionMap(
            transportId: defaultMediaReceiverApp?.transportId,
            sessionId: defaultMediaReceiverApp?.sessionId);
        _connectionChannel = ConnectionChannel.create(_socket,
            sourceId: _castSession!.sourceId,
            destinationId: _castSession!.destinationId);
        _connectionChannel!
            .sendMessage({'type': CastSentMessageType.CONNECT.value});
        if (_mediaChannel == null) {
          print('Creating media channel');
          _mediaChannel = MediaChannel.Create(
              socket: _socket,
              sourceId: _castSession!.sourceId,
              destinationId: _castSession!.destinationId);
          _castMediaAction(CastSentMessageType.GET_STATUS, null);
        }
        isConnectedStreamController.add(true);
      }
    }
  }

  Future<bool> _waitForMediaStatus() async {
    while (false == _castSession!.isConnected) {
      await Future.delayed(Duration(milliseconds: 100));
      if (_connectionDidClose) return false;
    }
    return _castSession!.isConnected;
  }

  void _handleMediaStatus(Map payload) {
    print('Handle media status: ' + payload.toString());

    if (null != payload['status']) {
      if (!_castSession!.isConnected) {
        _castSession!.isConnected = true;
        isConnectedStreamController.add(true);
        _handleContentQueue();
      }
      if (payload['status']?.length > 0) {
        CastMediaStatus? oldMediaStatus = _castSession?.castMediaStatus?.copy();
        _castSession!.castMediaStatus =
            CastMediaStatus.fromChromeCastMap(payload['status'][0]);
        CastMediaStatus newMediaStatus = _castSession!.castMediaStatus!;
        _upsertPublicStreams(oldMediaStatus, newMediaStatus, false);
        switch (_castSession!.castMediaStatus!.playerState) {
          case CastMediaPlayerState.PAUSED:
            print('Player state is PAUSED');
            if (_mediaCurrentTimeTimer != null) {
              _mediaCurrentTimeTimer!.cancel();
              _mediaCurrentTimeTimer = null;
            }
            break;
          case CastMediaPlayerState.PLAYING:
            print('Player state is PLAYING');
            _mediaCurrentTimeTimer =
                Timer(Duration(seconds: 1), _getMediaCurrentTime);
            break;
          case CastMediaPlayerState.FINISHED:
            print('Player state is FINISHED');
            _handleContentQueue();
            break;
          default:
            print(
                'Player state is ${_castSession!.castMediaStatus!.playerState!.value}');
            break;
        }

        try {
          _castMediaStatusController.add(_castSession!.castMediaStatus);
        } catch (e) {
          print(
              "Could not add the CastMediaStatus to the CastSession Stream Controller: events will not be triggered");
          print(e.toString());
          print("Closed? ${_castMediaStatusController.isClosed}");
        }
      } else {
        print("Media status is empty");
        if (null == _currentCastMedia && _contentQueue.isNotEmpty) {
          print("No media currently being casted, casting first in queue");
          _handleContentQueue();
        }
      }
    }
  }

  _handleContentQueue({forceNext = false}) {
    if (null == _mediaChannel || _contentQueue.isEmpty) {
      return;
    }
    if (null != _castSession!.castMediaStatus &&
        _castSession!.castMediaStatus != CastMediaPlayerState.FINISHED &&
        !forceNext) {
      // don't handle the next in the content queue, because we only want
      // to play the 'next' content if it's not already playing.
      return;
    }
    _currentCastMedia = _contentQueue.elementAt(0);
    if (null != _currentCastMedia) {
      _contentQueue = _contentQueue.getRange(1, _contentQueue.length).toList();
      Map map = {
        'type': CastSentMessageType.LOAD.value,
      };
      map.addAll(_currentCastMedia!.toChromeCastMap());
      _mediaChannel!.sendMessage(map);
    }
  }

  void _getMediaCurrentTime() {
    if (null != _mediaChannel &&
        _castSession?.castMediaStatus == CastMediaPlayerState.PLAYING) {
      _mediaChannel!.sendMessage({
        'type': CastSentMessageType.GET_STATUS.value,
      });
    }
  }

  Future<void> _startHeartbeatPingPong() async {
    await Future.delayed(const Duration(seconds: 1));
    DateTime now = DateTime.now();
    if (_lastPing != null && _lastPong != null) {
      if (now.difference(_lastPing!).inSeconds > 30 ||
          now.difference(_lastPong!).inSeconds > 30) {
        print('Ping timeout');
        _dispose();
        return;
      }
    }
    _heartbeatChannel?.sendMessage({'type': CastSentMessageType.PING.value});
    await Future.delayed(const Duration(seconds: 15));
    return _startHeartbeatPingPong();
  }

  void _upsertPublicStreams(CastMediaStatus? oldMediaStatus,
      CastMediaStatus? newMediaStatus, bool forceUpdate) {
    if (oldMediaStatus == null && newMediaStatus != null) {
      _setPublicStreams(
          playerState: newMediaStatus.playerState,
          position: newMediaStatus.position,
          mediaInfo: newMediaStatus.media,
          volume: newMediaStatus.volume?.level);
    } else if (oldMediaStatus != null && newMediaStatus != null) {
      if (oldMediaStatus.playerState != newMediaStatus.playerState ||
          forceUpdate) {
        _setPublicStreams(playerState: newMediaStatus.playerState);
      }
      if (oldMediaStatus.position != newMediaStatus.position || forceUpdate) {
        _setPublicStreams(position: newMediaStatus.position);
      }
      if (oldMediaStatus.media != newMediaStatus.media || forceUpdate) {
        _setPublicStreams(mediaInfo: newMediaStatus.media);
      }
      if (oldMediaStatus.volume?.level != newMediaStatus.volume?.level ||
          forceUpdate) {
        _setPublicStreams(volume: newMediaStatus.volume?.level);
      }
    }
  }

  void _setPublicStreams({
    CastMediaPlayerState? playerState,
    double? position,
    Map? mediaInfo,
    double? volume,
  }) {
    if (playerState != null) {
      try {
        playerStateStreamController.add(playerState);
      } catch (e) {
        print(
            "Could not add the CastMediaPlayerState to the CastSession Stream Controller: events will not be triggered");
        print(e.toString());
        print("Closed? ${playerStateStreamController.isClosed}");
      }
    }
    if (position != null) {
      try {
        positionStreamController.add(position);
      } catch (e) {
        print(
            "Could not add the position to the CastSession Stream Controller: events will not be triggered");
        print(e.toString());
        print("Closed? ${positionStreamController.isClosed}");
      }
    }
    if (mediaInfo != null) {
      try {
        mediaInfoStreamController.add(mediaInfo);
      } catch (e) {
        print(
            "Could not add the mediaInfo to the CastSession Stream Controller: events will not be triggered");
        print(e.toString());
        print("Closed? ${mediaInfoStreamController.isClosed}");
      }
    }
    if (volume != null) {
      try {
        volumeStreamController.add(volume);
      } catch (e) {
        print(
            "Could not add the volume to the CastSession Stream Controller: events will not be triggered");
        print(e.toString());
        print("Closed? ${volumeStreamController.isClosed}");
      }
    }
  }

  void _dispose() {
    //isConnectedStreamController.add(false);
    _castMediaStatusController.close();
    playerStateStreamController.close();
    positionStreamController.close();
    mediaInfoStreamController.close();
    volumeStreamController.close();
    _socket?.close();
    _socket?.destroy();
    _clearChannels();
    _castSession = null;
    _contentQueue.clear();
    _mediaCurrentTimeTimer?.cancel();
    _mediaCurrentTimeTimer = null;
    _connectionDidClose = true;
    isConnectedStreamController.close();
  }

  void _clearChannels() {
    _heartbeatChannel = null;
    _connectionChannel = null;
    _receiverChannel = null;
    _mediaChannel = null;
  }
}
