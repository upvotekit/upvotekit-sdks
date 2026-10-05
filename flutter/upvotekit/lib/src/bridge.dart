import 'dart:convert';

/// Bridge channel name expected by the hosted embed page.
const String upvoteKitBridgeChannel = 'UpvoteKitBridge';

/// Message types posted from the embed via [upvoteKitBridgeChannel].
enum UpvoteKitEventType {
  ready,
  resize,
  navigate,
  close,
  feedbackCreated,
  voteChanged,
  authExpired,
  openExternal,
  unavailable,
  changelogViewed,
}

/// Parsed bridge event from the embed page.
class UpvoteKitEvent {
  const UpvoteKitEvent({required this.type, this.payload = const {}});

  final UpvoteKitEventType type;
  final Map<String, dynamic> payload;

  int? get height => _asInt(payload['height']);

  String? get path => payload['path'] as String?;

  String? get url => payload['url'] as String?;

  String? get feedbackId => payload['id'] as String?;

  String? get feedbackTitle => payload['title'] as String?;

  bool? get voted => payload['voted'] as bool?;

  int? get voteCount => _asInt(payload['voteCount']);

  /// Newest published release the changelog page reported, or `null`.
  String? get latestPublishedAt {
    final value = payload['latestPublishedAt'];
    if (value is! String || value.isEmpty) return null;
    return value;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// Result of parsing a raw bridge message string.
sealed class UpvoteKitBridgeParseResult {
  const UpvoteKitBridgeParseResult();
}

/// Valid UpvoteKit bridge message.
class UpvoteKitBridgeMessage extends UpvoteKitBridgeParseResult {
  const UpvoteKitBridgeMessage(this.event);

  final UpvoteKitEvent event;
}

/// Message ignored because it is not a valid UpvoteKit bridge payload.
class UpvoteKitBridgeIgnored extends UpvoteKitBridgeParseResult {
  const UpvoteKitBridgeIgnored(this.reason);

  final String reason;
}

/// Parses `window.UpvoteKitBridge.postMessage(JSON.stringify(msg))` payloads.
class UpvoteKitBridgeParser {
  const UpvoteKitBridgeParser();

  /// Parses [raw] JSON. Returns [UpvoteKitBridgeIgnored] for invalid/foreign
  /// messages instead of throwing.
  UpvoteKitBridgeParseResult parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const UpvoteKitBridgeIgnored('empty');
    }

    late final Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException {
      return const UpvoteKitBridgeIgnored('invalid-json');
    }

    if (decoded is! Map) {
      return const UpvoteKitBridgeIgnored('not-object');
    }

    final map = Map<String, dynamic>.from(decoded);
    if (map['source'] != 'upvotekit') {
      return const UpvoteKitBridgeIgnored('foreign-source');
    }

    final typeRaw = map['type'];
    if (typeRaw is! String) {
      return const UpvoteKitBridgeIgnored('missing-type');
    }

    final type = _typeFromString(typeRaw);
    if (type == null) {
      return UpvoteKitBridgeIgnored('unknown-type:$typeRaw');
    }

    final payloadRaw = map['payload'];
    final payload = payloadRaw is Map
        ? Map<String, dynamic>.from(payloadRaw)
        : <String, dynamic>{};

    return UpvoteKitBridgeMessage(UpvoteKitEvent(type: type, payload: payload));
  }

  static UpvoteKitEventType? _typeFromString(String value) {
    switch (value) {
      case 'ready':
        return UpvoteKitEventType.ready;
      case 'resize':
        return UpvoteKitEventType.resize;
      case 'navigate':
        return UpvoteKitEventType.navigate;
      case 'close':
        return UpvoteKitEventType.close;
      case 'feedback-created':
        return UpvoteKitEventType.feedbackCreated;
      case 'vote-changed':
        return UpvoteKitEventType.voteChanged;
      case 'auth-expired':
        return UpvoteKitEventType.authExpired;
      case 'open-external':
        return UpvoteKitEventType.openExternal;
      case 'unavailable':
        return UpvoteKitEventType.unavailable;
      case 'changelog-viewed':
        return UpvoteKitEventType.changelogViewed;
      default:
        return null;
    }
  }
}
