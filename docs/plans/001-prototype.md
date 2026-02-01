# Plan: macos-notify

A Swift command-line tool using `UNUserNotificationCenter` to send macOS notifications with click actions.

## Project Structure

```
macos-notify/
  Package.swift
  Sources/
    macos-notify/
      main.swift            # ParsableCommand, parse args, start NSApplication run loop
      AppDelegate.swift     # NSApplicationDelegate + UNUserNotificationCenterDelegate
      NotificationManager.swift  # Send, remove, list notifications
      CommandExecutor.swift # /bin/sh -c execution
  Resources/
    Info.plist              # CFBundleIdentifier + LSUIElement
```

## Key Design Decisions

**Info.plist embedding:** UNUserNotificationCenter requires a valid bundle identifier. Embed Info.plist into the binary via linker flag `-Wl,-sectcreate,__TEXT,__info_plist,Resources/Info.plist` in Package.swift (as proven by the tiny-usernotifications-example reference). Include `LSUIElement=YES` to prevent Dock icon.

**NSApplication run loop:** Required for UNUserNotificationCenterDelegate callbacks. Parse args before `app.run()` so `--help`/`--version` exit immediately. For notifications with action flags (`--execute`, `--open`, `--activate`), stay alive until user clicks; otherwise exit after delivery.

**Argument parsing:** Use `swift-argument-parser` (SPM dependency) for standard `--flag value` POSIX-style flags. It provides `--help`/`--version` for free.

**Platform target:** macOS 13+ (Swift tools version 6.0).

## Files to Create

### 1. `Package.swift`
- Executable target `macos-notify`
- macOS 13+ platform
- Dependency: `apple/swift-argument-parser` (~> 1.5)
- Linker settings for Info.plist embedding via `unsafeFlags`

### 2. `Resources/Info.plist`
- `CFBundleIdentifier`: `com.github.ivy.macos-notify`
- `LSUIElement`: `YES` (no Dock icon)
- `CFBundleShortVersionString`: `0.1.0`

### 3. `Sources/macos-notify/main.swift`
- Define `MacOSNotify: ParsableCommand` with `@Option`/`@Flag` properties:
  `--message`, `--title`, `--subtitle`, `--sound`, `--group`, `--remove`, `--list`, `--activate`, `--open`, `--execute`
- Read from stdin if no `--message` and stdin is piped (`isatty(STDIN_FILENO) == 0`)
- Validate at least one of message, remove, or list is provided
- Create `NSApplication.shared`, set `AppDelegate`, call `app.run()`

### 4. `Sources/macos-notify/AppDelegate.swift`
- `applicationDidFinishLaunching`: set delegate on `UNUserNotificationCenter.current()`, request authorization, then dispatch to action handler
- Action handler: route to send/remove/list based on parsed options
- `willPresent`: return `[.banner, .list, .sound]` to show notification even when frontmost
- `didReceive`: extract userInfo, run `--execute` command, open `--open` URL, activate `--activate` app, then `exit(0)` or `exit(1)`
- After delivery: if no action flags set, `exit(0)` immediately; if action flags present, stay alive for click callback

### 5. `Sources/macos-notify/NotificationManager.swift`
- `deliverNotification(options:completion:)`:
  - Build `UNMutableNotificationContent` (title, subtitle, body, sound)
  - Store action metadata (`command`, `open`, `bundleID`) in `userInfo`
  - Use `--group` as request identifier (enables replacement of old notifications); UUID if no group
  - `UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)` for near-immediate delivery
- `removeNotifications(groupID:)`: remove by identifier, or all if "ALL"
- `listNotifications(groupID:completion:)`: `getDeliveredNotifications`, filter, print tab-separated

### 6. `Sources/macos-notify/CommandExecutor.swift`
- `run(_ command: String) -> Bool`
- `Process()` with `/bin/sh -c <command>`
- Capture stdout/stderr, print output, return `terminationStatus == 0`

## Exit Codes

| Scenario | Code |
|---|---|
| Success (delivered, listed, removed, actions succeeded) | 0 |
| Error (missing args, delivery failure, action failure) | 1 |

## Limitations vs terminal-notifier

- **No `--ignore-dnd`**: UNUserNotificationCenter respects Do Not Disturb; no bypass available
- **No `--sender` icon spoofing**: notification always shows as macos-notify's bundle; `--sender` flag will be omitted
- **`--app-icon`/`--content-image`**: can support local files via `UNNotificationAttachment`, but remote URLs would need downloading; defer to phase 2
- **First-run authorization prompt**: macOS will ask user to allow notifications on first use; unavoidable with modern API

## Verification

1. `swift build` compiles without errors
2. `swift run macos-notify --help` prints usage and exits
3. `swift run macos-notify --title "Test" --message "Hello"` shows a notification banner
4. `swift run macos-notify --message "Click me" --execute "echo clicked > /tmp/macos-notify-test.txt"` — click the notification, verify `/tmp/macos-notify-test.txt` was created
5. `swift run macos-notify --message "Grouped" --group test1` then `swift run macos-notify --list test1` shows the notification
6. `swift run macos-notify --remove test1` removes it
7. `echo "piped message" | swift run macos-notify` sends notification with piped content
