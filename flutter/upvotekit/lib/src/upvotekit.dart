import 'package:flutter/material.dart';

import 'config.dart';
import 'runtime.dart';
import 'views.dart';

/// Static facade for configuring and presenting UpvoteKit embeds.
class UpvoteKit {
  UpvoteKit._();

  /// Current configuration, or `null` if [initialize] has not been called.
  static UpvoteKitConfig? get config => UpvoteKitRuntime.config;

  /// Configuration used by embed views. Throws if not initialized.
  static UpvoteKitConfig get configOrThrow => UpvoteKitRuntime.requireConfig;

  /// Whether [initialize] has been called.
  static bool get isInitialized => UpvoteKitRuntime.config != null;

  /// Configures the SDK. Safe to call again to update settings.
  ///
  /// **Security:** Never pass an UpvoteKit API key to this SDK. Mint embed
  /// tokens on your backend via `POST /api/v1/embed-tokens` using a server-side
  /// API key with scope `end_users:write`, then return the short-lived JWT from
  /// [tokenProvider].
  static Future<void> initialize({
    String baseUrl = UpvoteKitConfig.defaultBaseUrl,
    required String project,
    UpvoteKitTokenProvider? tokenProvider,
    UpvoteKitTheme theme = UpvoteKitTheme.system,
    UpvoteKitStyle? style,
    String? locale,
    String? board,
    Color? accentColor,
    Color? secondaryColor,
    Color? backgroundColor,
  }) async {
    UpvoteKitRuntime.config = UpvoteKitConfig(
      baseUrl: baseUrl,
      project: project,
      tokenProvider: tokenProvider,
      theme: theme,
      style: style,
      locale: locale,
      board: board,
      accentColor: accentColor,
      secondaryColor: secondaryColor,
      backgroundColor: backgroundColor,
    );
  }

  /// Clears configuration (primarily for tests).
  static void reset() {
    UpvoteKitRuntime.reset();
  }

  /// Pushes a full-screen feedback board route with an AppBar close button.
  static Future<void> openFeedback(
    BuildContext context, {
    String? title,
    UpvoteKitEventCallback? onEvent,
    UpvoteKitFeedbackCreatedCallback? onFeedbackCreated,
    UpvoteKitVoteChangedCallback? onVoteChanged,
    UpvoteKitUnavailableCallback? onUnavailable,
    void Function(String path)? onNavigate,
  }) {
    return _open(
      context,
      title: title ?? 'Feedback',
      child: UpvoteKitFeedbackView(
        onEvent: onEvent,
        onFeedbackCreated: onFeedbackCreated,
        onVoteChanged: onVoteChanged,
        onUnavailable: onUnavailable,
        onNavigate: onNavigate,
      ),
    );
  }

  /// Pushes a full-screen roadmap route with an AppBar close button.
  static Future<void> openRoadmap(
    BuildContext context, {
    String? title,
    UpvoteKitEventCallback? onEvent,
    UpvoteKitFeedbackCreatedCallback? onFeedbackCreated,
    UpvoteKitVoteChangedCallback? onVoteChanged,
    UpvoteKitUnavailableCallback? onUnavailable,
    void Function(String path)? onNavigate,
  }) {
    return _open(
      context,
      title: title ?? 'Roadmap',
      child: UpvoteKitRoadmapView(
        onEvent: onEvent,
        onFeedbackCreated: onFeedbackCreated,
        onVoteChanged: onVoteChanged,
        onUnavailable: onUnavailable,
        onNavigate: onNavigate,
      ),
    );
  }

  /// Pushes a full-screen changelog route with an AppBar close button.
  static Future<void> openChangelog(
    BuildContext context, {
    String? title,
    UpvoteKitEventCallback? onEvent,
    UpvoteKitFeedbackCreatedCallback? onFeedbackCreated,
    UpvoteKitVoteChangedCallback? onVoteChanged,
    UpvoteKitUnavailableCallback? onUnavailable,
    void Function(String path)? onNavigate,
  }) {
    return _open(
      context,
      title: title ?? 'Changelog',
      child: UpvoteKitChangelogView(
        onEvent: onEvent,
        onFeedbackCreated: onFeedbackCreated,
        onVoteChanged: onVoteChanged,
        onUnavailable: onUnavailable,
        onNavigate: onNavigate,
      ),
    );
  }

  static Future<void> _open(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            body: child,
          );
        },
      ),
    );
  }
}
