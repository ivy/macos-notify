# Smoke Tests

Run each test one at a time. After each command, use AskUserQuestion to prompt the user with "Passed" / "Failed" options before moving to the next test. If the user selects "Failed", ask what happened. Rebuild between tests only if source files changed.

Before starting, run `make` to ensure the app bundle is built and up to date.

Use `make run ARGS="..."` to execute each test.

## 1. Basic notification

```
make run ARGS='--title "Test" --message "Hello from macos-notify"'
```

Expected: notification banner appears with title "Test" and body "Hello from macos-notify". Plays the default sound. Clicking the notification does not error. Process exits 0.

## 2. Subtitle

```
make run ARGS='--title "Test" --subtitle "Subtitle here" --message "With subtitle"'
```

Expected: banner shows title, subtitle, and body on three lines. Plays the default sound. Clicking the notification does not error. Process exits 0.

## 3. Message-only (no title)

```
make run ARGS='--message "Body only, no title"'
```

Expected: banner appears with body text only. Plays the default sound. Clicking the notification does not error. Process exits 0.

## 4. Stdin pipe

```
echo "piped message" | make run
```

Expected: banner appears with body "piped message". Plays the default sound. Clicking the notification does not error. Process exits 0.

## 5. Custom sound

```
make run ARGS='--title "Sound" --message "This should play Submarine" --sound Submarine'
```

Expected: notification appears and plays the Submarine sound (distinct from the default sound). Process exits 0.

## 6. Grouped notifications (send)

```
make run ARGS='--title "Group" --message "First grouped" --group test-group'
make run ARGS='--title "Group" --message "Second grouped" --group test-group'
make run ARGS='--title "Group" --message "Third grouped" --group test-group'
```

Expected: all three banners appear grouped together in Notification Center. Each process exits 0.

Known issue: see `docs/issues/grouped-notifications-not-grouping.md`.

## 7. List notifications

```
make run ARGS='--list'
```

Expected: prints tab-separated rows (`group\ttitle\tsubtitle\tmessage`) of delivered notifications to stdout. Should include the "test-group" notification from the previous step (only the last send, since same-group notifications replace each other). Process exits 0.

## 8. List filtered by group

```
make run ARGS='--list --group test-group'
```

Expected: prints only the "test-group" notification. Process exits 0.

## 9. Group replacement

```
make run ARGS='--title "Group" --message "Replaced grouped" --group test-group'
```

Expected: the previous "test-group" notification in Notification Center is replaced with this one. Process exits 0.

## 10. Remove by group

```
make run ARGS='--remove test-group'
```

Expected: the "test-group" notification disappears from Notification Center. Process exits 0. Verify with `make run ARGS='--list'` — should no longer appear.

## 11. Remove all

Send a couple of notifications first, then remove all:

```
make run ARGS='--title "A" --message "One" --group a'
make run ARGS='--title "B" --message "Two" --group b'
make run ARGS='--remove ALL'
```

Expected: all notifications cleared from Notification Center. Process exits 0.

## 12. Execute on click

```
make run ARGS='--message "Click me to execute" --execute "echo clicked > /tmp/macos-notify-test.txt"'
```

Expected: banner appears. Process stays alive. Click the notification. After clicking, check that `/tmp/macos-notify-test.txt` contains "clicked". Process should exit 0.

Clean up: `rm /tmp/macos-notify-test.txt`

## 13. Open URL on click

```
make run ARGS='--message "Click to open URL" --open "https://example.com"'
```

Expected: banner appears. Process stays alive. Click the notification. Default browser opens https://example.com. Process exits 0.

## 14. Activate app on click

```
make run ARGS='--message "Click to activate Calculator" --activate "com.apple.calculator"'
```

Expected: banner appears. Process stays alive. Click the notification. Calculator app launches or comes to foreground. Process exits 0.

## 15. Validation: no arguments

```
make run 2>&1
```

Expected: prints usage error about missing message/remove/list. Exits non-zero.

## 16. Help

```
make run ARGS='--help'
```

Expected: prints full usage text with all flags documented. Exits 0.

## 17. Version

```
make run ARGS='--version'
```

Expected: prints `0.1.0`. Exits 0.
