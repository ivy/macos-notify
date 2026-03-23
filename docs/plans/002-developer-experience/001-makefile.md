# Makefile Overhaul

Replace the current Makefile with a self-documenting, arch-agnostic build system.

## Targets

- `build` (default) — debug build via `swift build`
- `release` — optimized build
- `bundle` — create codesigned `.app` bundle
- `run ARGS="..."` — build and run with arguments
- `install` / `uninstall` — install binary to `PREFIX` (default `/usr/local`)
- `fmt` — auto-format source with SwiftFormat
- `lint` — run SwiftLint
- `test` — run test suite
- `check` — run everything CI runs (fmt check + lint + build + test)
- `clean` — remove build artifacts
- `help` — print all targets with descriptions

## Fixes

- Remove hardcoded `arm64-apple-macosx` path; use `swift build --show-bin-path`
- Make `BINARY` discovery dynamic so it works on Intel and Apple Silicon
