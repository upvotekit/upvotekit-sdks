import 'package:flutter/material.dart';

import 'runtime.dart';
import 'url_builder.dart';
import 'webview_widget.dart';

export 'webview_widget.dart'
    show
        UpvoteKitEventCallback,
        UpvoteKitFeedbackCreatedCallback,
        UpvoteKitUnavailableCallback,
        UpvoteKitVoteChangedCallback;

/// Embeds the project feedback board.
class UpvoteKitFeedbackView extends StatelessWidget {
  const UpvoteKitFeedbackView({
    super.key,
    this.onEvent,
    this.onFeedbackCreated,
    this.onVoteChanged,
    this.onUnavailable,
    this.onClose,
    this.onNavigate,
    this.secondaryColor,
    this.backgroundColor,
  });

  final UpvoteKitEventCallback? onEvent;
  final UpvoteKitFeedbackCreatedCallback? onFeedbackCreated;
  final UpvoteKitVoteChangedCallback? onVoteChanged;
  final UpvoteKitUnavailableCallback? onUnavailable;
  final VoidCallback? onClose;
  final void Function(String path)? onNavigate;

  /// Per-view override of the config value.
  final Color? secondaryColor;

  /// Per-view override of the config value.
  ///
  /// Pass `Theme.of(context).scaffoldBackgroundColor` to follow the app's theme.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return UpvoteKitEmbedView(
      config: UpvoteKitRuntime.requireConfig,
      route: UpvoteKitRoute.feedback,
      onEvent: onEvent,
      onFeedbackCreated: onFeedbackCreated,
      onVoteChanged: onVoteChanged,
      onUnavailable: onUnavailable,
      onClose: onClose,
      onNavigate: onNavigate,
      secondaryColor: secondaryColor,
      backgroundColor: backgroundColor,
    );
  }
}

/// Embeds a single feedback detail page.
class UpvoteKitFeedbackDetailView extends StatelessWidget {
  const UpvoteKitFeedbackDetailView({
    super.key,
    required this.feedbackId,
    this.onEvent,
    this.onFeedbackCreated,
    this.onVoteChanged,
    this.onUnavailable,
    this.onClose,
    this.onNavigate,
    this.secondaryColor,
    this.backgroundColor,
  });

  final String feedbackId;
  final UpvoteKitEventCallback? onEvent;
  final UpvoteKitFeedbackCreatedCallback? onFeedbackCreated;
  final UpvoteKitVoteChangedCallback? onVoteChanged;
  final UpvoteKitUnavailableCallback? onUnavailable;
  final VoidCallback? onClose;
  final void Function(String path)? onNavigate;

  /// Per-view override of the config value.
  final Color? secondaryColor;

  /// Per-view override of the config value.
  ///
  /// Pass `Theme.of(context).scaffoldBackgroundColor` to follow the app's theme.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return UpvoteKitEmbedView(
      config: UpvoteKitRuntime.requireConfig,
      route: UpvoteKitRoute.feedbackDetail,
      feedbackId: feedbackId,
      onEvent: onEvent,
      onFeedbackCreated: onFeedbackCreated,
      onVoteChanged: onVoteChanged,
      onUnavailable: onUnavailable,
      onClose: onClose,
      onNavigate: onNavigate,
      secondaryColor: secondaryColor,
      backgroundColor: backgroundColor,
    );
  }
}

/// Embeds the project roadmap.
class UpvoteKitRoadmapView extends StatelessWidget {
  const UpvoteKitRoadmapView({
    super.key,
    this.onEvent,
    this.onFeedbackCreated,
    this.onVoteChanged,
    this.onUnavailable,
    this.onClose,
    this.onNavigate,
    this.secondaryColor,
    this.backgroundColor,
  });

  final UpvoteKitEventCallback? onEvent;
  final UpvoteKitFeedbackCreatedCallback? onFeedbackCreated;
  final UpvoteKitVoteChangedCallback? onVoteChanged;
  final UpvoteKitUnavailableCallback? onUnavailable;
  final VoidCallback? onClose;
  final void Function(String path)? onNavigate;

  /// Per-view override of the config value.
  final Color? secondaryColor;

  /// Per-view override of the config value.
  ///
  /// Pass `Theme.of(context).scaffoldBackgroundColor` to follow the app's theme.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return UpvoteKitEmbedView(
      config: UpvoteKitRuntime.requireConfig,
      route: UpvoteKitRoute.roadmap,
      onEvent: onEvent,
      onFeedbackCreated: onFeedbackCreated,
      onVoteChanged: onVoteChanged,
      onUnavailable: onUnavailable,
      onClose: onClose,
      onNavigate: onNavigate,
      secondaryColor: secondaryColor,
      backgroundColor: backgroundColor,
    );
  }
}

/// Embeds the project changelog.
class UpvoteKitChangelogView extends StatelessWidget {
  const UpvoteKitChangelogView({
    super.key,
    this.onEvent,
    this.onFeedbackCreated,
    this.onVoteChanged,
    this.onUnavailable,
    this.onClose,
    this.onNavigate,
    this.secondaryColor,
    this.backgroundColor,
  });

  final UpvoteKitEventCallback? onEvent;
  final UpvoteKitFeedbackCreatedCallback? onFeedbackCreated;
  final UpvoteKitVoteChangedCallback? onVoteChanged;
  final UpvoteKitUnavailableCallback? onUnavailable;
  final VoidCallback? onClose;
  final void Function(String path)? onNavigate;

  /// Per-view override of the config value.
  final Color? secondaryColor;

  /// Per-view override of the config value.
  ///
  /// Pass `Theme.of(context).scaffoldBackgroundColor` to follow the app's theme.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return UpvoteKitEmbedView(
      config: UpvoteKitRuntime.requireConfig,
      route: UpvoteKitRoute.changelog,
      onEvent: onEvent,
      onFeedbackCreated: onFeedbackCreated,
      onVoteChanged: onVoteChanged,
      onUnavailable: onUnavailable,
      onClose: onClose,
      onNavigate: onNavigate,
      secondaryColor: secondaryColor,
      backgroundColor: backgroundColor,
    );
  }
}

/// Embeds the submit-feedback form.
class UpvoteKitSubmitView extends StatelessWidget {
  const UpvoteKitSubmitView({
    super.key,
    this.onEvent,
    this.onFeedbackCreated,
    this.onVoteChanged,
    this.onUnavailable,
    this.onClose,
    this.onNavigate,
    this.secondaryColor,
    this.backgroundColor,
  });

  final UpvoteKitEventCallback? onEvent;
  final UpvoteKitFeedbackCreatedCallback? onFeedbackCreated;
  final UpvoteKitVoteChangedCallback? onVoteChanged;
  final UpvoteKitUnavailableCallback? onUnavailable;
  final VoidCallback? onClose;
  final void Function(String path)? onNavigate;

  /// Per-view override of the config value.
  final Color? secondaryColor;

  /// Per-view override of the config value.
  ///
  /// Pass `Theme.of(context).scaffoldBackgroundColor` to follow the app's theme.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return UpvoteKitEmbedView(
      config: UpvoteKitRuntime.requireConfig,
      route: UpvoteKitRoute.submit,
      onEvent: onEvent,
      onFeedbackCreated: onFeedbackCreated,
      onVoteChanged: onVoteChanged,
      onUnavailable: onUnavailable,
      onClose: onClose,
      onNavigate: onNavigate,
      secondaryColor: secondaryColor,
      backgroundColor: backgroundColor,
    );
  }
}
