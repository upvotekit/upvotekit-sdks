import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:upvotekit/src/config.dart';
import 'package:upvotekit/src/url_builder.dart';

void main() {
  group('UpvoteKitUrlBuilder', () {
    late UpvoteKitUrlBuilder builder;

    setUp(() {
      builder = UpvoteKitUrlBuilder(
        const UpvoteKitConfig(
          baseUrl: 'https://upvotekit.com/',
          project: 'acme',
          theme: UpvoteKitTheme.dark,
          locale: 'en',
          board: 'ideas',
        ),
      );
    });

    test('builds feedback route and strips trailing slash from baseUrl', () {
      final uri = builder.build(route: UpvoteKitRoute.feedback);

      expect(uri.scheme, 'https');
      expect(uri.host, 'upvotekit.com');
      expect(uri.path, '/embed/acme/feedback');
      expect(uri.queryParameters['sdk'], 'flutter');
      expect(uri.queryParameters['theme'], 'dark');
      expect(uri.queryParameters['locale'], 'en');
      expect(uri.queryParameters['board'], 'ideas');
      expect(uri.queryParameters.containsKey('token'), isFalse);
    });

    test('builds feedback detail, roadmap, changelog, and submit paths', () {
      expect(
        builder
            .build(route: UpvoteKitRoute.feedbackDetail, feedbackId: 'fb-123')
            .path,
        '/embed/acme/feedback/fb-123',
      );
      expect(
        builder.build(route: UpvoteKitRoute.roadmap).path,
        '/embed/acme/roadmap',
      );
      expect(
        builder.build(route: UpvoteKitRoute.changelog).path,
        '/embed/acme/changelog',
      );
      expect(
        builder.build(route: UpvoteKitRoute.submit).path,
        '/embed/acme/submit',
      );
    });

    test('encodes token and special characters in query/path', () {
      final uri = builder.build(
        route: UpvoteKitRoute.feedbackDetail,
        feedbackId: 'id with spaces',
        token: 'jwt+token/value=',
        locale: 'en-US',
        board: 'board slug',
        theme: UpvoteKitTheme.light,
      );

      expect(uri.path, '/embed/acme/feedback/id%20with%20spaces');
      expect(uri.queryParameters['token'], 'jwt+token/value=');
      expect(uri.queryParameters['theme'], 'light');
      expect(uri.queryParameters['locale'], 'en-US');
      expect(uri.queryParameters['board'], 'board slug');
      expect(uri.queryParameters['sdk'], 'flutter');
    });

    test('omits empty optional params and always sets sdk=flutter', () {
      final emptyBuilder = UpvoteKitUrlBuilder(
        const UpvoteKitConfig(
          baseUrl: 'http://localhost:3000',
          project: 'demo',
        ),
      );

      final uri = emptyBuilder.build(
        route: UpvoteKitRoute.feedback,
        token: '  ',
        locale: '',
        board: null,
      );

      expect(uri.queryParameters.keys.toList(), ['sdk', 'theme']);
      expect(uri.queryParameters['sdk'], 'flutter');
      expect(uri.queryParameters['theme'], 'system');
    });

    test('omits style by default and sends mono-black for monoBlack', () {
      final uri = builder.build(route: UpvoteKitRoute.feedback);
      expect(uri.queryParameters.containsKey('style'), isFalse);

      final styled = UpvoteKitUrlBuilder(
        const UpvoteKitConfig(
          baseUrl: 'https://upvotekit.com',
          project: 'acme',
          style: UpvoteKitStyle.monoBlack,
        ),
      ).build(route: UpvoteKitRoute.feedback);

      expect(styled.queryParameters['style'], 'mono-black');
    });

    test('per-call style override wins over config', () {
      final styled = UpvoteKitUrlBuilder(
        const UpvoteKitConfig(
          baseUrl: 'https://upvotekit.com',
          project: 'acme',
          style: UpvoteKitStyle.classic,
        ),
      );

      final uri = styled.build(
        route: UpvoteKitRoute.feedback,
        style: UpvoteKitStyle.monoBlack,
      );

      expect(uri.queryParameters['style'], 'mono-black');
    });

    test('adds accent as hex without hash', () {
      const color = Color(0xFF1A73E8);
      final uri = builder.build(
        route: UpvoteKitRoute.feedback,
        accentColor: color,
      );

      expect(uri.queryParameters['accent'], '1a73e8');
      expect(UpvoteKitUrlBuilder.colorToHex(color), '1a73e8');
    });

    test('emits secondary and bg as lowercase hex without hash', () {
      const secondary = Color(0xFFAB12CD);
      const background = Color(0xFFF5F5F5);
      final uri = UpvoteKitUrlBuilder(
        const UpvoteKitConfig(
          baseUrl: 'https://upvotekit.com',
          project: 'acme',
          secondaryColor: secondary,
          backgroundColor: background,
        ),
      ).build(route: UpvoteKitRoute.feedback);

      expect(uri.queryParameters['secondary'], 'ab12cd');
      expect(uri.queryParameters['bg'], 'f5f5f5');
    });

    test('omits secondary and bg when null', () {
      final uri = builder.build(route: UpvoteKitRoute.feedback);

      expect(uri.queryParameters.containsKey('secondary'), isFalse);
      expect(uri.queryParameters.containsKey('bg'), isFalse);
    });

    test('per-call secondary and background overrides beat config', () {
      final colored = UpvoteKitUrlBuilder(
        const UpvoteKitConfig(
          baseUrl: 'https://upvotekit.com',
          project: 'acme',
          secondaryColor: Color(0xFF000000),
          backgroundColor: Color(0xFFFFFFFF),
        ),
      );

      final uri = colored.build(
        route: UpvoteKitRoute.feedback,
        secondaryColor: const Color(0xFF112233),
        backgroundColor: const Color(0xFF445566),
      );

      expect(uri.queryParameters['secondary'], '112233');
      expect(uri.queryParameters['bg'], '445566');
    });

    test('throws when feedback detail is missing feedbackId', () {
      expect(
        () => builder.build(route: UpvoteKitRoute.feedbackDetail),
        throwsArgumentError,
      );
    });

    test('encodes project slug in path', () {
      final custom = UpvoteKitUrlBuilder(
        const UpvoteKitConfig(
          baseUrl: 'http://localhost:3000',
          project: 'acme/co',
        ),
      );

      expect(
        custom.build(route: UpvoteKitRoute.feedback).path,
        '/embed/acme%2Fco/feedback',
      );
    });
  });
}
