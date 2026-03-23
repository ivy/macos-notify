# Test Target

Add a test target to `Package.swift` and scaffold initial tests.

## Intent

Signal that tests belong here. Infrastructure first, coverage over time.

## Testable logic (even with side-effectful code)

- Argument parsing and validation (message required unless stdin/remove/list)
- `NotificationOptions` construction from CLI flags
- `CommandExecutor.run` with simple shell commands

## Files

- `Package.swift` — add test target
- `Tests/macos-notifyTests/` — test scaffolding
