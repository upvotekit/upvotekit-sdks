import 'dart:ui' show Color;

import 'config.dart';

/// Embed route segments under `/embed/{project}/...`.
enum UpvoteKitRoute { feedback, feedbackDetail, roadmap, changelog, submit }

/// Builds hosted embed URLs from [UpvoteKitConfig] and route options.
class UpvoteKitUrlBuilder {
  const UpvoteKitUrlBuilder(this.config);

  final UpvoteKitConfig config;

  /// Builds a full embed URL for [route].
  ///
  /// Always includes `sdk=flutter`. Optional params are omitted when null/empty.
  Uri build({
    required UpvoteKitRoute route,
    String? feedbackId,
    String? token,
    UpvoteKitTheme? theme,
    UpvoteKitStyle? style,
    String? locale,
    String? board,
    Color? accentColor,
    Color? secondaryColor,
    Color? backgroundColor,
  }) {
    final path = _pathFor(route, feedbackId: feedbackId);
    final query = <String, String>{'sdk': 'flutter'};

    final resolvedToken = token?.trim();
    if (resolvedToken != null && resolvedToken.isNotEmpty) {
      query['token'] = resolvedToken;
    }

    final resolvedTheme = theme ?? config.theme;
    query['theme'] = resolvedTheme.queryValue;

    final resolvedStyle = style ?? config.style;
    if (resolvedStyle != null) {
      query['style'] = resolvedStyle.queryValue;
    }

    final resolvedLocale = (locale ?? config.locale)?.trim();
    if (resolvedLocale != null && resolvedLocale.isNotEmpty) {
      query['locale'] = resolvedLocale;
    }

    final resolvedBoard = (board ?? config.board)?.trim();
    if (resolvedBoard != null && resolvedBoard.isNotEmpty) {
      query['board'] = resolvedBoard;
    }

    final resolvedAccent = accentColor ?? config.accentColor;
    if (resolvedAccent != null) {
      query['accent'] = colorToHex(resolvedAccent);
    }

    final resolvedSecondary = secondaryColor ?? config.secondaryColor;
    if (resolvedSecondary != null) {
      query['secondary'] = colorToHex(resolvedSecondary);
    }

    final resolvedBackground = backgroundColor ?? config.backgroundColor;
    if (resolvedBackground != null) {
      query['bg'] = colorToHex(resolvedBackground);
    }

    return Uri.parse('${config.normalizedBaseUrl}$path')
        .replace(queryParameters: query);
  }

  String _pathFor(UpvoteKitRoute route, {String? feedbackId}) {
    final project = Uri.encodeComponent(config.project);
    switch (route) {
      case UpvoteKitRoute.feedback:
        return '/embed/$project/feedback';
      case UpvoteKitRoute.feedbackDetail:
        final id = feedbackId?.trim();
        if (id == null || id.isEmpty) {
          throw ArgumentError.value(
            feedbackId,
            'feedbackId',
            'Required for feedback detail route',
          );
        }
        return '/embed/$project/feedback/${Uri.encodeComponent(id)}';
      case UpvoteKitRoute.roadmap:
        return '/embed/$project/roadmap';
      case UpvoteKitRoute.changelog:
        return '/embed/$project/changelog';
      case UpvoteKitRoute.submit:
        return '/embed/$project/submit';
    }
  }

  /// Converts [color] to an RRGGBB hex string without `#`.
  static String colorToHex(Color color) {
    final value = color.toARGB32();
    final rgb = value & 0x00FFFFFF;
    return rgb.toRadixString(16).padLeft(6, '0');
  }
}
