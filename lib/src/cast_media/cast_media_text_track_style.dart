enum TextTrackEdgeType {
  NONE('NONE'),
  OUTLINE('OUTLINE'),
  DROP_SHADOW('DROP_SHADOW'),
  RAISED('RAISED'),
  DEPRESSED('DEPRESSED');

  const TextTrackEdgeType(this.value);
  final String value;
}

enum TextTrackFontGenericFamily {
  SANS_SERIF('SANS_SERIF'),
  MONOSPACED_SANS_SERIF('MONOSPACED_SANS_SERIF'),
  SERIF('SERIF'),
  MONOSPACED_SERIF('MONOSPACED_SERIF'),
  CASUAL('CASUAL'),
  CURSIVE('CURSIVE'),
  SMALL_CAPITALS('SMALL_CAPITALS');

  const TextTrackFontGenericFamily(this.value);
  final String value;
}

enum TextTrackFontStyle {
  NORMAL('NORMAL'),
  BOLD('BOLD'),
  BOLD_ITALIC('BOLD_ITALIC'),
  ITALIC('ITALIC');

  const TextTrackFontStyle(this.value);
  final String value;
}

enum TextTrackWindowType {
  NONE('NONE'),
  NORMAL('NORMAL'),
  ROUNDED_CORNERS('ROUNDED_CORNERS');

  const TextTrackWindowType(this.value);
  final String value;
}

class CastMediaTextTrackStyle {
  //TODO: Create a Color class to handle this, or use a dart existing one
  String? backgroundColor; // 32-bit RGBA color, represented as #RRGGBBAA
  Map<String, dynamic>? customData;
  String? edgeColor; // RGBA color for the edge
  TextTrackEdgeType? edgeType; // Edge type
  String? fontFamily; // Font family
  TextTrackFontGenericFamily? fontGenericFamily; // Generic family of the font
  double? fontScale; // Font-scaling factor, default is 1
  TextTrackFontStyle? fontStyle; // Font style
  String?
      foregroundColor; // Foreground 32-bit RGBA color, represented as #RRGGBBAA
  String?
      windowColor; // 32-bit RGBA color for the window, represented as #RRGGBBAA
  double?
      windowRoundedCornerRadius; // Absolute radius of the rounded corners of the window, in pixels
  TextTrackWindowType? windowType; // Window type

  /// Read: https://github.com/thibauts/node-castv2-client/wiki/How-to-use-subtitles-with-the-DefaultMediaReceiver-app
  CastMediaTextTrackStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.customData,
    this.edgeColor,
    this.edgeType,
    this.fontFamily,
    this.fontGenericFamily,
    this.fontScale,
    this.fontStyle,
    this.windowColor,
    this.windowRoundedCornerRadius,
    this.windowType,
  });

  Map toChromeCastMap() {
    return {
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (foregroundColor != null) 'foregroundColor': foregroundColor,
      if (customData != null) 'customData': customData,
      if (edgeColor != null) 'edgeColor': edgeColor,
      if (edgeType != null) 'edgeType': edgeType!.value,
      if (fontFamily != null) 'fontFamily': fontFamily,
      if (fontGenericFamily != null)
        'fontGenericFamily': fontGenericFamily!.value,
      if (fontScale != null) 'fontScale': fontScale,
      if (fontStyle != null) 'fontStyle': fontStyle!.value,
      if (windowColor != null) 'windowColor': windowColor,
      if (windowRoundedCornerRadius != null)
        'windowRoundedCornerRadius': windowRoundedCornerRadius,
      if (windowType != null) 'windowType': windowType!.value,
    };
  }
}
