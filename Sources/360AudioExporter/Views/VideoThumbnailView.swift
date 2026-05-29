import AppKit
import CryptoKit
import SwiftUI

struct VideoThumbnailView<Placeholder: View>: View {
    let asset: MediaAsset?
    let ffmpegPath: String
    let height: CGFloat
    let cornerRadius: CGFloat
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: NSImage?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .clipped()
            } else {
                placeholder()
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
            }

            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: asset?.url) {
            await loadThumbnail()
        }
    }

    @MainActor
    private func loadThumbnail() async {
        image = nil
        guard let asset, asset.fileType != .audio else { return }

        isLoading = true
        defer { isLoading = false }

        let thumbnailURL = await Task.detached(priority: .utility) {
            ThumbnailGenerator.generate(for: asset, ffmpegPath: ffmpegPath)
        }.value
        image = thumbnailURL.flatMap { NSImage(contentsOf: $0) }
    }
}

private enum ThumbnailGenerator {
    static func generate(for asset: MediaAsset, ffmpegPath: String) -> URL? {
        guard FileManager.default.fileExists(atPath: ffmpegPath) else { return nil }

        let cacheURL = thumbnailCacheURL(for: asset.url)
        if FileManager.default.fileExists(atPath: cacheURL.path) {
            return cacheURL
        }

        let seekTime = thumbnailSeekTime(for: asset)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = [
            "-hide_banner",
            "-loglevel", "error",
            "-ss", seekTime,
            "-i", asset.url.path,
            "-frames:v", "1",
            "-vf", "scale=640:-1",
            "-y",
            cacheURL.path
        ]

        let pipe = Pipe()
        process.standardError = pipe
        process.standardOutput = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let message = String(data: data, encoding: .utf8) ?? "Unknown ffmpeg thumbnail error"
                Logger.info("Thumbnail generation failed for \(asset.url.path): \(message)")
                return nil
            }
            return cacheURL
        } catch {
            Logger.info("Thumbnail generation failed for \(asset.url.path): \(error.localizedDescription)")
            return nil
        }
    }

    private static func thumbnailSeekTime(for asset: MediaAsset) -> String {
        guard let duration = asset.probe?.duration, duration > 1 else { return "0.1" }
        return String(format: "%.2f", min(max(duration * 0.1, 0.5), 10.0))
    }

    private static func thumbnailCacheURL(for url: URL) -> URL {
        let keySource = "\(url.path)|\(fileModificationStamp(for: url))"
        let digest = SHA256.hash(data: Data(keySource.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("360AudioExporter-thumbnails", isDirectory: true)
            .ensuringDirectoryExists()
            .appendingPathComponent("\(digest).jpg")
    }

    private static func fileModificationStamp(for url: URL) -> String {
        guard
            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
            let date = attrs[.modificationDate] as? Date
        else {
            return "unknown"
        }
        return "\(date.timeIntervalSince1970)"
    }
}

private extension URL {
    func ensuringDirectoryExists() -> URL {
        try? FileManager.default.createDirectory(at: self, withIntermediateDirectories: true)
        return self
    }
}
