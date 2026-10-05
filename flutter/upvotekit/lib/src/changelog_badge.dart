import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'bridge.dart';
import 'runtime.dart';

/// Days that count as unread when the changelog has never been opened.
const changelogBadgeWindowDays = 30;

/// Counts above this are shown as "9+".
const changelogBadgeCap = 9;

/// How long [fetchLatestPublishedAt] waits before treating the board as quiet.
const defaultChangelogFetchTimeout = Duration(seconds: 5);

@visibleForTesting
Duration changelogFetchTimeout = defaultChangelogFetchTimeout;

/// Clock for the seen-date fallback and the unread window. Tests replace it.
@visibleForTesting
DateTime Function() changelogBadgeClock = DateTime.now;

/// When set, [refreshUnreadChangelogCount] uses this instead of a real client.
@visibleForTesting
http.Client? debugChangelogHttpClient;

final ValueNotifier<int> _unreadChangelog = ValueNotifier<int>(0);

/// In-flight fetches compare against this so a newer "seen" wins.
int _refreshGeneration = 0;

/// Listenable unread count. The same object as [UpvoteKit.unreadChangelog].
ValueListenable<int> get unreadChangelogListenable => _unreadChangelog;

/// Drops the count and ignores a fetch that started earlier.
void clearUnreadChangelog() {
  _refreshGeneration++;
  _unreadChangelog.value = 0;
}

/// Clears badge state. Used by [UpvoteKit.reset].
void resetChangelogBadge() {
  clearUnreadChangelog();
  debugChangelogHttpClient = null;
  changelogBadgeClock = DateTime.now;
  changelogFetchTimeout = defaultChangelogFetchTimeout;
}

/// Releases newer than [seen].
///
/// Mirrors the web rule: with no seen date, or one that does not parse, only
/// releases from the last [changelogBadgeWindowDays] days count.
int unreadReleaseCount(
  List<String> publishedAt,
  String? seen, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final seenAt = _parseInstant(seen);
  final since =
      seenAt ?? clock.subtract(const Duration(days: changelogBadgeWindowDays));
  var count = 0;
  for (final date in publishedAt) {
    final parsed = _parseInstant(date);
    if (parsed != null && parsed.isAfter(since)) count++;
  }
  return count;
}

/// Badge text for [count]. `null` hides it; above [changelogBadgeCap] is "9+".
///
/// Mirrors the web rule.
String? unreadBadgeLabel(int count) {
  if (count <= 0) return null;
  return count > changelogBadgeCap ? '$changelogBadgeCap+' : '$count';
}

String _unreadSemanticsLabel(int count) {
  if (count > changelogBadgeCap) {
    return '$changelogBadgeCap or more new updates';
  }
  final noun = count == 1 ? 'update' : 'updates';
  return '$count new $noun';
}

DateTime? _parseInstant(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

/// `shared_preferences` key for the newest release this install has seen.
String changelogSeenStorageKey(String baseUrl, String project) {
  return 'upvotekit.changelog.seen|$baseUrl|$project';
}

Future<String?> _readSeen(String baseUrl, String project) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(changelogSeenStorageKey(baseUrl, project));
}

Future<void> _writeSeen(String baseUrl, String project, String seen) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(changelogSeenStorageKey(baseUrl, project), seen);
}

Uri _changelogLatestUri(String baseUrl, String project) {
  final base = Uri.parse(baseUrl);
  return base.replace(
    pathSegments: [
      ...base.pathSegments.where((segment) => segment.isNotEmpty),
      'api',
      'public',
      project,
      'changelog',
      'latest',
    ],
  );
}

List<String> _publishedAtFromBody(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map) return const [];
  final data = decoded['data'];
  if (data is! Map) return const [];
  final publishedAt = data['publishedAt'];
  if (publishedAt is! List) return const [];
  return [
    for (final entry in publishedAt)
      if (entry is String) entry,
  ];
}

/// `GET /api/public/<project>/changelog/latest`.
///
/// 404, 503, a timeout, and any other failure return an empty list. Never
/// throws. [client] is for tests; production opens and closes its own.
Future<List<String>> fetchLatestPublishedAt({
  required String baseUrl,
  required String project,
  http.Client? client,
  Duration timeout = defaultChangelogFetchTimeout,
}) async {
  final ownsClient = client == null;
  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient
        .get(_changelogLatestUri(baseUrl, project))
        .timeout(timeout);
    if (response.statusCode != 200) return const [];
    return _publishedAtFromBody(response.body);
  } on Object {
    return const [];
  } finally {
    if (ownsClient) httpClient.close();
  }
}

/// Fetches, applies the unread rule, and updates [unreadChangelogListenable].
///
/// Returns 0 when the SDK is not initialized or the request or storage fails.
Future<int> refreshUnreadChangelogCount() async {
  final config = UpvoteKitRuntime.config;
  if (config == null) {
    _unreadChangelog.value = 0;
    return 0;
  }
  final generation = ++_refreshGeneration;
  try {
    final publishedAt = await fetchLatestPublishedAt(
      baseUrl: config.normalizedBaseUrl,
      project: config.project,
      client: debugChangelogHttpClient,
      timeout: changelogFetchTimeout,
    );
    if (generation != _refreshGeneration) return _unreadChangelog.value;
    final seen = await _readSeen(config.normalizedBaseUrl, config.project);
    if (generation != _refreshGeneration) return _unreadChangelog.value;
    final count = unreadReleaseCount(
      publishedAt,
      seen,
      now: changelogBadgeClock(),
    );
    _unreadChangelog.value = count;
    return count;
  } on Object {
    if (generation != _refreshGeneration) return _unreadChangelog.value;
    _unreadChangelog.value = 0;
    return 0;
  }
}

/// Stores the changelog page's seen date and clears the badge.
///
/// Called from the embed view when it receives `changelog-viewed`. The app's
/// `onEvent` callback still runs; this does not replace it.
Future<void> acknowledgeChangelogViewed(UpvoteKitEvent event) async {
  if (event.type != UpvoteKitEventType.changelogViewed) return;
  _refreshGeneration++;
  _unreadChangelog.value = 0;

  final config = UpvoteKitRuntime.config;
  if (config == null) return;
  final seen =
      event.latestPublishedAt ??
      changelogBadgeClock().toUtc().toIso8601String();
  try {
    await _writeSeen(config.normalizedBaseUrl, config.project, seen);
  } on Object {
    // The bubble is already cleared. The next visit stores the date.
  }
}

/// Wraps [child] with the unread-changelog count.
///
/// Nothing is drawn at 0. Counts above 9 are shown as "9+". The count is
/// fetched the first time the widget builds and follows
/// `UpvoteKit.unreadChangelog` after that.
///
/// Does not throw if the SDK is not initialized, the device is offline, or
/// storage fails — the bubble stays hidden.
class UpvoteKitChangelogBadge extends StatefulWidget {
  const UpvoteKitChangelogBadge({
    super.key,
    required this.child,
    this.backgroundColor,
    this.textColor,
  });

  final Widget child;

  /// Bubble fill. Defaults to the theme's error color.
  final Color? backgroundColor;

  /// Bubble text color. Defaults to the theme's on-error color.
  final Color? textColor;

  @override
  State<UpvoteKitChangelogBadge> createState() =>
      _UpvoteKitChangelogBadgeState();
}

class _UpvoteKitChangelogBadgeState extends State<UpvoteKitChangelogBadge> {
  @override
  void initState() {
    super.initState();
    unawaited(refreshUnreadChangelogCount());
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _unreadChangelog,
      builder: (context, count, child) {
        final label = unreadBadgeLabel(count);
        if (label == null) return child!;
        return Badge(
          backgroundColor: widget.backgroundColor,
          textColor: widget.textColor,
          label: Text(label, semanticsLabel: _unreadSemanticsLabel(count)),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
