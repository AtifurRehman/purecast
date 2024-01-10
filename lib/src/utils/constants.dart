class CastConstants {
  CastConstants._();
  static const int hostTTL = 120;
  //Fun fact: Mac OS does not allow reuseAddress to be true for loopback addresses apparently.
  //See: https://github.com/dart-lang/sdk/issues/50172
  static const bool reuseAddress = true;
  static const bool reusePort = true;
  static const String gcastName = '_googlecast._tcp.local';
  static const int mdnsDelay = 100;
  static const int maxTicks = 100;
}
