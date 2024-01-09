enum CastStreamType {
  buffered('BUFFERED'),
  live('LIVE');

  const CastStreamType(this.value);
  final String value;
}
