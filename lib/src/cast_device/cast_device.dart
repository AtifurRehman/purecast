import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

enum CastDeviceType {
  Unknown,
  ChromeCast,
  AppleTV,
}

enum GoogleCastModelType {
  GoogleHub,
  GoogleHome,
  GoogleMini,
  GoogleMax,
  ChromeCast,
  ChromeCastAudio,
  NonGoogle,
  CastGroup,
}

class CastDevice {
  late final String? name;
  final String? type;
  final String? host;
  final int? port;

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

  late final String? modelName;

  CastDevice._({
    this.type,
    this.host,
    this.port,
    this.attr,
  }) {}

  /// Creates a [CastDevice] that will represent the Cast Device to be connected.
  ///
  /// * [defaultName] - The default name to be used for the device, if the friendly name is not found in the attributes.
  /// * [type] - The type of the device. Default value is '_googlecast._tcp'.
  /// * [host] - The host IP of the device.
  /// * [port] - The port of the device.
  static Future<CastDevice> create({
    String? defaultName,
    String? type = '_googlecast._tcp',
    required String host,
    required int port,
    Map<String, Uint8List>? attr,
  }) async {
    CastDevice device = CastDevice._(
      type: type,
      host: host,
      port: port,
      attr: attr,
    );
    await device.getDeviceInfo(defaultName);
    return device;
  }

  Future<void> getDeviceInfo(String? defaultName) async {
    String? nameToUse;
    String? modelNameToUse;
    if (CastDeviceType.ChromeCast == deviceType) {
      if (null != attr && null != attr!['fn']) {
        nameToUse = utf8.decode(attr!['fn']!);
        if (null != attr!['md']) {
          modelNameToUse = utf8.decode(attr!['md']!);
        }
      } else {
        // Attributes are not guaranteed to be set, if not set fetch them via the eureka_info url
        // Possible parameters: version,audio,name,build_info,detail,device_info,net,wifi,setup,settings,opt_in,opencast,multizone,proxy,night_mode_params,user_eq,room_equalizer
        try {
          bool trustSelfSigned = true;
          HttpClient httpClient = HttpClient()
            ..badCertificateCallback =
                ((X509Certificate cert, String host, int port) =>
                    trustSelfSigned);
          IOClient ioClient = new IOClient(httpClient);
          final uri = Uri.parse(
              'https://$host:8443/setup/eureka_info?params=name,device_info');
          http.Response response = await ioClient.get(uri);
          String body = response.body.toString();
          Map<String, dynamic> eurekaInfo = jsonDecode(body);
          if (eurekaInfo['name'] != null && eurekaInfo['name'] != 'Unknown') {
            nameToUse = eurekaInfo['name'];
          } else if (eurekaInfo['ssid'] != null) {
            nameToUse = eurekaInfo['ssid'];
          }
          Map<String, dynamic> deviceInfo = eurekaInfo['device_info'];
          if (deviceInfo['model_name'] != null) {
            modelNameToUse = deviceInfo['model_name'];
          }
        } catch (exception) {
          log(exception.toString());
        }
      }
    }
    name = nameToUse ?? defaultName;
    modelName = modelNameToUse ?? 'Unknown';
  }

  CastDeviceType get deviceType {
    if (type!.contains('_googlecast._tcp')) {
      return CastDeviceType.ChromeCast;
    } else if (type!.contains('_airplay._tcp')) {
      return CastDeviceType.AppleTV;
    }
    return CastDeviceType.Unknown;
  }

  GoogleCastModelType get googleModelType {
    switch (modelName) {
      case "Google Home":
        return GoogleCastModelType.GoogleHome;
      case "Google Home Hub":
        return GoogleCastModelType.GoogleHub;
      case "Google Home Mini":
        return GoogleCastModelType.GoogleMini;
      case "Google Home Max":
        return GoogleCastModelType.GoogleMax;
      case "Chromecast":
        return GoogleCastModelType.ChromeCast;
      case "Chromecast Audio":
        return GoogleCastModelType.ChromeCastAudio;
      case "Google Cast Group":
        return GoogleCastModelType.CastGroup;
      default:
        return GoogleCastModelType.NonGoogle;
    }
  }
}
