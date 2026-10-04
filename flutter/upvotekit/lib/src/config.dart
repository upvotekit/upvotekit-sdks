import 'dart:ui' show Color;

/// Theme preference passed to the hosted embed as `theme`.
enum UpvoteKitTheme {
  light,
  dark,
  system;

  /// Query-param value for the embed URL.
  String get queryValue => name;
}

/// Portal look & feel preset passed to the hosted embed as `style`.
///
/// `null` on [UpvoteKitConfig] means the project's saved style is used and
/// the query param is omitted.
enum UpvoteKitStyle {
  classic,
  soft,
  editorial,
  brutalist,
  glass,
  studio,
  monoWhite,
  monoBlack,
  terminal,
  paper,
  neon;

  /// Kebab-case query-param value (`mono-white`, `mono-black`, otherwise [name]).
  String get queryValue => switch (this) {
    UpvoteKitStyle.monoWhite => 'mono-white',
    UpvoteKitStyle.monoBlack => 'mono-black',
    _ => name,
  };
}

/// Returns a short-lived embed JWT, or `null` for anonymous/public mode.
///
/// Tokens must be minted by the customer's backend via
/// `POST /api/v1/embed-tokens` using a server-side API key.
/// This SDK never accepts or requires an UpvoteKit API key.
typedef UpvoteKitTokenProvider = Future<String?> Function();

/// Immutable configuration set via [UpvoteKit.initialize].
class UpvoteKitConfig {
  /// Hosted UpvoteKit origin used when [baseUrl] is omitted.
  static const defaultBaseUrl = 'https://upvotekit.com';

  const UpvoteKitConfig({
    this.baseUrl = defaultBaseUrl,
    required this.project,
    this.tokenProvider,
    this.theme = UpvoteKitTheme.system,
    this.style,
    this.locale,
    this.board,
    this.accentColor,
    this.secondaryColor,
    this.backgroundColor,
  });

  /// Hosted UpvoteKit origin. Defaults to [defaultBaseUrl].
  ///
  /// Override for a self-hosted or local server.
  final String baseUrl;

  /// Project slug used in embed paths.
  final String project;

  /// Optional provider for short-lived embed JWTs (identified mode).
  final UpvoteKitTokenProvider? tokenProvider;

  /// Embed theme preference.
  final UpvoteKitTheme theme;

  /// Optional portal style. `null` uses the project setting (param omitted).
  final UpvoteKitStyle? style;

  /// Optional BCP-47 locale (e.g. `en`).
  final String? locale;

  /// Optional board slug to deep-link into a specific board.
  final String? board;

  /// Optional accent color override (sent as hex without `#`).
  final Color? accentColor;

  /// Optional highlight color (voted state, active tab, changelog markers).
  /// Sent as hex without `#`.
  final Color? secondaryColor;

  /// Optional page background (sent as hex without `#`).
  ///
  /// The embed derives card, text, and border colors from it and picks light
  /// or dark rendering from its luminance. Styles with a fixed mode
  /// (`monoWhite`, `monoBlack`, `terminal`, `paper`, `neon`) ignore it.
  ///
  /// Static default; prefer the per-view param.
  final Color? backgroundColor;

  /// Normalized base URL without a trailing slash.
  String get normalizedBaseUrl {
    final trimmed = baseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
