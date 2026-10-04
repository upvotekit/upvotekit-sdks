import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'bridge.dart';
import 'config.dart';
import 'url_builder.dart';

/// Callback fired for every recognized bridge event.
typedef UpvoteKitEventCallback = void Function(UpvoteKitEvent event);

/// Callback when the embed creates feedback.
typedef UpvoteKitFeedbackCreatedCallback = void Function({
  required String id,
  required String? title,
});

/// Callback when a vote changes in the embed.
typedef UpvoteKitVoteChangedCallback = void Function({
  required String id,
  required bool? voted,
  required int? voteCount,
});

/// Callback when the board is under maintenance.
///
/// Host apps can use this to hide a Feedback button. The embed still posts
/// `ready` and `resize`.
typedef UpvoteKitUnavailableCallback = void Function();

/// Shared webview host for all UpvoteKit embed routes.
class UpvoteKitEmbedView extends StatefulWidget {
  const UpvoteKitEmbedView({
    super.key,
    required this.config,
    required this.route,
    this.feedbackId,
    this.onEvent,
    this.onFeedbackCreated,
    this.onVoteChanged,
    this.onUnavailable,
    this.onClose,
    this.onNavigate,
    this.secondaryColor,
    this.backgroundColor,
  });

  final UpvoteKitConfig config;
  final UpvoteKitRoute route;
  final String? feedbackId;
  final UpvoteKitEventCallback? onEvent;
  final UpvoteKitFeedbackCreatedCallback? onFeedbackCreated;
  final UpvoteKitVoteChangedCallback? onVoteChanged;
  final UpvoteKitUnavailableCallback? onUnavailable;
  final VoidCallback? onClose;
  final void Function(String path)? onNavigate;

  /// Per-call highlight override. Falls back to [UpvoteKitConfig.secondaryColor].
  final Color? secondaryColor;

  /// Per-call page background override. Falls back to
  /// [UpvoteKitConfig.backgroundColor].
  final Color? backgroundColor;

  @override
  State<UpvoteKitEmbedView> createState() => _UpvoteKitEmbedViewState();
}

class _UpvoteKitEmbedViewState extends State<UpvoteKitEmbedView> {
  static const _parser = UpvoteKitBridgeParser();

  late final WebViewController _controller;
  late UpvoteKitUrlBuilder _urlBuilder;

  late String _currentPath;
  bool _isLoading = true;
  String? _errorMessage;
  bool _canGoBack = false;

  UpvoteKitConfig get _config => widget.config;

  Color? get _backgroundColor =>
      widget.backgroundColor ?? _config.backgroundColor;

  static Color? _resolvedBackground(UpvoteKitEmbedView view) =>
      view.backgroundColor ?? view.config.backgroundColor;

  static Color? _resolvedSecondary(UpvoteKitEmbedView view) =>
      view.secondaryColor ?? view.config.secondaryColor;

  @override
  void didUpdateWidget(UpvoteKitEmbedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config != oldWidget.config) {
      _urlBuilder = UpvoteKitUrlBuilder(widget.config);
    }
    final backgroundChanged =
        _resolvedBackground(widget) != _resolvedBackground(oldWidget);
    final secondaryChanged =
        _resolvedSecondary(widget) != _resolvedSecondary(oldWidget);
    if (backgroundChanged || secondaryChanged) {
      _loadCurrentRoute();
    }
  }

  @override
  void initState() {
    super.initState();
    _urlBuilder = UpvoteKitUrlBuilder(_config);
    _currentPath = _pathForRoute(_config);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (_) async {
            if (!mounted) return;
            final canGoBack = await _controller.canGoBack();
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _canGoBack = canGoBack;
            });
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _errorMessage = error.description;
            });
          },
          onNavigationRequest: (request) {
            if (_isExternalUrl(request.url)) {
              _openExternal(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        upvoteKitBridgeChannel,
        onMessageReceived: _onBridgeMessage,
      );
    _loadCurrentRoute();
  }

  String _pathForRoute(UpvoteKitConfig config) {
    switch (widget.route) {
      case UpvoteKitRoute.feedback:
        return '/embed/${config.project}/feedback';
      case UpvoteKitRoute.feedbackDetail:
        return '/embed/${config.project}/feedback/${widget.feedbackId}';
      case UpvoteKitRoute.roadmap:
        return '/embed/${config.project}/roadmap';
      case UpvoteKitRoute.changelog:
        return '/embed/${config.project}/changelog';
      case UpvoteKitRoute.submit:
        return '/embed/${config.project}/submit';
    }
  }

  Future<void> _loadCurrentRoute({String? tokenOverride}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? token = tokenOverride;
    if (token == null && _config.tokenProvider != null) {
      try {
        token = await _config.tokenProvider!();
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch embed token: $error';
        });
        return;
      }
    }

    final built = _urlBuilder.build(
      route: widget.route,
      feedbackId: widget.feedbackId,
      token: token,
      secondaryColor: widget.secondaryColor,
      backgroundColor: widget.backgroundColor,
    );

    final background = _backgroundColor;
    if (background != null) {
      await _controller.setBackgroundColor(background);
    }

    final loadUri = built.replace(path: _currentPath);
    await _controller.loadRequest(loadUri);
  }

  void _onBridgeMessage(JavaScriptMessage message) {
    final result = _parser.parse(message.message);
    if (result is! UpvoteKitBridgeMessage) return;

    final event = result.event;
    widget.onEvent?.call(event);

    switch (event.type) {
      case UpvoteKitEventType.ready:
      case UpvoteKitEventType.resize:
        break;
      case UpvoteKitEventType.navigate:
        final path = event.path;
        if (path != null && path.isNotEmpty) {
          _currentPath = path.startsWith('/') ? path : '/$path';
          widget.onNavigate?.call(_currentPath);
        }
        break;
      case UpvoteKitEventType.close:
        _handleClose();
        break;
      case UpvoteKitEventType.feedbackCreated:
        widget.onFeedbackCreated?.call(
          id: event.feedbackId ?? '',
          title: event.feedbackTitle,
        );
        break;
      case UpvoteKitEventType.voteChanged:
        widget.onVoteChanged?.call(
          id: event.feedbackId ?? '',
          voted: event.voted,
          voteCount: event.voteCount,
        );
        break;
      case UpvoteKitEventType.authExpired:
        _refreshTokenAndReload();
        break;
      case UpvoteKitEventType.openExternal:
        final url = event.url;
        if (url != null && url.isNotEmpty) {
          _openExternal(url);
        }
        break;
      case UpvoteKitEventType.unavailable:
        widget.onUnavailable?.call();
        break;
    }
  }

  Future<void> _refreshTokenAndReload() async {
    final provider = _config.tokenProvider;
    if (provider == null) return;
    try {
      final token = await provider();
      if (!mounted) return;
      await _loadCurrentRoute(tokenOverride: token);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to refresh embed token: $error';
      });
    }
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  bool _isExternalUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;
    if (uri.scheme == 'about' || uri.scheme == 'data' || uri.scheme == 'blob') {
      return false;
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return true;
    }

    final base = Uri.parse(_config.normalizedBaseUrl);
    return uri.origin != base.origin;
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _onPopInvoked(bool didPop, Object? result) async {
    if (didPop) return;
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      final canGoBack = await _controller.canGoBack();
      if (mounted) {
        setState(() => _canGoBack = canGoBack);
      }
      return;
    }
    if (widget.onClose != null) {
      widget.onClose!();
    } else if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = _backgroundColor;
    final stack = Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const ExcludeSemantics(
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_errorMessage != null)
          ColoredBox(
            color: background ?? Theme.of(context).colorScheme.surface,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => _loadCurrentRoute(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: _onPopInvoked,
      child: background == null
          ? stack
          : ColoredBox(color: background, child: stack),
    );
  }
}
