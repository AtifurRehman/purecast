import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:developer';

import 'package:purecast/purecast.dart';
import 'package:purecast/src/cast_channel/connection_channel.dart';
import 'package:purecast/src/cast_channel/heartbeat_channel.dart';
import 'package:purecast/src/cast_channel/media_channel.dart';
import 'package:purecast/src/cast_channel/receiver_channel.dart';
import 'package:purecast/proto/cast_channel.pb.dart';

class CastSender extends Object {
  final CastDevice device;

  SecureSocket? _socket;

  ConnectionChannel? _connectionChannel;
  HeartbeatChannel? _heartbeatChannel;
  ReceiverChannel? _receiverChannel;
  MediaChannel? _mediaChannel;

  late bool connectionDidClose;

//  Timer _heartbeatTimer;
  Timer? _mediaCurrentTimeTimer;

  CastSession? _castSession;
  late StreamController<CastSession?> castSessionController;
  late StreamController<CastMediaStatus?> castMediaStatusController;
  late List<CastMedia> _contentQueue;
  CastMedia? _currentCastMedia;

  CastSender(this.device) {
    // TODO: _airplay._tcp
    _contentQueue = [];

    castSessionController = StreamController.broadcast();
    castMediaStatusController = StreamController.broadcast();
  }

  Future<bool> connect() async {
    connectionDidClose = false;

    if (null == _castSession) {
      _castSession = CastSession(
          sourceId: 'client-${math.Random().nextInt(99999)}',
          destinationId: 'receiver-0');
    }

    // connect to socket
    if (null == await _createSocket()) {
      log('Could not create socket');
      return false;
    }

    _connectionChannel!.sendMessage({'type': 'CONNECT'});

    _startHeartbeatPingPong();

    // start status tick
    // TODO: only start receiver status tick when there are subscriptions to it
    // _receiverStatusTick();

    return true;
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
    _mediaChannel!.sendMessage({'type': 'GET_STATUS'});

    // now wait for the media to actually get a status?
    bool didReconnect = await _waitForMediaStatus();
    if (didReconnect) {
      log('reconnecting successful!');
      try {
        castSessionController.add(_castSession);
      } catch (e) {
        log("Could not add the CastSession to the CastSession Stream Controller: events will not be triggered");
        log(e.toString());
        log("Closed? ${castSessionController.isClosed}");
      }

      try {
        castMediaStatusController.add(_castSession!.castMediaStatus);
      } catch (e) {
        log("Could not add the CastMediaStatus to the CastSession Stream Controller: events will not be triggered");
        log(e.toString());
        log("Closed? ${castMediaStatusController.isClosed}");
      }
    }
    return didReconnect;
  }

  Future<bool> disconnect() async {
    if (null != _connectionChannel && null != _castSession?.castMediaStatus) {
      _connectionChannel!.sendMessage({
        'type': 'CLOSE',
        'sessionId': _castSession!.castMediaStatus!.sessionId,
      });
    }

    _socket?.destroy();
    _dispose();
    connectionDidClose = true;
    return true;
  }

  void launch({String? appId}) {
    _castReceiverAction('LAUNCH', {
      'appId': appId ?? 'CC1AD845',
    });
  }

  //TODO: Actually test this
  /// ChromeCast does not allow you to jump levels too quickly to avoid blowing speakers.
  /// This method will increase/decrease the volume by the increment amount until it reaches the
  /// desired level.
  Future<void> setVolumeByIncrement(double level) async {
    if (_castSession?.castMediaStatus != null) {
      CastVolume? v = _castSession?.castMediaStatus?.volume;
      if (v == null) {
        return;
      }
      if (v.increment <= 0) {
        return;
      }
      // With floating points we always have minor decimal variations, using the Math.min/max
      // works around this issue

      // Increase volume
      if (level > v.level) {
        while (v!.level < level) {
          v = _castSession?.castMediaStatus?.volume;
          if (v == null) {
            await _waitForMediaStatus();
            if (_castSession?.castMediaStatus == null) {
              return;
            }
            v = _castSession?.castMediaStatus?.volume;
            if (v == null) {
              return;
            }
          }
          v.level = math.min(v.level + v.increment, level);
          _castReceiverAction('SET_VOLUME', v.toChromeCastMap());
        }
        // Decrease Volume
      } else if (level < v.level) {
        while (v!.level > level) {
          v = _castSession?.castMediaStatus?.volume;
          if (v == null) {
            await _waitForMediaStatus();
            if (_castSession?.castMediaStatus == null) {
              return;
            }
            v = _castSession?.castMediaStatus?.volume;
            if (v == null) {
              return;
            }
          }
          v.level = math.max(v.level - v.increment, level);
          _castReceiverAction('SET_VOLUME', v.toChromeCastMap());
        }
      }
    }
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

  void _castMediaAction(type, [params]) {
    if (null == params) params = {};
    if (null != _mediaChannel && null != _castSession?.castMediaStatus) {
      _mediaChannel!.sendMessage(params
        ..addAll({
          'mediaSessionId': _castSession!.castMediaStatus!.sessionId,
          'type': type,
        }));
    }
  }

  void _castReceiverAction(type, [params]) {
    if (null == params) params = {};
    if (null != _receiverChannel) {
      _receiverChannel!.sendMessage(params
        ..addAll({
          'type': type,
        }));
    }
  }

  void play() {
    _castMediaAction('PLAY');
    log('PLAY');
  }

  void pause() {
    _castMediaAction('PAUSE');
    log('PAUSE');
  }

  void togglePause() {
    log("TOGGLE_PAUSE");
    log(_castSession?.castMediaStatus.toString() ?? "null");
    if (true == _castSession?.castMediaStatus?.isPlaying) {
      pause();
    } else if (true == _castSession?.castMediaStatus?.isPaused) {
      play();
    }
  }

  void stop() {
    _castMediaAction('STOP');
  }

  void seek(double time) {
    Map<String, dynamic> map = {'currentTime': time};
    _castMediaAction('SEEK', map);
  }

  //TODO: Actually test this
  void setVolume(double volume) {
    Map<String, dynamic> map = {'volume': math.min(volume, 1)};
    _castMediaAction('VOLUME', map);
  }

  void setPlayBackRate(double rate) {
    Map<String, dynamic> map = {'playbackRate': rate};
    _castMediaAction('SET_PLAYBACK_RATE', map);
  }

  void setTrackId(int trackId) {
    Map<String, dynamic> map = {
      'activeTrackIds': [trackId]
    };
    _castMediaAction('EDIT_TRACKS_INFO', map);
  }

  void clearTrackId() {
    Map<String, dynamic> map = {'activeTrackIds': []};
    _castMediaAction('EDIT_TRACKS_INFO', map);
  }

  CastSession? get castSession => _castSession;

  // private

  Future<SecureSocket?> _createSocket() async {
    if (null == _socket) {
      try {
        log('Connecting to ${device.host}:${device.port}');

        _socket = await SecureSocket.connect(device.host, device.port!,
            onBadCertificate: (X509Certificate certificate) => true,
            timeout: Duration(seconds: 10));

        _connectionChannel = ConnectionChannel.create(_socket,
            sourceId: _castSession!.sourceId,
            destinationId: _castSession!.destinationId);
        _heartbeatChannel = HeartbeatChannel.create(_socket,
            sourceId: _castSession!.sourceId,
            destinationId: _castSession!.destinationId);
        _receiverChannel = ReceiverChannel.create(_socket,
            sourceId: _castSession!.sourceId,
            destinationId: _castSession!.destinationId);

        _socket!.listen(_onSocketData, onDone: _dispose);
      } catch (e) {
        log(e.toString());
        return null;
      }
    }
    return _socket;
  }

  void _onSocketData(List<int> event) {
    List<int> slice = event.getRange(4, event.length).toList();

    CastMessage message = CastMessage.fromBuffer(slice);
    // handle the message
    Map<String, dynamic> payloadMap = jsonDecode(message.payloadUtf8);
    log('Received Socket Data: ${payloadMap.toString()}');
    String type = payloadMap['type'];
    switch (type) {
      case 'PING':
        if (_heartbeatChannel != null)
          _heartbeatChannel!.sendMessage({'type': 'PONG'});
        break;
      case 'CLOSE':
        _dispose();
        connectionDidClose = true;
        break;
      case 'RECEIVER_STATUS':
        _handleReceiverStatus(payloadMap);
        break;
      case 'MEDIA_STATUS':
        _handleMediaStatus(payloadMap);
        break;
      case 'LOAD_FAILED':
        log('Load failed: ${payloadMap.toString()}');
        break;
      case 'LAUNCH_ERROR':
        log('Launch error: ${payloadMap.toString()}');
        break;
      default:
        log('Unknown message type received: $type, ${payloadMap.toString()}');
    }
  }

  void _handleReceiverStatus(Map payload) {
    log(payload.toString());
    if (null == _mediaChannel &&
        true == payload['status']?.containsKey('applications')) {
      _castSession!.castStatus =
          CastDeviceStatus.fromChromeCastMap(payload['status']);
      // re-create the channel with the transportId the chromecast just sent us
      if (false == _castSession?.isConnected) {
        _castSession = _castSession!
          ..mergeWithChromeCastSessionMap(payload['status']['applications'][0]);
        _connectionChannel = ConnectionChannel.create(_socket,
            sourceId: _castSession!.sourceId,
            destinationId: _castSession!.destinationId);
        _connectionChannel!.sendMessage({'type': 'CONNECT'});
        _mediaChannel = MediaChannel.Create(
            socket: _socket,
            sourceId: _castSession!.sourceId,
            destinationId: _castSession!.destinationId);
        _mediaChannel!.sendMessage({'type': 'GET_STATUS'});

        try {
          castSessionController.add(_castSession);
        } catch (e) {
          log("Could not add the CastSession to the CastSession Stream Controller: events will not be triggered");
          log(e.toString());
        }
      }
    }
  }

  Future<bool> _waitForMediaStatus() async {
    while (false == _castSession!.isConnected) {
      await Future.delayed(Duration(milliseconds: 100));
      if (connectionDidClose) return false;
    }
    return _castSession!.isConnected;
  }

  void _handleMediaStatus(Map payload) {
    log('Handle media status: ' + payload.toString());

    if (null != payload['status']) {
      if (!_castSession!.isConnected) {
        _castSession!.isConnected = true;
        _handleContentQueue();
      }

      if (payload['status'].length > 0) {
        _castSession!.castMediaStatus =
            CastMediaStatus.fromChromeCastMap(payload['status'][0]);

        log('Media status ${_castSession!.castMediaStatus.toString()}');

        if (_castSession!.castMediaStatus!.isFinished) {
          _handleContentQueue();
        }

        if (_castSession!.castMediaStatus!.isPlaying) {
          _mediaCurrentTimeTimer =
              Timer(Duration(seconds: 1), _getMediaCurrentTime);
        } else if (_castSession!.castMediaStatus!.isPaused &&
            null != _mediaCurrentTimeTimer) {
          _mediaCurrentTimeTimer!.cancel();
          _mediaCurrentTimeTimer = null;
        }

        try {
          castMediaStatusController.add(_castSession!.castMediaStatus);
        } catch (e) {
          log("Could not add the CastMediaStatus to the CastSession Stream Controller: events will not be triggered");
          log(e.toString());
          log("Closed? ${castMediaStatusController.isClosed}");
        }
      } else {
        log("Media status is empty");

        if (null == _currentCastMedia && _contentQueue.isNotEmpty) {
          log("no media is currently being casted, try to cast first in queue");
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
        !_castSession!.castMediaStatus!.isFinished &&
        !forceNext) {
      // don't handle the next in the content queue, because we only want
      // to play the 'next' content if it's not already playing.
      return;
    }
    _currentCastMedia = _contentQueue.elementAt(0);
    if (null != _currentCastMedia) {
      _contentQueue = _contentQueue.getRange(1, _contentQueue.length).toList();
      _mediaChannel!.sendMessage(_currentCastMedia!.toChromeCastMap());
    }
  }

  void _getMediaCurrentTime() {
    if (null != _mediaChannel &&
        true == _castSession?.castMediaStatus?.isPlaying) {
      _mediaChannel!.sendMessage({
        'type': 'GET_STATUS',
      });
    }
  }

  void _startHeartbeatPingPong() {
    if (null != _heartbeatChannel) {
      _heartbeatChannel!.sendMessage({'type': 'PING'});
      Timer(Duration(seconds: 30), _startHeartbeatPingPong);
    }
  }

  void _dispose() {
    castSessionController.close();
    castMediaStatusController.close();
    _socket = null;
    _heartbeatChannel = null;
    _connectionChannel = null;
    _receiverChannel = null;
    _mediaChannel = null;
    _castSession = null;
    _contentQueue = [];
  }
}
