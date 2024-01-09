class CastDeviceApplicationNamespace {
  String name;
  CastDeviceApplicationNamespace({
    required this.name,
  });
}

enum CastDeviceApplicationType {
  WEB('WEB'),
  ANDROID_TV('ANDROID_TV');

  /// Defines the text track edge (border) type.
  const CastDeviceApplicationType(this.value);
  static CastDeviceApplicationType fromValue(String value) {
    switch (value) {
      case 'WEB':
        return WEB;
      case 'ANDROID_TV':
        return ANDROID_TV;
      default:
        return WEB;
    }
  }

  final String value;
}

class CastDeviceApplication {
  String appId;
  CastDeviceApplicationType appType;
  String iconUrl;
  String displayName;
  String? sessionId;
  String statusText;
  String? transportId;
  bool isIdleScreen;
  bool launchedFromCloud;
  String? universalAppId;
  List<CastDeviceApplicationNamespace>? namespaces;
  CastDeviceApplication({
    required this.appId,
    required this.appType,
    required this.iconUrl,
    required this.displayName,
    this.sessionId,
    required this.statusText,
    this.transportId,
    this.universalAppId,
    this.isIdleScreen = false,
    this.launchedFromCloud = false,
    this.namespaces,
  });

  Map toChromeCastMap() {
    return {
      'appId': appId,
      'appType': appType.value,
      'displayName': displayName,
      'iconUrl': iconUrl,
      'isIdleScreen': isIdleScreen,
      'launchedFromCloud': launchedFromCloud,
      'namespaces': namespaces?.map((e) => e.name).toList(),
      if (sessionId != null) 'sessionId': sessionId,
      'statusText': statusText,
      if (transportId != null) 'transportId': transportId,
      if (universalAppId != null) 'universalAppId': universalAppId,
    };
  }

  static CastDeviceApplication fromChromeCastMap(dynamic map) {
    return CastDeviceApplication(
      appId: map['appId'],
      appType: CastDeviceApplicationType.fromValue(map['appType'] as String),
      displayName: map['displayName'],
      iconUrl: map['iconUrl'],
      isIdleScreen: map['isIdleScreen'],
      launchedFromCloud: map['launchedFromCloud'],
      namespaces: map['namespaces'] != null
          ? List<CastDeviceApplicationNamespace>.from(map['namespaces']
              .map((e) => CastDeviceApplicationNamespace(name: e)))
          : null,
      sessionId: map['sessionId'],
      statusText: map['statusText'],
      transportId: map['transportId'],
      universalAppId: map['universalAppId'],
    );
  }
}
