import Foundation
import UserNotifications

struct NotificationOptions: Sendable {
    var title: String?
    var subtitle: String?
    var message: String
    var sound: String?
    var group: String?
    var execute: String?
    var open: String?
    var activate: String?
}

enum NotificationManager {
    static func deliverNotification(
        options: NotificationOptions,
        completion: @escaping @Sendable (Bool) -> Void
    ) {
        let content = UNMutableNotificationContent()

        if let title = options.title {
            content.title = title
        }
        if let subtitle = options.subtitle {
            content.subtitle = subtitle
        }
        content.body = options.message

        if let sound = options.sound {
            if sound == "default" {
                content.sound = .default
            } else {
                content.sound = UNNotificationSound(named: UNNotificationSoundName(sound))
            }
        } else {
            content.sound = .default
        }

        var userInfo: [String: String] = [:]
        if let command = options.execute {
            userInfo["command"] = command
        }
        if let url = options.open {
            userInfo["open"] = url
        }
        if let bundleID = options.activate {
            userInfo["activate"] = bundleID
        }
        content.userInfo = userInfo

        if let group = options.group {
            content.threadIdentifier = group
        }

        let identifier = options.group ?? UUID().uuidString
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                FileHandle.standardError.write(
                    Data("Failed to deliver notification: \(error.localizedDescription)\n".utf8)
                )
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    static func removeNotifications(groupID: String) {
        let center = UNUserNotificationCenter.current()
        if groupID == "ALL" {
            center.removeAllDeliveredNotifications()
            center.removeAllPendingNotificationRequests()
        } else {
            center.removeDeliveredNotifications(withIdentifiers: [groupID])
            center.removePendingNotificationRequests(withIdentifiers: [groupID])
        }
    }

    static func listNotifications(
        groupID: String?,
        completion: @escaping @Sendable () -> Void
    ) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let filtered: [UNNotification]
            if let groupID = groupID {
                filtered = notifications.filter { $0.request.identifier == groupID }
            } else {
                filtered = notifications
            }

            for notification in filtered {
                let content = notification.request.content
                let id = notification.request.identifier
                print("\(id)\t\(content.title)\t\(content.subtitle)\t\(content.body)")
            }

            completion()
        }
    }
}
