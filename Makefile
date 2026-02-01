APP_NAME := macos-notify
BUILD_DIR := .build
APP_BUNDLE := $(BUILD_DIR)/$(APP_NAME).app
BINARY := $(BUILD_DIR)/arm64-apple-macosx/debug/$(APP_NAME)

.PHONY: build clean run

build: $(APP_BUNDLE)

$(APP_BUNDLE): $(BINARY)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	cp $(BINARY) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	cp Resources/Info.plist $(APP_BUNDLE)/Contents/Info.plist
	codesign -f -s - $(APP_BUNDLE)

$(BINARY): Sources/macos-notify/*.swift Package.swift Resources/Info.plist
	swift build

run: $(APP_BUNDLE)
	$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME) $(ARGS)

clean:
	swift package clean
	rm -rf $(APP_BUNDLE)
