# Fullscreen Web App

Turn any website into a truly fullscreen iPhone or iPad app: no status bar (clock, battery), no Safari bars, and an auto-hiding home indicator.

Safari's "Add to Home Screen", PWA `display: fullscreen` and Web Clip profiles all keep the status bar on iOS. WebKit treats `fullscreen` as `standalone`. This template wraps the site in a small native app that can hide it.

## Make an app without a Mac (GitHub Actions)

1. Click **Use this template** → **Create a new repository**.
2. In your new repo, open **Actions** → **Build IPA** → **Run workflow**.
3. Enter the site URL and the app name, then run it.
4. Download the `WebApp-ipa` artifact when the run finishes, and unzip it to get `WebApp.ipa`.
5. Install the `.ipa` with [SideStore](https://sidestore.io) or [AltStore](https://altstore.io). They sign it with your Apple ID.

Each run uses a bundle ID based on the app name, so you can install several wrapped sites side by side. Actions minutes are free on public repos. Private repos use macOS minutes at a 10x rate.

## Make an app on a Mac (Xcode)

1. Install XcodeGen: `brew install xcodegen`.
2. Edit the three `EDIT` settings in `project.yml`: `WEB_APP_URL`, `APP_DISPLAY_NAME` and `PRODUCT_BUNDLE_IDENTIFIER`.
3. Run `xcodegen generate`, then open `WebApp.xcodeproj`.
4. Select your team under **Signing & Capabilities**, pick your device and click **Run**.

To build an unsigned `.ipa` locally instead, run:

```sh
WEB_APP_URL=https://example.com APP_DISPLAY_NAME="My App" scripts/build-ipa.sh
```

## Custom icon

Replace `WebApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png` with any opaque 1024×1024 PNG. `scripts/make-icon.swift` draws the default icon.

## How it works

The whole app is [`WebApp/WebApp.swift`](WebApp/WebApp.swift): one full-screen `WKWebView`.

| Feature | How |
|---|---|
| No status bar | `.statusBarHidden(true)` plus `UIStatusBarHidden`. `UIRequiresFullScreen` turns off iPad multitasking, because iPadOS keeps the status bar in resizable windows. |
| No home indicator | `.persistentSystemOverlays(.hidden)` hides it until you touch the bottom edge. |
| Sites that need Safari | `applicationNameForUserAgent` adds a Safari token to the user agent. |
| Sites that need an installed PWA | A script injected at page start makes `navigator.standalone` return `true` and `matchMedia('(display-mode: standalone)')` match. CSS `@media (display-mode)` rules still see the real mode. |
| Video and audio | Inline playback, with no tap needed to start. |
| Sign-in pop-ups | Pop-ups open in the same view. Swipe back to return. |
| Debugging | `isInspectable` lets you use Safari → Develop on a Mac. |

## Limits

- A free Apple ID signs apps for 7 days. SideStore and AltStore refresh them. A paid Apple Developer account signs them for a year.
- There is no address bar or reload button. Swipe from the left edge to go back.
- Some sites block embedded web views (for example, Google sign-in). Those sites will not work.
- Only wrap sites you are allowed to use this way. Each site's own terms still apply.

## License

[MIT](LICENSE)
