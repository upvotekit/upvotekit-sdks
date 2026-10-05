import 'package:flutter_test/flutter_test.dart';
import 'package:upvotekit/src/bridge.dart';

void main() {
  const parser = UpvoteKitBridgeParser();

  group('UpvoteKitBridgeParser', () {
    test('parses ready event', () {
      final result = parser.parse(
        '{"source":"upvotekit","type":"ready","payload":{}}',
      );

      expect(result, isA<UpvoteKitBridgeMessage>());
      final event = (result as UpvoteKitBridgeMessage).event;
      expect(event.type, UpvoteKitEventType.ready);
      expect(event.payload, isEmpty);
    });

    test('parses resize with height', () {
      final result = parser.parse(
        '{"source":"upvotekit","type":"resize","payload":{"height":420}}',
      );

      final event = (result as UpvoteKitBridgeMessage).event;
      expect(event.type, UpvoteKitEventType.resize);
      expect(event.height, 420);
    });

    test('parses navigate, close, feedback-created, vote-changed', () {
      final navigate = parser.parse(
        '{"source":"upvotekit","type":"navigate","payload":{"path":"/embed/a/feedback/1"}}',
      );
      expect(
        (navigate as UpvoteKitBridgeMessage).event.path,
        '/embed/a/feedback/1',
      );

      final close = parser.parse('{"source":"upvotekit","type":"close"}');
      expect(
        (close as UpvoteKitBridgeMessage).event.type,
        UpvoteKitEventType.close,
      );

      final created = parser.parse(
        '{"source":"upvotekit","type":"feedback-created","payload":{"id":"f1","title":"Hello"}}',
      );
      final createdEvent = (created as UpvoteKitBridgeMessage).event;
      expect(createdEvent.type, UpvoteKitEventType.feedbackCreated);
      expect(createdEvent.feedbackId, 'f1');
      expect(createdEvent.feedbackTitle, 'Hello');

      final vote = parser.parse(
        '{"source":"upvotekit","type":"vote-changed","payload":{"id":"f1","voted":true,"voteCount":3}}',
      );
      final voteEvent = (vote as UpvoteKitBridgeMessage).event;
      expect(voteEvent.type, UpvoteKitEventType.voteChanged);
      expect(voteEvent.voted, isTrue);
      expect(voteEvent.voteCount, 3);
    });

    test('parses unavailable', () {
      final result = parser.parse(
        '{"source":"upvotekit","type":"unavailable","payload":{}}',
      );

      final event = (result as UpvoteKitBridgeMessage).event;
      expect(event.type, UpvoteKitEventType.unavailable);
      expect(event.payload, isEmpty);
    });

    test('parses changelog-viewed', () {
      final result = parser.parse(
        '{"source":"upvotekit","type":"changelog-viewed","payload":{"latestPublishedAt":"2026-10-01T00:00:00.000Z"}}',
      );

      final event = (result as UpvoteKitBridgeMessage).event;
      expect(event.type, UpvoteKitEventType.changelogViewed);
      expect(event.latestPublishedAt, '2026-10-01T00:00:00.000Z');

      final none = parser.parse(
        '{"source":"upvotekit","type":"changelog-viewed","payload":{"latestPublishedAt":null}}',
      );
      expect((none as UpvoteKitBridgeMessage).event.latestPublishedAt, isNull);

      final empty = parser.parse(
        '{"source":"upvotekit","type":"changelog-viewed","payload":{"latestPublishedAt":""}}',
      );
      expect((empty as UpvoteKitBridgeMessage).event.latestPublishedAt, isNull);
    });

    test('parses auth-expired and open-external', () {
      final auth = parser.parse(
        '{"source":"upvotekit","type":"auth-expired","payload":{}}',
      );
      expect(
        (auth as UpvoteKitBridgeMessage).event.type,
        UpvoteKitEventType.authExpired,
      );

      final open = parser.parse(
        '{"source":"upvotekit","type":"open-external","payload":{"url":"https://example.com"}}',
      );
      expect((open as UpvoteKitBridgeMessage).event.url, 'https://example.com');
    });

    test('ignores foreign source', () {
      final result = parser.parse(
        '{"source":"other","type":"ready","payload":{}}',
      );

      expect(result, isA<UpvoteKitBridgeIgnored>());
      expect((result as UpvoteKitBridgeIgnored).reason, 'foreign-source');
    });

    test('ignores invalid json and non-objects', () {
      expect(
        (parser.parse('not-json') as UpvoteKitBridgeIgnored).reason,
        'invalid-json',
      );
      expect(
        (parser.parse('[]') as UpvoteKitBridgeIgnored).reason,
        'not-object',
      );
      expect((parser.parse('') as UpvoteKitBridgeIgnored).reason, 'empty');
    });

    test('ignores missing or unknown type', () {
      expect(
        (parser.parse(
          '{"source":"upvotekit"}',
        ) as UpvoteKitBridgeIgnored).reason,
        'missing-type',
      );
      expect(
        (parser.parse(
          '{"source":"upvotekit","type":"nope"}',
        ) as UpvoteKitBridgeIgnored).reason,
        'unknown-type:nope',
      );
    });
  });
}
