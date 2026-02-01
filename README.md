# macos-notify

A command-line tool for sending macOS notifications with click actions.

Built with Swift and `UNUserNotificationCenter` (available since macOS 10.14) — the modern macOS notification framework that replaces `NSUserNotification`. Apple deprecated `NSUserNotification` in macOS 11.0, and while the API is still present, it no longer receives fixes. Tools built on it (like [terminal-notifier](https://github.com/julienXX/terminal-notifier)) still deliver notifications on current macOS versions but have broken user interactions — clicking notifications may not trigger actions, and a spurious "Show" button can appear. `macos-notify` is a from-scratch alternative for anyone who needs a reliable, scriptable notification CLI on modern macOS.

## Usage

```
macos-notify --title "Hello" --message "World"
echo "piped message" | macos-notify
macos-notify --message "Click me" --execute "echo clicked"
macos-notify --list
macos-notify --remove ALL
```

Run `macos-notify --help` for all options.

## Comparison with terminal-notifier

| Feature | macos-notify | terminal-notifier |
|---|---|---|
| `--message` | Yes | Yes |
| `--title` | Yes | Yes |
| `--subtitle` | Yes | Yes |
| `--sound` | Yes | Yes |
| `--group` | Yes | Yes |
| `--list` | Yes | Yes |
| `--remove` | Yes | Yes |
| `--activate` | Yes | Yes |
| `--open` | Yes | Yes |
| `--execute` | Yes | Yes |
| `--app-icon` | Planned | Yes |
| `--content-image` | Planned | Yes |
| `--sender` | No (see below) | Yes |
| `--ignore-dnd` | No (see below) | Yes |
| Stdin pipe | Yes | Yes |
| Framework | `UNUserNotificationCenter` (macOS 10.14+) | `NSUserNotification` (deprecated in macOS 11.0) |
| Reliable click actions | Yes | No (broken on recent macOS) |
| Dock icon | Hidden (`LSUIElement`) | Hidden |
| First-run auth prompt | Yes (required by modern API) | No |

### Why not terminal-notifier?

terminal-notifier is built on `NSUserNotification`, which Apple deprecated in macOS 11.0. The API is still present but no longer maintained — on recent macOS versions, terminal-notifier can deliver notifications but user interactions are unreliable (click actions don't fire, a spurious "Show" button appears). macos-notify uses `UNUserNotificationCenter`, the actively supported notification framework, and will continue to work correctly as macOS evolves.

### What macos-notify doesn't support

- **`--sender`**: `UNUserNotificationCenter` ties notifications to the app's own bundle identifier. There is no public API to display another app's icon.
- **`--ignore-dnd`**: `UNUserNotificationCenter` respects Focus/Do Not Disturb. There is no public API to bypass it. (`NSUserNotification` allowed this because it predated Focus modes.)

## Building

```
make
```

The app bundle is placed at `.build/macos-notify.app`.

## Requirements

- macOS 13+
- Swift 6.0+
