import 'package:flutter_test/flutter_test.dart';
import 'package:upvotekit/upvotekit.dart';

void main() {
  tearDown(UpvoteKit.reset);

  test('baseUrl defaults to the hosted origin', () async {
    const config = UpvoteKitConfig(project: 'acme');
    expect(config.baseUrl, UpvoteKitConfig.defaultBaseUrl);
    expect(config.normalizedBaseUrl, 'https://upvotekit.com');

    await UpvoteKit.initialize(project: 'acme');
    expect(UpvoteKit.config?.baseUrl, UpvoteKitConfig.defaultBaseUrl);
    expect(UpvoteKit.config?.project, 'acme');
  });
}
