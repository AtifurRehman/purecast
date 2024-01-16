import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:purecast/purecast.dart';
import 'package:logging/logging.dart';

final Logger log = new Logger('Chromecast CLI');

void main(List<String> arguments) async {
  // Create an argument parser so we can read the cli's arguments and options
  final parser = new ArgParser()
    ..addOption('host', abbr: 'h', defaultsTo: '')
    ..addOption('port', abbr: 'p', defaultsTo: '8009')
    ..addFlag('append', abbr: 'a', defaultsTo: false)
    ..addFlag('debug', abbr: 'd', defaultsTo: false);

  final ArgResults argResults = parser.parse(arguments);

  if (true == argResults['debug']) {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.message}');
    });
  } else {
    Logger.root.level = Level.OFF;
  }
  List<CastMedia> media = [];
  if (!argResults.rest.isEmpty &&
      argResults.rest
          .fold<String>("", (previousValue, element) => previousValue + element)
          .trim()
          .isNotEmpty) {
    media = argResults.rest
        .map((String i) =>
            CastMedia(url: i, metadata: CastMediaMetadata(title: i)))
        .toList();
  }

  if (media.length == 0) {
    media.add(CastMedia(
        url:
            'https://assets.club.ziyou.com.br/ziyou_video_samples/04-03-2022/1646395449399-004aaZiYouaaaRoupagemaaaAquelaaqueatodosaficamasabendoav1amp4.mp4',
        metadata:
            CastMediaMetadata(title: 'MOVIMENTE-SE COM A MÚSICA', images: [
          Uri.https('assets.club.ziyou.com.br',
              '/ziyou-upload-poster-images/04-03-2022/1646394835519-blob.webp')
        ])));
  }

  String host = argResults['host'];
  int? port = int.parse(argResults['port']);
  if ('' == host.trim()) {
    // search!
    print('Looking for ChromeCast devices...');
    PureCast pureCast = PureCast();
    List<CastDevice> devices = [];
    DateTime start = DateTime.now();
    StreamSubscription sub =
        pureCast.scanForDevices().stream.listen((castDevice) {
      print(
          'Found device: ${castDevice.name} at ${castDevice.host}:${castDevice.port} ${castDevice.model.name} ${castDevice.model.isGoogleCastDevice ? 'Google Cast Device' : 'AirPlay Device'} ${castDevice.model.googleCastDeviceModel?.name ?? castDevice.model.airPlayDeviceModel?.name}');
      devices.add(castDevice);
    });
    while (devices.length == 0) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    print("Time taken: ${DateTime.now().difference(start).inSeconds}s");
    sub.cancel();
    print("Found ${devices.length} devices:");

    print("Pick a device (1-${devices.length}):");

    int? choice;

    while (choice == null || choice < 0 || choice > devices.length) {
      choice = int.parse(stdin.readLineSync()!);
      print(
          "Please pick a number (1-${devices.length}) or press return to search again");
    }

    CastDevice pickedDevice = devices[choice - 1];

    print("Connecting to device: ${pickedDevice.name}");

    startCasting(media, pickedDevice, argResults['append']);
  } else {
    print("Connecting to device: $host:$port");
    CastDevice pickedDevice = await CastDevice.create(
        host: host, port: port, type: '_googlecast._tcp');
    startCasting(media, pickedDevice, argResults['append']);
  }
}

void startCasting(
    List<CastMedia> media, CastDevice device, bool? append) async {
  // instantiate the chromecast sender class
  final CastSender castSender = CastSender(
    device,
  );
  castSender.isConnectedStreamController.stream.listen((bool isConnected) {
    log.info('Connection state changed to $isConnected');
  });
  castSender.playerStateStreamController.stream
      .listen((CastMediaPlayerState? state) {
    log.info('Player state changed to ${state?.value}');
  });
  castSender.mediaInfoStreamController.stream.listen((Map? mediaInfo) {
    log.info('Media info changed to ${mediaInfo?.toString()}');
  });
  castSender.positionStreamController.stream.listen((double? position) {
    log.info('Position changed to ${position?.toString()}');
  });
  castSender.volumeStreamController.stream.listen((double? volume) {
    log.info('Volume changed to ${volume?.toString()}');
  });
  print('Connecting to chromecast...');
  bool connected = await castSender.connect();
  if (connected) {
    print('Connected to chromecast!');
    // load CastMedia playlist and send it to the chromecast
    castSender.loadPlaylist(media, append: append);

    // Initiate key press handler
    // space = toggle pause
    // s = stop playing
    // left arrow = seek current playback - 10s
    // right arrow = seek current playback + 10s
    stdin.echoMode = false;
    stdin.lineMode = false;

    stdin.asBroadcastStream().listen((List<int> data) {
      _handleUserInput(castSender, data);
    });
  }
}

void _handleUserInput(CastSender castSender, List<int> data) {
  if (data.length == 0) return;

  int keyCode = data.last;

  if (32 == keyCode) {
    // space = toggle pause
    castSender.togglePause();
  } else if (115 == keyCode) {
    // s == stop
    castSender.stop();
  } else if (27 == keyCode) {
    // escape = disconnect
    castSender.disconnect();
  } else if (67 == keyCode || 68 == keyCode) {
    // left or right = seek 10s back or forth
    double seekBy = 67 == keyCode ? 10.0 : -10.0;
    if (null != castSender.castSession &&
        null != castSender.castSession!.castMediaStatus) {
      castSender.seek(
        max(0.0, castSender.castSession!.castMediaStatus!.position! + seekBy),
      );
    }
  }
}
