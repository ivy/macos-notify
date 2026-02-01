# Plan: --activate should launch the app if not running

## Problem

In `AppDelegate.swift:93-115`, when the user clicks a notification with `--activate`, the handler:

1. Checks if the app is already running — if so, calls `app.activate()` (works)
2. If not running, calls `NSWorkspace.shared.openApplication(at:configuration:)` to launch it
3. Immediately calls `exit()` on line 115

`openApplication(at:configuration:)` is asynchronous. The process exits before the launch completes, so the target app never actually opens.

## Fix

In `Sources/macos-notify/AppDelegate.swift`, replace the fire-and-forget `openApplication` call with one that waits for completion before exiting. Use the async/await overload of `openApplication(at:configuration:)` and defer the `exit()` call until it resolves.

Wrap the activate block in a `Task` that awaits the launch, then calls `exit()` from within the task. Move the `completionHandler()` and `exit()` calls so they only run after the async launch finishes (or fails).

### Before (lines 93-115)

```swift
if let bundleID = userInfo["activate"] as? String {
    if let app = NSRunningApplication.runningApplications(
        withBundleIdentifier: bundleID
    ).first {
        app.activate()
    } else {
        let config = NSWorkspace.OpenConfiguration()
        if let appURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: bundleID
        ) {
            NSWorkspace.shared.openApplication(at: appURL, configuration: config)
        } else {
            ...
            success = false
        }
    }
}

completionHandler()
exit(success ? 0 : 1)
```

### After

```swift
if let bundleID = userInfo["activate"] as? String {
    if let app = NSRunningApplication.runningApplications(
        withBundleIdentifier: bundleID
    ).first {
        app.activate()
    } else {
        let config = NSWorkspace.OpenConfiguration()
        if let appURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: bundleID
        ) {
            Task {
                do {
                    try await NSWorkspace.shared.openApplication(
                        at: appURL, configuration: config
                    )
                } catch {
                    FileHandle.standardError.write(
                        Data("Failed to launch \(bundleID): \(error.localizedDescription)\n".utf8)
                    )
                    success = false
                }
                completionHandler()
                exit(success ? 0 : 1)
            }
            return
        } else {
            ...
            success = false
        }
    }
}

completionHandler()
exit(success ? 0 : 1)
```

The key change: when we need to launch an app, wrap in a `Task`, `await` the result, then exit. The early `return` prevents the synchronous `exit()` at the bottom from firing before the async launch completes.

## Files changed

| File | Change |
|------|--------|
| `Sources/macos-notify/AppDelegate.swift` | Await `openApplication` before exiting |

## Verification

1. Quit Calculator if running
2. `make run ARGS='--message "Click me" --activate "com.apple.calculator"'`
3. Click the notification — Calculator should launch
4. Repeat with Calculator already running — it should activate (come to foreground)
