# SwiftFormat

Add `.swiftformat` config to enforce consistent style automatically.

## Intent

Eliminate style bikeshedding in PRs. Contributors run `make fmt` and move on.

## Key decisions

- Indentation style (2-space vs 4-space) — needs a call
- Trailing commas: enabled
- Sort imports: enabled
- Rules should match what CI enforces via `swiftformat --lint`

## Files

- `.swiftformat` — rule configuration
