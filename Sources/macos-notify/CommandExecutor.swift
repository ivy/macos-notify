import Foundation

enum CommandExecutor {
    @discardableResult
    static func run(_ command: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            FileHandle.standardError.write(
                Data("Failed to execute command: \(error.localizedDescription)\n".utf8)
            )
            return false
        }

        if let output = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8),
           !output.isEmpty {
            print(output, terminator: "")
        }

        if let errOutput = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8),
           !errOutput.isEmpty {
            FileHandle.standardError.write(Data(errOutput.utf8))
        }

        return process.terminationStatus == 0
    }
}
