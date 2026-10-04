import 'config.dart';

/// Internal holder for the active [UpvoteKitConfig].
class UpvoteKitRuntime {
  UpvoteKitRuntime._();

  static UpvoteKitConfig? config;

  static UpvoteKitConfig get requireConfig {
    final value = config;
    if (value == null) {
      throw StateError(
        'UpvoteKit.initialize() must be called before using UpvoteKit views.',
      );
    }
    return value;
  }

  static void reset() {
    config = null;
  }
}
