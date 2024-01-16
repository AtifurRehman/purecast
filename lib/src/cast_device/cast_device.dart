import 'dart:convert';
import 'package:universal_io/io.dart';
import 'dart:typed_data';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../utils/constants.dart';

class CastDeviceModel {
  const CastDeviceModel({
    this.name,
    this.googleCastDeviceModel,
    this.airPlayDeviceModel,
  });
  final String? name;
  final GoogleCastDeviceModel? googleCastDeviceModel;
  final AirPlayDeviceModel? airPlayDeviceModel;
  bool get isGoogleCastDevice => googleCastDeviceModel != null;
  bool get isAirPlayDevice => airPlayDeviceModel != null;
}

enum AirPlayDeviceModel {
  AppleTV,
  AirPortExpress,
  AirPlaySpeaker,
  AirPlayReceiver,
  AirPlayTransmitter,
  AirPlayTransceiver,
  AirPlayDevice,
  Unknown;

  static AirPlayDeviceModel fromString(String? modelName) {
    switch (modelName) {
      case "Apple TV":
        return AirPlayDeviceModel.AppleTV;
      case "AirPort Express":
        return AirPlayDeviceModel.AirPortExpress;
      case "AirPlay Speaker":
        return AirPlayDeviceModel.AirPlaySpeaker;
      case "AirPlay Receiver":
        return AirPlayDeviceModel.AirPlayReceiver;
      case "AirPlay Transmitter":
        return AirPlayDeviceModel.AirPlayTransmitter;
      case "AirPlay Transceiver":
        return AirPlayDeviceModel.AirPlayTransceiver;
      case "AirPlay Device":
        return AirPlayDeviceModel.AirPlayDevice;
      default:
        return AirPlayDeviceModel.Unknown;
    }
  }
}

enum GoogleCastDeviceModel {
  GoogleHub,
  GoogleHome,
  GoogleMini,
  GoogleMax,
  ChromeCast,
  ChromeCastAudio,
  CastGroup,
  Unknown;

  static GoogleCastDeviceModel fromString(String? modelName) {
    switch (modelName) {
      case "Google Home":
        return GoogleCastDeviceModel.GoogleHome;
      case "Google Home Hub":
        return GoogleCastDeviceModel.GoogleHub;
      case "Google Home Mini":
        return GoogleCastDeviceModel.GoogleMini;
      case "Google Home Max":
        return GoogleCastDeviceModel.GoogleMax;
      case "Chromecast":
        return GoogleCastDeviceModel.ChromeCast;
      case "Chromecast Audio":
        return GoogleCastDeviceModel.ChromeCastAudio;
      case "Google Cast Group":
        return GoogleCastDeviceModel.CastGroup;
      default:
        return GoogleCastDeviceModel.Unknown;
    }
  }
}

class CastDevice {
  final String name;
  final String host;
  final int port;
  final CastDeviceModel model;

  /// Contains the information about the device.
  /// You can decode with utf8 a bunch of information
  ///
  /// * md - Model Name (e.g. "Chromecast");
  /// * id - UUID without hyphens of the particular device (e.g. xx12x3x456xx789xx01xx234x56789x0);
  /// * fn - Friendly Name of the device (e.g. "Living Room");
  /// * rs - Unknown (recent share???) (e.g. "Youtube TV");
  /// * bs - Unknown (e.g. "XX1XXX2X3456");
  /// * st - Unknown (e.g. "1");
  /// * ca - Unknown (e.g. "1234");
  /// * ic - Icon path (e.g. "/setup/icon.png");
  /// * ve - Version (e.g. "04").
  final Map<String, Uint8List>? attr;

  CastDevice._({
    required this.host,
    required this.port,
    required this.name,
    required this.model,
    this.attr,
  }) {}

  /// Creates a [CastDevice] that will represent the Cast Device to be connected.
  ///
  /// * [defaultName] - The default name to be used for the device, if the friendly name is not found in the attributes.
  /// * [type] - The type of the device. Default value is '_googlecast._tcp'.
  /// * [host] - The host IP of the device.
  /// * [port] - The port of the device.
  static Future<CastDevice> create({
    String defaultName = "No name",
    String type = CastConstants.gcastName,
    required String host,
    required int port,
    Map<String, Uint8List>? attr,
  }) async {
    String? modelName;
    String? nameToUse;
    switch (type) {
      case CastConstants.gcastName:
        if (attr != null) {
          if (null != attr['fn']) {
            nameToUse = utf8.decode(attr['fn']!);
          }
          if (null != attr['md']) {
            modelName = utf8.decode(attr['md']!);
          }
        }
        if (modelName == null || nameToUse == null) {
          Map<String, dynamic>? eurekaInfo = await _getEurekaInfo(host);
          if (eurekaInfo != null) {
            if (eurekaInfo['name'] != null && eurekaInfo['name'] != 'Unknown') {
              nameToUse = eurekaInfo['name'] as String;
            } else if (eurekaInfo['ssid'] != null) {
              nameToUse = eurekaInfo['ssid'] as String;
            }
            Map<String, dynamic> deviceInfo = eurekaInfo['device_info'];
            if (deviceInfo['model_name'] != null) {
              modelName = deviceInfo['model_name'];
            }
          }
        }
        return CastDevice._(
          host: host,
          port: port,
          name: nameToUse ?? defaultName,
          model: CastDeviceModel(
              name: modelName,
              googleCastDeviceModel:
                  GoogleCastDeviceModel.fromString(modelName)),
          attr: attr,
        );
      case CastConstants.airplayName:
        nameToUse = 'Unknown';
        throw Exception('Unknown type');
      default:
        throw Exception('Unknown type');
    }
  }

  static Future<Map<String, dynamic>?> _getEurekaInfo(String host) async {
    try {
      bool trustSelfSigned = true;
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => trustSelfSigned);
      IOClient ioClient = new IOClient(httpClient);
      final uri = Uri.parse(
          'https://$host:8443/setup/eureka_info?params=name,device_info');
      http.Response response = await ioClient.get(uri);
      String body = response.body.toString();
      return jsonDecode(body);
    } catch (exception) {
      log(exception.toString());
      return null;
    }
  }
}
