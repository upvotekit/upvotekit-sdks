## 0.1.0

* Initial Flutter SDK: thin webview embeds for feedback, roadmap, changelog, and submit.
* Optional `UpvoteKitStyle` on `initialize` and the URL builder. Omitted from the embed URL when null so the project branding preset is used.
* Optional `secondaryColor` and `backgroundColor` on `initialize` and the URL builder. Sent as `secondary` and `bg` (hex without `#`) and omitted when null.
* Per-view `backgroundColor` and `secondaryColor` on embed views. The view reloads when the resolved color changes so it can follow the app's light/dark theme.
* Bridge message `unavailable` (empty payload) when a board is under maintenance. Views and `UpvoteKit.open*` accept `onUnavailable` so the host app can hide its Feedback button. `ready` and `resize` are still posted.
* `baseUrl` is optional on `UpvoteKitConfig` and `UpvoteKit.initialize`. It defaults to `https://upvotekit.com` (`UpvoteKitConfig.defaultBaseUrl`).
