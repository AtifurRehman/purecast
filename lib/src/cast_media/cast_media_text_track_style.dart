import 'package:color/color.dart' show HexColor;

enum TextTrackEdgeType {
  NONE('NONE'),
  OUTLINE('OUTLINE'),
  DROP_SHADOW('DROP_SHADOW'),
  RAISED('RAISED'),
  DEPRESSED('DEPRESSED');

  /// Defines the text track edge (border) type.
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

  /// Generic font family to be used if the font is not defined in the text track.
  const TextTrackFontGenericFamily(this.value);
  final String value;
}

enum TextTrackFontStyle {
  NORMAL('NORMAL'),
  BOLD('BOLD'),
  BOLD_ITALIC('BOLD_ITALIC'),
  ITALIC('ITALIC');

  /// The text track font style.
  const TextTrackFontStyle(this.value);
  final String value;
}

enum TextTrackWindowType {
  NONE('NONE'),
  NORMAL('NORMAL'),
  ROUNDED_CORNERS('ROUNDED_CORNERS');

  /// The window concept as defined in CEA-608 and CEA-708. In WebVTT, this is called a region.
  const TextTrackWindowType(this.value);
  final String value;
}

class CastMediaTextTrackStyle {
  String? _backgroundColorHex;
  HexColor? backgroundColor; // 32-bit RGB color, represented as #RRGGBB
  double
      backgroundColorAlpha; // Alpha component of the background color, from 0.0 to 1.0
  Map<String, dynamic>? customData;
  String? _edgeColorHex;
  HexColor? edgeColor; // RGB color for the edge
  double edgeColorAlpha; // Alpha component of the edge color, from 0.0 to 1.0
  TextTrackEdgeType? edgeType; // Edge type
  String? fontFamily; // Font family
  TextTrackFontGenericFamily? fontGenericFamily; // Generic family of the font
  double? fontScale; // Font-scaling factor, default is 1
  TextTrackFontStyle? fontStyle; // Font style
  String? _foregroundColorHex;
  HexColor?
      foregroundColor; // Foreground 32-bit RGB color, represented as #RRGGBB
  double
      foregroundColorAlpha; // Alpha component of the foreground color, from 0.0 to 1.0
  String? _windowColorHex;
  HexColor?
      windowColor; // 32-bit RGB color for the window, represented as #RRGGBB
  double
      windowColorAlpha; // Alpha component of the window color, from 0.0 to 1.0
  double?
      windowRoundedCornerRadius; // Absolute radius of the rounded corners of the window, in pixels
  TextTrackWindowType? windowType; // Window type

  /// Creates a [CastMediaTextTrackStyle] to me used with a text track [CastMediaTrack]
  /// * [backgroundColor] - 32-bit RGBA color, represented as #RRGGBB
  /// * [backgroundColorAlpha] - Alpha component of the background color, from 0.0 to 1.0
  /// * [customData] - Custom data
  /// * [edgeColor] - RGBA color for the edge
  /// * [edgeColorAlpha] - Alpha component of the edge color, from 0.0 to 1.0
  /// * [edgeType] - Edge type
  /// * [fontFamily] - Font family
  /// * [fontGenericFamily] - Generic font family to be used if the font is not defined in the text track.
  /// * [fontScale] - Font-scaling factor, default is 1
  /// * [fontStyle] - Font style
  /// * [foregroundColor] - Foreground 32-bit RGBA color, represented as #RRGGBB
  /// * [foregroundColorAlpha] - Alpha component of the foreground color, from 0.0 to 1.0
  /// * [windowColor] - 32-bit RGBA color for the window, represented as #RRGGBB
  /// * [windowColorAlpha] - Alpha component of the window color, from 0.0 to 1.0
  /// * [windowRoundedCornerRadius] - Absolute radius of the rounded corners of the window, in pixels. This value will be ignored if windowType is not ROUNDED_CORNERS.
  /// * [windowType] - Window type
  /// Read: https://github.com/thibauts/node-castv2-client/wiki/How-to-use-subtitles-with-the-DefaultMediaReceiver-app
  CastMediaTextTrackStyle({
    this.backgroundColor = const HexColor.fromRgb(0, 0, 0),
    this.backgroundColorAlpha = 1,
    this.foregroundColor = const HexColor.fromRgb(255, 255, 255),
    this.foregroundColorAlpha = 1,
    this.customData,
    this.edgeColor = const HexColor.fromRgb(0, 0, 0),
    this.edgeColorAlpha = 1,
    this.edgeType,
    this.fontFamily,
    this.fontGenericFamily,
    this.fontScale,
    this.fontStyle,
    this.windowColor = const HexColor.fromRgb(0, 0, 0),
    this.windowColorAlpha = 1,
    this.windowRoundedCornerRadius,
    this.windowType,
  }) {
    if (backgroundColorAlpha > 1 ||
        foregroundColorAlpha > 1 ||
        edgeColorAlpha > 1 ||
        windowColorAlpha > 1 ||
        backgroundColorAlpha < 0 ||
        foregroundColorAlpha < 0 ||
        edgeColorAlpha < 0 ||
        windowColorAlpha < 0) {
      throw Exception('Alpha values must be between 0 and 1');
    }
    _backgroundColorHex =
        "#${backgroundColor?.toHexColor().toString()}${(backgroundColorAlpha * 255.toDouble()).round().toRadixString(16)}";
    _foregroundColorHex =
        "#${foregroundColor?.toHexColor().toString()}${(foregroundColorAlpha * 255.toDouble()).round().toRadixString(16)}";
    _edgeColorHex =
        "#${edgeColor?.toHexColor().toString()}${(edgeColorAlpha * 255.toDouble()).round().toRadixString(16)}";
    _windowColorHex =
        "#${windowColor?.toHexColor().toString()}${(windowColorAlpha * 255.toDouble()).round().toRadixString(16)}";
  }

  Map toChromeCastMap() {
    return {
      'backgroundColor': _backgroundColorHex,
      'foregroundColor': _foregroundColorHex,
      if (customData != null) 'customData': customData,
      'edgeColor': _edgeColorHex,
      if (edgeType != null) 'edgeType': edgeType!.value,
      if (fontFamily != null) 'fontFamily': fontFamily,
      if (fontGenericFamily != null)
        'fontGenericFamily': fontGenericFamily!.value,
      if (fontScale != null) 'fontScale': fontScale,
      if (fontStyle != null) 'fontStyle': fontStyle!.value,
      'windowColor': _windowColorHex,
      if (windowRoundedCornerRadius != null)
        'windowRoundedCornerRadius': windowRoundedCornerRadius,
      if (windowType != null) 'windowType': windowType!.value,
    };
  }
}
