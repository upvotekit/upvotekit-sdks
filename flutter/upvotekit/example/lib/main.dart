import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:upvotekit/upvotekit.dart';

String get _defaultBaseUrl {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3100';
  }
  return 'http://localhost:3100';
}

const _baseUrlFromDefine = String.fromEnvironment('UPVOTEKIT_BASE_URL');
const _projectFromDefine = String.fromEnvironment(
  'UPVOTEKIT_PROJECT',
  defaultValue: 'acme',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final baseUrl = _baseUrlFromDefine.isNotEmpty
      ? _baseUrlFromDefine
      : _defaultBaseUrl;

  await UpvoteKit.initialize(
    baseUrl: baseUrl,
    project: _projectFromDefine,
    theme: UpvoteKitTheme.system,
    // Identified mode — call your own backend (never the UpvoteKit API key
    // from the client). Example:
    //
    // tokenProvider: () async {
    //   final response = await http.post(
    //     Uri.parse('https://your-api.example.com/upvotekit/embed-token'),
    //     headers: {'Authorization': 'Bearer ${await yourSessionToken()}'},
    //   );
    //   if (response.statusCode != 200) return null;
    //   return jsonDecode(response.body)['token'] as String?;
    // },
  );

  runApp(const UpvoteKitExampleApp());
}

class UpvoteKitExampleApp extends StatelessWidget {
  const UpvoteKitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UpvoteKit Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;
  bool _boardUnavailable = false;

  void _onUnavailable() {
    if (!mounted) return;
    setState(() => _boardUnavailable = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UpvoteKit Example')),
      body: _tabIndex == 0
          ? _LaunchPad(
              boardUnavailable: _boardUnavailable,
              onOpenFeedback: () => UpvoteKit.openFeedback(
                context,
                onUnavailable: _onUnavailable,
              ),
              onOpenRoadmap: () =>
                  UpvoteKit.openRoadmap(context, onUnavailable: _onUnavailable),
              onOpenChangelog: () => UpvoteKit.openChangelog(
                context,
                onUnavailable: _onUnavailable,
              ),
            )
          : UpvoteKitFeedbackView(onUnavailable: _onUnavailable),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) {
          setState(() => _tabIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Embedded',
          ),
        ],
      ),
    );
  }
}

class _LaunchPad extends StatelessWidget {
  const _LaunchPad({
    required this.boardUnavailable,
    required this.onOpenFeedback,
    required this.onOpenRoadmap,
    required this.onOpenChangelog,
  });

  final bool boardUnavailable;
  final VoidCallback onOpenFeedback;
  final VoidCallback onOpenRoadmap;
  final VoidCallback onOpenChangelog;

  @override
  Widget build(BuildContext context) {
    final base = UpvoteKit.config?.normalizedBaseUrl ?? '';
    final project = UpvoteKit.config?.project ?? '';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Hosted embeds', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'baseUrl: $base\nproject: $project',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        if (boardUnavailable)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'This board is under maintenance. Please check back later.',
            ),
          ),
        if (!boardUnavailable)
          FilledButton(
            onPressed: onOpenFeedback,
            child: const Text('Feedback'),
          ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: onOpenRoadmap,
          child: const Text('Roadmap'),
        ),
        const SizedBox(height: 12),
        UpvoteKitChangelogBadge(
          child: FilledButton.tonal(
            onPressed: onOpenChangelog,
            child: const Text('Changelog'),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Use the Embedded tab to host UpvoteKitFeedbackView inline.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
