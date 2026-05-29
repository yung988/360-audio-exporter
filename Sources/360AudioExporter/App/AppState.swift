import Foundation
import Combine

@MainActor
public final class AppState: ObservableObject {
    @Published var selectedMode: ExportMode = .export360Video
    
    // Mode 1 assets
    @Published var inputVideo: MediaAsset?
    
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
    @Published var showValidationDetails: Bool = false
    @Published var errorMessage: String?
    
    // Executable settings paths
    @Published var ffmpegPath: String
    @Published var ffprobePath: String
    
    private let ffprobeService: MediaProbeService
    private let exportEngine: ExportEngine
    private let metadataService: MetadataService
    private let commandBuilder = FFmpegCommandBuilder()
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
        
        self.ffmpegPath = savedFfmpeg ?? Self.findDefaultBinary(name: "ffmpeg")
        self.ffprobePath = savedFfprobe ?? Self.findDefaultBinary(name: "ffprobe")
    }
    
    public func saveBinaryPaths() {
        UserDefaults.standard.set(ffmpegPath, forKey: "ffmpegPath")
        UserDefaults.standard.set(ffprobePath, forKey: "ffprobePath")
    }
    
    private static func findDefaultBinary(name: String) -> String {
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
    
    // Validate binaries exist
    public var isFfmpegAvailable: Bool {
        FileManager.default.fileExists(atPath: ffmpegPath)
    }
    
    public var isFfprobeAvailable: Bool {
        FileManager.default.fileExists(atPath: ffprobePath)
    }

    public var commandPreview: String? {
        guard let job = makeExportJob() else { return nil }
        return commandBuilder.commandLine(for: job, ffmpegPath: ffmpegPath)
    }
    
    // Core business actions
    public func probeAsset(url: URL, mode: ExportMode, isSecondary: Bool = false) async {
        guard isFfprobeAvailable else {
            self.errorMessage = "ffprobe binary not found. Please set correct path in Nastavení."
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
                self.inputVideo = asset
            } else {
                if isSecondary {
                    self.spatialAudioSource = asset
                } else {
                    self.renderedVideo = asset
                }
            }
        } catch {
            self.errorMessage = "Chyba načítání metadat: \(error.localizedDescription)"
        }
    }
    
    public func clearAsset(mode: ExportMode, isSecondary: Bool = false) {
        if mode == .export360Video {
            self.inputVideo = nil
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
            self.errorMessage = "ffmpeg binary not found. Please set correct path in Nastavení."
            return
        }

        guard let job = makeExportJob() else {
            self.errorMessage = selectedMode == .export360Video ? "Není vybráno vstupní video." : "Není vybráno hotové video nebo zdroj prostorového audia."
            return
        }
        
        self.currentJob = job
        self.validationResult = nil
        self.showValidationDetails = false
        self.isExporting = true
        self.errorMessage = nil
        
        exportTask = Task {
            do {
                let progressStream = exportEngine.start(job: job, ffmpegPath: ffmpegPath)
                for try await progress in progressStream {
                    try Task.checkCancellation()
                    self.exportProgress = progress
                }
                try Task.checkCancellation()
                
                // Success - run validation
                self.exportProgress = ExportProgress(
                    percentage: 1.0,
                    currentTime: nil,
                    totalDuration: nil,
                    estimatedRemainingSeconds: 0,
                    speed: nil,
                    stage: "Validace",
                    message: "Kontroluji výstup přes ffprobe..."
                )
                
                let result = try await metadataService.validate(url: job.outputURL, expectedJob: job, ffprobePath: ffprobePath)
                self.validationResult = result
                self.lastCompletedJob = job
                self.showValidationDetails = true
                self.isExporting = false
                self.currentJob = nil
                self.exportProgress = nil
                self.exportTask = nil
            } catch is CancellationError {
                self.isExporting = false
                self.currentJob = nil
                self.exportProgress = nil
                self.exportTask = nil
            } catch {
                self.isExporting = false
                self.currentJob = nil
                self.exportProgress = nil
                self.exportTask = nil
                self.errorMessage = "Export selhal: \(error.localizedDescription)"
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
        self.errorMessage = "Export byl stornován uživatelem."
    }

    private func makeExportJob() -> ExportJob? {
        let inputAsset: MediaAsset
        let secondaryAsset: MediaAsset?

        if selectedMode == .export360Video {
            guard let video = inputVideo else { return nil }
            inputAsset = video
            secondaryAsset = nil
        } else {
            guard let video = renderedVideo, let audio = spatialAudioSource else { return nil }
            inputAsset = video
            secondaryAsset = audio
        }

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
}
