import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upvotekit/src/bridge.dart';
import 'package:upvotekit/src/changelog_badge.dart';
import 'package:upvotekit/upvotekit.dart';

const _parser = UpvoteKitBridgeParser();

final _now = DateTime.utc(2026, 10, 5, 12);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    changelogBadgeClock = () => _now;
    await UpvoteKit.initialize(
      baseUrl: 'https://upvotekit.com',
      project: 'acme',
    );
  });

  tearDown(UpvoteKit.reset);

  group('unread rule', () {
    test('counts releases newer than the seen date', () {
      expect(
        unreadReleaseCount(
          [
            '2026-10-04T00:00:00.000Z',
            '2026-10-02T00:00:00.000Z',
            '2026-10-01T00:00:00.000Z',
          ],
          '2026-10-02T00:00:00.000Z',
          now: _now,
        ),
        1,
      );
    });

    test('a release at the seen instant is not unread', () {
      expect(
        unreadReleaseCount(
          ['2026-10-02T00:00:00.000Z'],
          '2026-10-02T00:00:00.000Z',
          now: _now,
        ),
        0,
      );
    });

    test('with nothing seen, only the last 30 days count', () {
      final edge = _now.subtract(const Duration(days: 30));
      expect(unreadReleaseCount([edge.toIso8601String()], null, now: _now), 0);
      expect(
        unreadReleaseCount(
          [edge.add(const Duration(milliseconds: 1)).toIso8601String()],
          null,
          now: _now,
        ),
        1,
      );
      expect(
        unreadReleaseCount(
          ['2026-10-01T00:00:00.000Z', '2026-09-01T00:00:00.000Z'],
          null,
          now: _now,
        ),
        1,
      );
    });

    test('an unparseable seen date uses the 30 day window', () {
      expect(
        unreadReleaseCount(
          ['2026-09-01T00:00:00.000Z'],
          'not-a-date',
          now: _now,
        ),
        0,
      );
      expect(
        unreadReleaseCount(
          ['2026-10-01T00:00:00.000Z'],
          'not-a-date',
          now: _now,
        ),
        1,
      );
    });

    test('unparseable release dates are ignored', () {
      expect(
        unreadReleaseCount(
          ['not-a-date', '2026-10-01T00:00:00.000Z'],
          null,
          now: _now,
        ),
        1,
      );
    });

    test('labels nothing at 0 and 9+ above the cap', () {
      expect(unreadBadgeLabel(0), isNull);
      expect(unreadBadgeLabel(-1), isNull);
      expect(unreadBadgeLabel(1), '1');
      expect(unreadBadgeLabel(9), '9');
      expect(unreadBadgeLabel(10), '9+');
      expect(unreadBadgeLabel(12), '9+');
    });
  });

  group('latest request', () {
    test('counts releases newer than the stored seen date', () async {
      SharedPreferences.setMockInitialValues({
        changelogSeenStorageKey('https://upvotekit.com', 'acme'):
            '2026-10-03T00:00:00.000Z',
      });
      debugChangelogHttpClient = _client(const [
        '2026-10-04T00:00:00.000Z',
        '2026-10-03T00:00:00.000Z',
        '2026-10-01T00:00:00.000Z',
      ]);

      expect(await UpvoteKit.unreadChangelogCount(), 1);
      expect(UpvoteKit.unreadChangelog.value, 1);
    });

    test('requests the public latest endpoint', () async {
      late Uri requested;
      debugChangelogHttpClient = MockClient((request) async {
        requested = request.url;
        return _body(const [
          '2026-10-04T00:00:00.000Z',
          '2026-10-03T00:00:00.000Z',
          '2026-09-01T00:00:00.000Z',
        ]);
      });

      expect(await UpvoteKit.unreadChangelogCount(), 2);
      expect(
        requested,
        Uri.parse('https://upvotekit.com/api/public/acme/changelog/latest'),
      );
    });

    test('404 counts as no unread releases', () async {
      debugChangelogHttpClient = MockClient(
        (_) async => http.Response('missing', 404),
      );

      expect(await UpvoteKit.unreadChangelogCount(), 0);
      expect(UpvoteKit.unreadChangelog.value, 0);
    });

    test('503 counts as no unread releases', () async {
      debugChangelogHttpClient = MockClient(
        (_) async => http.Response('unavailable', 503),
      );

      expect(await UpvoteKit.unreadChangelogCount(), 0);
      expect(UpvoteKit.unreadChangelog.value, 0);
    });

    test('a timeout counts as no unread releases', () async {
      changelogFetchTimeout = const Duration(milliseconds: 20);
      final gate = Completer<http.Response>();
      debugChangelogHttpClient = MockClient((_) => gate.future);

      expect(await UpvoteKit.unreadChangelogCount(), 0);
      expect(UpvoteKit.unreadChangelog.value, 0);
      gate.complete(http.Response('{}', 200));
    });

    test('a failed request counts as no unread releases', () async {
      debugChangelogHttpClient = MockClient((request) async {
        throw http.ClientException('offline', request.url);
      });

      expect(await UpvoteKit.unreadChangelogCount(), 0);
    });

    test('a body that is not the contract counts as none', () async {
      debugChangelogHttpClient = MockClient(
        (_) async => http.Response('nope', 200),
      );

      expect(await UpvoteKit.unreadChangelogCount(), 0);
    });

    test('is 0 when the SDK is not initialized', () async {
      UpvoteKit.reset();

      expect(await UpvoteKit.unreadChangelogCount(), 0);
      expect(UpvoteKit.unreadChangelog.value, 0);
    });
  });

  group('changelog-viewed', () {
    test('stores latestPublishedAt and clears the count', () async {
      debugChangelogHttpClient = _client(const [
        '2026-10-04T00:00:00.000Z',
        '2026-10-03T00:00:00.000Z',
        '2026-10-02T00:00:00.000Z',
      ]);
      expect(await UpvoteKit.unreadChangelogCount(), 3);

      await acknowledgeChangelogViewed(_viewed('2026-10-04T00:00:00.000Z'));

      expect(UpvoteKit.unreadChangelog.value, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(
          changelogSeenStorageKey('https://upvotekit.com', 'acme'),
        ),
        '2026-10-04T00:00:00.000Z',
      );
      expect(await UpvoteKit.unreadChangelogCount(), 0);
    });

    test('stores the current time when the page has no releases', () async {
      await acknowledgeChangelogViewed(_viewed(null));

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(
          changelogSeenStorageKey('https://upvotekit.com', 'acme'),
        ),
        _now.toIso8601String(),
      );
      expect(UpvoteKit.unreadChangelog.value, 0);
    });

    test('keeps the seen date scoped by base url and project', () async {
      await acknowledgeChangelogViewed(_viewed('2026-10-01T00:00:00.000Z'));
      await UpvoteKit.initialize(
        baseUrl: 'https://example.com/',
        project: 'other',
      );
      await acknowledgeChangelogViewed(_viewed('2026-09-01T00:00:00.000Z'));

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(
          changelogSeenStorageKey('https://upvotekit.com', 'acme'),
        ),
        '2026-10-01T00:00:00.000Z',
      );
      expect(
        prefs.getString(
          changelogSeenStorageKey('https://example.com', 'other'),
        ),
        '2026-09-01T00:00:00.000Z',
      );
      expect(
        prefs.getString(
          changelogSeenStorageKey('https://example.com/', 'other'),
        ),
        isNull,
      );
    });

    test('an in-flight fetch does not restore the count', () async {
      final gate = Completer<http.Response>();
      debugChangelogHttpClient = MockClient((_) => gate.future);
      final pending = UpvoteKit.unreadChangelogCount();
      await acknowledgeChangelogViewed(_viewed('2026-10-01T00:00:00.000Z'));
      gate.complete(
        _body(const ['2026-10-04T00:00:00.000Z', '2026-10-03T00:00:00.000Z']),
      );

      expect(await pending, 0);
      expect(UpvoteKit.unreadChangelog.value, 0);
      expect(await UpvoteKit.unreadChangelogCount(), 2);
    });

    test('does not throw when the SDK is not initialized', () async {
      UpvoteKit.reset();

      await acknowledgeChangelogViewed(_viewed('2026-10-01T00:00:00.000Z'));
      expect(UpvoteKit.unreadChangelog.value, 0);
    });
  });

  group('UpvoteKitChangelogBadge', () {
    testWidgets('shows nothing at 0', (tester) async {
      debugChangelogHttpClient = _client(const ['2020-01-01T00:00:00.000Z']);

      await _pumpBadge(tester);

      expect(find.text('Open'), findsOneWidget);
      expect(find.byType(Badge), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows 3', (tester) async {
      debugChangelogHttpClient = _client(const [
        '2026-10-04T00:00:00.000Z',
        '2026-10-03T00:00:00.000Z',
        '2026-10-02T00:00:00.000Z',
      ]);

      await _pumpBadge(tester);

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('3')).semanticsLabel,
        '3 new updates',
      );
    });

    testWidgets('shows 9+ for 12', (tester) async {
      debugChangelogHttpClient = _client([
        for (var i = 0; i < 12; i++)
          DateTime.utc(2026, 10, 4, 0, i).toIso8601String(),
      ]);

      await _pumpBadge(tester);

      expect(find.text('9+'), findsOneWidget);
      expect(find.text('12'), findsNothing);
      expect(
        tester.widget<Text>(find.text('9+')).semanticsLabel,
        '9 or more new updates',
      );
    });

    testWidgets('shows the child and no bubble when not initialized', (
      tester,
    ) async {
      UpvoteKit.reset();

      await _pumpBadge(tester);

      expect(find.text('Open'), findsOneWidget);
      expect(find.byType(Badge), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

UpvoteKitEvent _viewed(String? latestPublishedAt) {
  final result = _parser.parse(
    jsonEncode({
      'source': 'upvotekit',
      'type': 'changelog-viewed',
      'payload': {'latestPublishedAt': latestPublishedAt},
    }),
  );
  return (result as UpvoteKitBridgeMessage).event;
}

http.Response _body(List<String> publishedAt, {int statusCode = 200}) {
  return http.Response(
    jsonEncode({
      'data': {'publishedAt': publishedAt},
    }),
    statusCode,
  );
}

MockClient _client(List<String> publishedAt) {
  return MockClient((_) async => _body(publishedAt));
}

Future<void> _pumpBadge(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: UpvoteKitChangelogBadge(child: Text('Open'))),
    ),
  );
  await tester.pump();
}
