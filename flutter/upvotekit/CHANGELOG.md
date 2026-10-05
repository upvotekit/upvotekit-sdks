## 0.2.0

* What's new badge: `UpvoteKitChangelogBadge` wraps any widget with an unread-release count. `UpvoteKit.unreadChangelogCount()` and `UpvoteKit.unreadChangelog` expose the same count.
* Opening the changelog (`UpvoteKitChangelogView` or `UpvoteKit.openChangelog`) marks it seen when the embed posts `changelog-viewed`. The seen date is stored on the device, scoped by base URL and project. With no seen date, only releases from the last 30 days count. Counts above 9 show as "9+".
* Bridge event `changelog-viewed` (`latestPublishedAt`).

## 0.1.0

* Initial Flutter SDK: thin webview embeds for feedback, roadmap, changelog, and submit.
* Optional `UpvoteKitStyle` on `initialize` and the URL builder. Omitted from the embed URL when null so the project branding preset is used.
* Optional `secondaryColor` and `backgroundColor` on `initialize` and the URL builder. Sent as `secondary` and `bg` (hex without `#`) and omitted when null.
* Per-view `backgroundColor` and `secondaryColor` on embed views. The view reloads when the resolved color changes so it can follow the app's light/dark theme.
* Bridge message `unavailable` (empty payload) when a board is under maintenance. Views and `UpvoteKit.open*` accept `onUnavailable` so the host app can hide its Feedback button. `ready` and `resize` are still posted.
* `baseUrl` is optional on `UpvoteKitConfig` and `UpvoteKit.initialize`. It defaults to `https://upvotekit.com` (`UpvoteKitConfig.defaultBaseUrl`).
