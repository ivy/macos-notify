import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate, @unchecked Sendable {
    var options: NotificationOptions?
    var removeGroup: String?
    var listGroup: String?
    var shouldList = false
    var hasActions = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                FileHandle.standardError.write(
                    Data("Authorization error: \(error.localizedDescription)\n".utf8)
                )
                exit(1)
            }

            if !granted {
                FileHandle.standardError.write(
                    Data("Notification permission denied.\n".utf8)
                )
                exit(1)
            }

            self.dispatchAction()
        }
    }

    private func dispatchAction() {
        if let group = removeGroup {
            NotificationManager.removeNotifications(groupID: group)
            exit(0)
        }

        if shouldList {
            NotificationManager.listNotifications(groupID: listGroup) {
                exit(0)
            }
            return
        }

        guard let options = options else {
            FileHandle.standardError.write(Data("No notification options provided.\n".utf8))
            exit(1)
        }

        NotificationManager.deliverNotification(options: options) { success in
            if !success {
                exit(1)
            }
            if !self.hasActions {
                // Brief delay to allow the notification to appear
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    exit(0)
                }
            }
            // If actions are set, stay alive waiting for user click
        }
    }

    // Show notification banner even when app is frontmost
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    // Handle notification click
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        var success = true

        if let command = userInfo["command"] as? String {
            success = CommandExecutor.run(command) && success
        }

        if let urlString = userInfo["open"] as? String,
           let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }

        if let bundleID = userInfo["activate"] as? String {
            if let app = NSRunningApplication.runningApplications(
                withBundleIdentifier: bundleID
            ).first {
                app.activate()
            } else {
                // Try to launch the app
                let config = NSWorkspace.OpenConfiguration()
                if let appURL = NSWorkspace.shared.urlForApplication(
                    withBundleIdentifier: bundleID
                ) {
                    NSWorkspace.shared.openApplication(at: appURL, configuration: config)
                } else {
                    FileHandle.standardError.write(
                        Data("Could not find application with bundle ID: \(bundleID)\n".utf8)
                    )
                    success = false
                }
            }
        }

        completionHandler()
        exit(success ? 0 : 1)
    }
}
