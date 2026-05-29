import Foundation
import Combine

public struct CompletedExportResult: Identifiable, Hashable {
    public let id: UUID
    public let sourceFileName: String
    public let outputURL: URL
    public let validationResult: ValidationResult

    public init(id: UUID = UUID(), sourceFileName: String, outputURL: URL, validationResult: ValidationResult) {
        self.id = id
        self.sourceFileName = sourceFileName
        self.outputURL = outputURL
        self.validationResult = validationResult
    }
}

@MainActor
public final class AppState: ObservableObject {
    public static let maxBatchSize = 20

    @Published var selectedMode: ExportMode = .export360Video
    
    // Mode 1 assets
    @Published var inputVideos: [MediaAsset] = []
    public var inputVideo: MediaAsset? { inputVideos.first }
    
    // Mode 2 assets
    @Published var renderedVideo: MediaAsset?
    @Published var spatialAudioSource: MediaAsset?
    
    // App Settings
    @Published var exportSettings: ExportSettings = .default
    @Published var attachAudioMode: AttachAudioMode = .replace
    
    // Running states
    @Published var currentJob: ExportJob?
    @Published var lastCompletedJob: ExportJob?
    @Published var exportProgress: ExportProgress?
    @Published var isExporting: Bool = false
    @Published var validationResult: ValidationResult?
    @Published var completedExportResults: [CompletedExportResult] = []
    @Published var showValidationDetails: Bool = false
    @Published var errorMessage: String?
    @Published var currentBatchIndex: Int = 0
    @Published var batchTotal: Int = 0
    
    // Executable settings paths
    @Published var ffmpegPath: String
    @Published var ffprobePath: String
    
    private let ffprobeService: MediaProbeService
    private let exportEngine: ExportEngine
    private let metadataService: MetadataService
    private var exportTask: Task<Void, Never>?
    
    public init(
        ffprobeService: MediaProbeService = FFprobeService(),
        exportEngine: ExportEngine = LiveExportEngine(),
        metadataService: MetadataService = MetadataService()
    ) {
        self.ffprobeService = ffprobeService
        self.exportEngine = exportEngine
        self.metadataService = metadataService
        
        // Auto-detect default binary paths or load from UserDefaults
        let savedFfmpeg = UserDefaults.standard.string(forKey: "ffmpegPath")
        let savedFfprobe = UserDefaults.standard.string(forKey: "ffprobePath")
        
        self.ffmpegPath = Self.validSavedPath(savedFfmpeg) ?? Self.findDefaultBinary(name: "ffmpeg")
        self.ffprobePath = Self.validSavedPath(savedFfprobe) ?? Self.findDefaultBinary(name: "ffprobe")
    }
    
    public func saveBinaryPaths() {
        UserDefaults.standard.set(ffmpegPath, forKey: "ffmpegPath")
        UserDefaults.standard.set(ffprobePath, forKey: "ffprobePath")
    }
    
    private static func findDefaultBinary(name: String) -> String {
        if let bundledPath = Bundle.main.path(forResource: name, ofType: nil), FileManager.default.isExecutableFile(atPath: bundledPath) {
            return bundledPath
        }

        let commonPaths = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/usr/bin/\(name)"
        ]
        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return "/opt/homebrew/bin/\(name)"
    }

    private static func validSavedPath(_ path: String?) -> String? {
        guard let path, FileManager.default.isExecutableFile(atPath: path) else { return nil }
        return path
    }
    
    // Validate binaries exist
    public var isFfmpegAvailable: Bool {
        FileManager.default.fileExists(atPath: ffmpegPath)
    }
    
    public var isFfprobeAvailable: Bool {
        FileManager.default.fileExists(atPath: ffprobePath)
    }

    // Core business actions
    public func probeAsset(url: URL, mode: ExportMode, isSecondary: Bool = false, appendToBatch: Bool = false) async {
        guard isFfprobeAvailable else {
            self.errorMessage = "ffprobe was not found. Open Settings and choose the correct binary."
            return
        }
        
        do {
            let probe = try await ffprobeService.probe(url: url, ffprobePath: ffprobePath)
            let fileName = url.lastPathComponent
            
            // Deduce file type
            var type: MediaFileType = .unknown
            if !probe.videoStreams.isEmpty {
                type = probe.isLikely360 ? .video360 : .normalVideo
            } else if !probe.audioStreams.isEmpty {
                type = .audio
            }
            
            let asset = MediaAsset(url: url, fileName: fileName, fileType: type, probe: probe)
            
            if mode == .export360Video {
                if appendToBatch {
                    appendInputVideo(asset)
                } else {
                    self.inputVideos = [asset]
                }
            } else {
                if isSecondary {
                    self.spatialAudioSource = asset
                } else {
                    self.renderedVideo = asset
                }
            }
        } catch {
            self.errorMessage = "Could not read media metadata: \(error.localizedDescription)"
        }
    }

    public func probeAssets(urls: [URL], mode: ExportMode, appendToBatch: Bool = false) async {
        guard mode == .export360Video else {
            if let url = urls.first {
                await probeAsset(url: url, mode: mode)
            }
            return
        }

        if !appendToBatch {
            inputVideos = []
        }

        let remainingSlots = max(0, Self.maxBatchSize - inputVideos.count)
        let allowedURLs = Array(urls.prefix(remainingSlots))
        if urls.count > allowedURLs.count {
            errorMessage = "Only \(Self.maxBatchSize) videos can be queued at once. Extra files were ignored."
        }

        for url in allowedURLs {
            await probeAsset(url: url, mode: mode, appendToBatch: true)
        }
    }

    public func removeInputVideo(id: UUID) {
        inputVideos.removeAll { $0.id == id }
    }

    public func clearInputVideos() {
        inputVideos = []
    }
    
    public func clearAsset(mode: ExportMode, isSecondary: Bool = false) {
        if mode == .export360Video {
            self.inputVideos = []
        } else {
            if isSecondary {
                self.spatialAudioSource = nil
            } else {
                self.renderedVideo = nil
            }
        }
    }
    
    public func startExport() {
        guard isFfmpegAvailable else {
            self.errorMessage = "ffmpeg was not found. Open Settings and choose the correct binary."
            return
        }

        guard let jobs = makeExportJobs(), !jobs.isEmpty else {
            self.errorMessage = selectedMode == .export360Video ? "Choose a 360° input video first." : "Choose both a finished video and an original ambisonic audio source."
            return
        }
        
        self.validationResult = nil
        self.completedExportResults = []
        self.showValidationDetails = false
        self.isExporting = true
        self.errorMessage = nil
        self.currentBatchIndex = 0
        self.batchTotal = jobs.count
        
        exportTask = Task {
            do {
                for (index, job) in jobs.enumerated() {
                    try Task.checkCancellation()
                    self.currentBatchIndex = index + 1
                    self.currentJob = job

                    let progressStream = exportEngine.start(job: job, ffmpegPath: ffmpegPath)
                    for try await progress in progressStream {
                        try Task.checkCancellation()
                        self.exportProgress = progress
                    }
                    try Task.checkCancellation()

                    self.exportProgress = ExportProgress(
                        percentage: 1.0,
                        currentTime: nil,
                        totalDuration: nil,
                        estimatedRemainingSeconds: 0,
                        speed: nil,
                        stage: "Validating",
                        message: "Checking the exported file with ffprobe..."
                    )

                    let result = try await metadataService.validate(url: job.outputURL, expectedJob: job, ffprobePath: ffprobePath)
                    self.validationResult = result
                    self.lastCompletedJob = job
                    self.completedExportResults.append(CompletedExportResult(
                        sourceFileName: job.inputVideo.fileName,
                        outputURL: job.outputURL,
                        validationResult: result
                    ))
                }

                self.showValidationDetails = true
                self.isExporting = false
                self.currentJob = nil
                self.exportProgress = nil
                self.exportTask = nil
                self.currentBatchIndex = 0
                self.batchTotal = 0
            } catch is CancellationError {
                self.isExporting = false
                self.currentJob = nil
                self.exportProgress = nil
                self.exportTask = nil
                self.currentBatchIndex = 0
                self.batchTotal = 0
            } catch {
                let fileName = self.currentJob?.inputVideo.fileName
                self.isExporting = false
                self.currentJob = nil
                self.exportProgress = nil
                self.exportTask = nil
                self.currentBatchIndex = 0
                self.batchTotal = 0
                self.errorMessage = fileName.map { "Export failed for \($0): \(error.localizedDescription)" } ?? "Export failed: \(error.localizedDescription)"
            }
        }
    }
    
    public func cancelExport() {
        exportTask?.cancel()
        exportTask = nil
        exportEngine.cancel()
        self.isExporting = false
        self.currentJob = nil
        self.exportProgress = nil
        self.currentBatchIndex = 0
        self.batchTotal = 0
        self.errorMessage = "Export was canceled."
    }

    private func makeExportJobs() -> [ExportJob]? {
        if selectedMode == .export360Video {
            guard !inputVideos.isEmpty else { return nil }
            return inputVideos.map { makeExportJob(inputAsset: $0, secondaryAsset: nil) }
        }

        guard let video = renderedVideo, let audio = spatialAudioSource else { return nil }
        return [makeExportJob(inputAsset: video, secondaryAsset: audio)]
    }

    private func makeExportJob(inputAsset: MediaAsset, secondaryAsset: MediaAsset?) -> ExportJob {
        let targetFolder = exportSettings.destinationFolder ?? inputAsset.url.deletingLastPathComponent()
        let baseName = inputAsset.url.deletingPathExtension().lastPathComponent
        let suffix = selectedMode == .export360Video ? "_360_export" : "_spatial"
        let outputURL = targetFolder.appendingPathComponent("\(baseName)\(suffix).\(exportSettings.outputFormat.rawValue)")

        return ExportJob(
            mode: selectedMode,
            inputVideo: inputAsset,
            secondarySource: secondaryAsset,
            settings: exportSettings,
            attachAudioMode: attachAudioMode,
            outputURL: outputURL
        )
    }

    private func appendInputVideo(_ asset: MediaAsset) {
        guard !inputVideos.contains(where: { $0.url == asset.url }) else { return }
        guard inputVideos.count < Self.maxBatchSize else {
            errorMessage = "Only \(Self.maxBatchSize) videos can be queued at once. Remove a file before adding another."
            return
        }
        inputVideos.append(asset)
    }
}
