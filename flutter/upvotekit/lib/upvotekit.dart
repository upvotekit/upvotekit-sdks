/// First-party Flutter SDK for UpvoteKit.
///
/// Thin webview wrapper around hosted embed pages. This package never accepts
/// or requires an UpvoteKit API key — mint short-lived embed tokens on your
/// backend via `POST /api/v1/embed-tokens`.
library;

export 'src/bridge.dart' show UpvoteKitEvent, UpvoteKitEventType;
export 'src/changelog_badge.dart' show UpvoteKitChangelogBadge;
export 'src/config.dart';
export 'src/upvotekit.dart';
export 'src/views.dart';
