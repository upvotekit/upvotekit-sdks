import 'package:flutter_test/flutter_test.dart';
import 'package:upvotekit/upvotekit.dart';
import 'package:upvotekit_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await UpvoteKit.initialize(
      baseUrl: 'http://localhost:3000',
      project: 'acme',
    );
  });

  tearDown(UpvoteKit.reset);

  testWidgets('home shows launch buttons', (tester) async {
    await tester.pumpWidget(const UpvoteKitExampleApp());
    await tester.pump();

    expect(find.text('Feedback'), findsOneWidget);
    expect(find.text('Roadmap'), findsOneWidget);
    expect(find.text('Changelog'), findsOneWidget);
  });
}
