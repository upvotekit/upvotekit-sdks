# UpvoteKit Flutter SDK

Thin first-party Flutter wrapper around [UpvoteKit](https://upvotekit.com) hosted embed pages (feedback board, roadmap, changelog). Uses `webview_flutter` for the embed UI and `url_launcher` for external links.

> **Security:** This package never accepts or requires an UpvoteKit API key. Mint short-lived embed JWTs on your backend.

## Install

```bash
flutter pub add upvotekit
```

```yaml
dependencies:
  upvotekit: ^0.2.0
```

## Initialize

```dart
import 'package:upvotekit/upvotekit.dart';

await UpvoteKit.initialize(
  project: 'your-project-slug',
);
```

`baseUrl` is optional and defaults to `https://upvotekit.com`. Pass it for a self-hosted or local server.

```dart
await UpvoteKit.initialize(
  project: 'your-project-slug',
  baseUrl: 'http://localhost:3100', // optional
  theme: UpvoteKitTheme.system, // light | dark | system
  style: null, // optional UpvoteKitStyle; null uses the project setting
  locale: 'en',
  board: null, // optional board slug
  accentColor: null, // optional Color runtime override
  secondaryColor: null, // optional highlight (voted state, active tab, changelog markers)
  backgroundColor: null, // static default; prefer the per-view param
  // tokenProvider: null => anonymous / public mode
);
```

### Anonymous vs identified mode

| Mode | `tokenProvider` | Behavior |
|------|-----------------|----------|
| Anonymous | `null` / omitted | Public embed; no end-user identity |
| Identified | `() async => token` | Embed loads with a short-lived JWT so votes/submissions are attributed |

### Embed token flow

```text
Customer Flutter app
        │
        │  1. Needs identified embed session
        ▼
Customer backend  ──────────────────────────────►  UpvoteKit API
        │  POST /api/v1/embed-tokens               │
        │  Authorization: Bearer upk_...           │  scope: end_users:write
        │  (API key stays server-side only)        │
        │                                          │
        │◄──────────── short-lived JWT ────────────┘
        │
        ▼
UpvoteKit.initialize(tokenProvider: () async => jwt)
        │
        ▼
Hosted embed  /embed/{project}/…?token=…&sdk=flutter
```

Your backend should call `POST /api/v1/embed-tokens` with a **server-side** API key (`upk_…`) that has scope `end_users:write`. Return only the JWT to the app. Never ship the API key in the Flutter client.

```dart
await UpvoteKit.initialize(
  project: 'acme',
  tokenProvider: () async {
    // Call YOUR backend — not UpvoteKit directly with an API key.
    final token = await yourApi.fetchUpvoteKitEmbedToken();
    return token;
  },
);
```

On `auth-expired` bridge messages, the SDK calls `tokenProvider` again and reloads the current embed route with the new token.

On `unavailable`, the board is under maintenance. Pass `onUnavailable` to a view or to `UpvoteKit.openFeedback` (and the other `open*` methods) and hide your Feedback button. The embed still posts `ready` and `resize`.

## Present embeds

### Full-screen routes (AppBar + close)

```dart
UpvoteKit.openFeedback(context);
UpvoteKit.openRoadmap(context);
UpvoteKit.openChangelog(context);
```

### Inline widgets

```dart
UpvoteKitFeedbackView();
UpvoteKitFeedbackDetailView(feedbackId: '...');
UpvoteKitRoadmapView();
UpvoteKitChangelogView();
UpvoteKitSubmitView();
```

### Callbacks

All views accept optional:

- `onEvent(UpvoteKitEvent)` — every recognized bridge event
- `onFeedbackCreated({id, title})`
- `onVoteChanged({id, voted, voteCount})`
- `onUnavailable()` — bridge `unavailable` (board under maintenance; hide a Feedback button)
- `onClose` — bridge `close` (defaults to `Navigator.maybePop`)
- `onNavigate(path)` — in-embed path changes

## What's new badge

`UpvoteKitChangelogBadge` wraps a button (or any other widget) and shows how many published releases the user has not opened. It fetches once, the first time it builds. A count of 0 draws nothing. Counts above 9 show as `9+`.

```dart
UpvoteKitChangelogBadge(
  child: IconButton(
    tooltip: 'Changelog',
    onPressed: () => UpvoteKit.openChangelog(context),
    icon: const Icon(Icons.campaign_outlined),
  ),
)
```

`UpvoteKit.openChangelog` and `UpvoteKitChangelogView` mark those releases seen when the page posts `changelog-viewed`. The seen date stays on the device (`shared_preferences`), separate for each `baseUrl` and project. Until one is stored, only releases from the last 30 days count.

`UpvoteKit.unreadChangelog` is a `ValueListenable<int>` if you draw the count yourself. `UpvoteKit.unreadChangelogCount()` fetches and updates it. Both stay at 0 — and do not throw — when the SDK is not initialized, the board is unknown or down, or the device is offline.

Optional `backgroundColor` and `textColor` tint the bubble. They default to the theme's error colors.

## Theming

Pass `theme`, `style`, `locale`, `board`, `accentColor`, `secondaryColor`, and `backgroundColor` to `initialize`. They become embed query params (`theme`, `style`, `locale`, `board`, `accent`, `secondary`, and `bg` as hex without `#`). `style` is omitted when null so the project's saved preset is used (`classic`, `soft`, `editorial`, `brutalist`, `glass`, `studio`, `mono-white`, `mono-black`, `terminal`, `paper`, `neon`). `secondary` is the highlight color (voted state, active tab, changelog markers). `bg` is the page background; the embed derives card, text, and border colors from it and picks light or dark rendering from its luminance. Styles with a fixed mode (`mono-white`, `mono-black`, `terminal`, `paper`, `neon`) ignore `bg`. To follow the app theme, pass the color on the view:

```dart
UpvoteKitFeedbackView(
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
)
```

The view reloads when the color changes (e.g. the app switches to dark mode). `accent`, `secondary`, and `bg` are omitted when null. The SDK always adds `sdk=flutter`.

## Bridge contract

The embed posts JSON to the `UpvoteKitBridge` JavaScript channel:

```json
{"source":"upvotekit","type":"<type>","payload":{}}
```

Messages with `source != "upvotekit"` are ignored. Types: `ready`, `resize`, `navigate`, `close`, `feedback-created`, `vote-changed`, `auth-expired`, `open-external`, `unavailable`, `changelog-viewed`.

`changelog-viewed` carries `{ "latestPublishedAt": "<ISO>" | null }` — the newest published release, or `null` when the changelog is empty. The SDK stores that date (or the current time when it is null) and clears the what's-new badge. Your `onEvent` callback still receives the message.

`unavailable` carries an empty payload. Use `onUnavailable` to hide a Feedback entry point while the board is under maintenance. `ready` and `resize` are still delivered.

External URLs (different origin than `baseUrl`, or `open-external`) open via `url_launcher` in an external application.

## Example app

```bash
cd example
flutter run \
  --dart-define=UPVOTEKIT_BASE_URL=http://10.0.2.2:3100 \
  --dart-define=UPVOTEKIT_PROJECT=acme
```

Defaults: Android emulator `http://10.0.2.2:3100`, other platforms `http://localhost:3100`, project `acme`. The example enables cleartext HTTP (Android) and local networking ATS (iOS) for local dev.

## License

MIT
