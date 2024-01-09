class CastApplicationNamespace {
  String name;
  CastApplicationNamespace({
    required this.name,
  });
}

enum CastApplicationType {
  WEB('WEB'),
  ANDROID_TV('ANDROID_TV');

  /// Defines the text track edge (border) type.
  const CastApplicationType(this.value);
  static CastApplicationType fromValue(String value) {
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

class CastApplication {
  String appId;
  CastApplicationType appType;
  String iconUrl;
  String displayName;
  String? sessionId;
  String statusText;
  String? transportId;
  bool isIdleScreen;
  bool launchedFromCloud;
  String? universalAppId;
  List<CastApplicationNamespace>? namespaces;
  CastApplication({
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

  static CastApplication fromChromeCastMap(dynamic map) {
    return CastApplication(
      appId: map['appId'],
      appType: CastApplicationType.fromValue(map['appType'] as String),
      displayName: map['displayName'],
      iconUrl: map['iconUrl'],
      isIdleScreen: map['isIdleScreen'],
      launchedFromCloud: map['launchedFromCloud'],
      namespaces: map['namespaces'] != null
          ? List<CastApplicationNamespace>.from(
              map['namespaces'].map((e) => CastApplicationNamespace(name: e)))
          : null,
      sessionId: map['sessionId'],
      statusText: map['statusText'],
      transportId: map['transportId'],
      universalAppId: map['universalAppId'],
    );
  }
}
