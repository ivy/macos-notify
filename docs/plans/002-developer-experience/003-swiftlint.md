# SwiftLint

Add `.swiftlint.yml` for static analysis beyond what SwiftFormat and Swift 6 catch.

## Intent

Catch code smells: force unwraps, long functions, high complexity, leftover TODOs.
Swift 6 strict concurrency handles thread safety; SwiftLint handles everything else.

## Approach

- Start with a tight, opinionated ruleset
- Disable noisy rules that generate false positives on small codebases
- Exclude `.build/` and `reference/` directories

## Files

- `.swiftlint.yml` — rule configuration
