import AppKit
import ArgumentParser
import Foundation

struct MacOSNotify: @preconcurrency ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "macos-notify",
        abstract: "Send macOS notifications with click actions.",
        version: "0.1.0"
    )

    @Option(name: .long, help: "Notification title.")
    var title: String?

    @Option(name: .long, help: "Notification subtitle.")
    var subtitle: String?

    @Option(name: [.short, .long], help: "Notification message body.")
    var message: String?

    @Option(name: .long, help: "Sound name (use 'default' for system sound).")
    var sound: String?

    @Option(name: .long, help: "Group ID for notification replacement/lookup.")
    var group: String?

    @Option(name: .long, help: "Remove a notification by group ID (use 'ALL' to remove all).")
    var remove: String?

    @Flag(name: .long, help: "List delivered notifications.")
    var list = false

    @Option(name: .long, help: "Activate an app by bundle ID when notification is clicked.")
    var activate: String?

    @Option(name: .long, help: "Open a URL when notification is clicked.")
    var open: String?

    @Option(name: .long, help: "Execute a shell command when notification is clicked.")
    var execute: String?

    func validate() throws {
        if remove == nil && !list && message == nil && !stdinHasData() {
            throw ValidationError(
                "Provide --message, pipe data to stdin, use --remove, or use --list."
            )
        }
    }

    @MainActor
    func run() throws {
        let delegate = AppDelegate()

        if let remove = remove {
            delegate.removeGroup = remove
        } else if list {
            delegate.shouldList = true
            delegate.listGroup = group
        } else {
            let body: String
            if let message = message {
                body = message
            } else {
                // Read from stdin
                body = readLine(strippingNewline: false)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    ?? ""

                guard !body.isEmpty else {
                    throw ValidationError("No message provided via --message or stdin.")
                }
            }

            let hasActions = execute != nil || open != nil || activate != nil

            delegate.options = NotificationOptions(
                title: title,
                subtitle: subtitle,
                message: body,
                sound: sound,
                group: group,
                execute: execute,
                open: open,
                activate: activate
            )
            delegate.hasActions = hasActions
        }

        let app = NSApplication.shared
        app.delegate = delegate
        app.run()
    }
}

private func stdinHasData() -> Bool {
    return isatty(STDIN_FILENO) == 0
}

MacOSNotify.main()
