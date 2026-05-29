import Foundation

public enum FFmpegEvent: Hashable {
    case log(String)
    case progress(currentTime: Double, speed: String?)
}

public final class FFmpegService {
    private var process: Process?
    private let lock = NSLock()
    
    public init() {}
    
    public func cancel() {
        lock.lock()
        defer { lock.unlock() }
        if let process = process, process.isRunning {
            Logger.info("Terminating running ffmpeg process.")
            process.terminate()
        }
    }
    
    public func run(arguments: [String], ffmpegPath: String) -> AsyncThrowingStream<FFmpegEvent, Error> {
        AsyncThrowingStream { continuation in
            lock.lock()
            guard FileManager.default.fileExists(atPath: ffmpegPath) else {
                lock.unlock()
                continuation.finish(throwing: NSError(domain: "FFmpegService", code: 404, userInfo: [NSLocalizedDescriptionKey: "ffmpeg binary not found at \(ffmpegPath)"]))
                return
            }
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: ffmpegPath)
            process.arguments = arguments
            
            let errPipe = Pipe()
            process.standardError = errPipe
            
            // Redirect standard output to avoid polluting or blocking
            let outPipe = Pipe()
            process.standardOutput = outPipe
            
            self.process = process
            lock.unlock()
            
            do {
                Logger.info("Starting ffmpeg with arguments: \(arguments.joined(separator: " "))")
                try process.run()
            } catch {
                continuation.finish(throwing: error)
                return
            }
            
            // Read stderr stream in a background task. ffmpeg updates progress with both \n and \r.
            let errHandle = errPipe.fileHandleForReading
            Task.detached(priority: .background) {
                var buffer = Data()
                
                while true {
                    let data = errHandle.availableData
                    if data.isEmpty {
                        break
                    }
                    buffer.append(data)
                    
                    while let separatorRange = buffer.firstLineSeparatorRange() {
                        let lineData = buffer.subdata(in: 0..<separatorRange.lowerBound)
                        buffer.removeSubrange(0..<separatorRange.upperBound)
                        Self.emit(lineData: lineData, continuation: continuation)
                    }
                }

                if !buffer.isEmpty {
                    Self.emit(lineData: buffer, continuation: continuation)
                }
                
                process.waitUntilExit()
                
                let status = process.terminationStatus
                Logger.info("ffmpeg process finished with exit code \(status)")
                
                if status == 0 || status == 255 { // 255 is typical exit code when SIGTERM/terminate is called
                    continuation.finish()
                } else {
                    let remainingErr = errHandle.readDataToEndOfFile()
                    let errStr = String(data: remainingErr, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    continuation.finish(throwing: NSError(domain: "FFmpegService", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "ffmpeg failed with exit code \(status). \(errStr)"]))
                }
            }
        }
    }

    private static func emit(lineData: Data, continuation: AsyncThrowingStream<FFmpegEvent, Error>.Continuation) {
        guard let line = String(data: lineData, encoding: .utf8) else { return }
        let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanLine.isEmpty else { return }

        continuation.yield(.log(cleanLine))

        let parts = cleanLine.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var timeStr: String?
        var speedStr: String?

        for part in parts {
            if part.hasPrefix("time=") {
                timeStr = String(part.dropFirst(5))
            } else if part.hasPrefix("speed=") {
                speedStr = String(part.dropFirst(6))
            }
        }

        if let timeStr = timeStr, let seconds = TimecodeParser.parse(timecode: timeStr) {
            continuation.yield(.progress(currentTime: seconds, speed: speedStr))
        }
    }
}

private extension Data {
    func firstLineSeparatorRange() -> Range<Data.Index>? {
        let newline = firstRange(of: Data([0x0A]))
        let carriageReturn = firstRange(of: Data([0x0D]))

        switch (newline, carriageReturn) {
        case let (lhs?, rhs?):
            return lhs.lowerBound < rhs.lowerBound ? lhs : rhs
        case let (lhs?, nil):
            return lhs
        case let (nil, rhs?):
            return rhs
        case (nil, nil):
            return nil
        }
    }
}
