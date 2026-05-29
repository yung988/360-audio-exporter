import Foundation

public enum OutputFormat: String, CaseIterable, Identifiable, Codable {
    case mp4 = "mp4"
    case m4v = "m4v"
    case mov = "mov"
    case mkv = "mkv"
    case webm = "webm"
    
    public var id: String { self.rawValue }
    public var label: String {
        switch self {
        case .mp4: return "MP4 (.mp4)"
        case .m4v: return "M4V (.m4v)"
        case .mov: return "MOV (.mov)"
        case .mkv: return "Matroska (.mkv)"
        case .webm: return "WebM (.webm)"
        }
    }

    public var supportsFastStart: Bool {
        switch self {
        case .mp4, .m4v, .mov: return true
        case .mkv, .webm: return false
        }
    }

    public var prefersAACAudio: Bool {
        switch self {
        case .mp4, .m4v, .mov: return true
        case .mkv, .webm: return false
        }
    }
}

public enum VideoCodec: String, CaseIterable, Identifiable, Codable {
    case h264VideoToolbox = "h264_videotoolbox"
    case hevcVideoToolbox = "hevc_videotoolbox"
    case proRes = "prores"
    case vp9 = "vp9"
    case copy = "copy"
    
    public var id: String { self.rawValue }
    public var label: String {
        switch self {
        case .h264VideoToolbox: return "H.264 (VideoToolbox)"
        case .hevcVideoToolbox: return "HEVC (VideoToolbox)"
        case .proRes: return "ProRes 422"
        case .vp9: return "VP9 (WebM/MKV)"
        case .copy: return "Kopírovat (bez rekomprese)"
        }
    }
}

public enum ExportResolution: String, CaseIterable, Identifiable, Codable {
    case original = "original"
    case r8k = "7680x3840"
    case r5k7 = "5760x2880"
    case r5k2 = "5120x2560"
    case r4k = "3840x1920"
    case r3k = "3072x1536"
    case r2k = "1920x960"
    case custom = "custom"
    
    public var id: String { self.rawValue }
    public var label: String {
        switch self {
        case .original: return "Stejné jako zdroj"
        case .r8k: return "7680 × 3840 (8K)"
        case .r5k7: return "5760 × 2880 (5.7K)"
        case .r5k2: return "5120 × 2560 (5K)"
        case .r4k: return "3840 × 1920 (4K)"
        case .r3k: return "3072 × 1536 (3K)"
        case .r2k: return "1920 × 960 (2K)"
        case .custom: return "Vlastní rozlišení"
        }
    }

    public var dimensions: (width: Int, height: Int)? {
        switch self {
        case .original, .custom:
            return nil
        case .r8k:
            return (7680, 3840)
        case .r5k7:
            return (5760, 2880)
        case .r5k2:
            return (5120, 2560)
        case .r4k:
            return (3840, 1920)
        case .r3k:
            return (3072, 1536)
        case .r2k:
            return (1920, 960)
        }
    }
}

public enum FrameRateMode: String, CaseIterable, Identifiable, Codable {
    case original = "original"
    case fps60 = "60"
    case fps50 = "50"
    case fps30 = "29.97"
    case fps24 = "23.976"
    
    public var id: String { self.rawValue }
    public var label: String {
        switch self {
        case .original: return "Stejné jako zdroj"
        case .fps60: return "60 fps"
        case .fps50: return "50 fps"
        case .fps30: return "29.97 fps"
        case .fps24: return "23.98 fps"
        }
    }
    
    public var doubleValue: Double? {
        switch self {
        case .original: return nil
        case .fps60: return 60.0
        case .fps50: return 50.0
        case .fps30: return 29.97
        case .fps24: return 23.976
        }
    }
}

public enum QualityPreset: String, CaseIterable, Identifiable, Codable {
    case maximum = "maximum"
    case high = "high"
    case medium = "medium"
    case low = "low"
    case custom = "custom"
    
    public var id: String { self.rawValue }
    public var label: String {
        switch self {
        case .maximum: return "Maximální"
        case .high: return "Vysoká"
        case .medium: return "Střední"
        case .low: return "Nízká"
        case .custom: return "Vlastní bitrate"
        }
    }
    
    public var bitrateLabel: String {
        switch self {
        case .maximum: return "Bitrate: ~80 Mbps"
        case .high: return "Bitrate: ~40 Mbps"
        case .medium: return "Bitrate: ~20 Mbps"
        case .low: return "Bitrate: ~10 Mbps"
        case .custom: return "Bitrate: podle zadání"
        }
    }
    
    public var videoBitrate: String {
        switch self {
        case .maximum: return "80M"
        case .high: return "40M"
        case .medium: return "20M"
        case .low: return "10M"
        case .custom: return "40M"
        }
    }
}

public enum AudioMode: String, CaseIterable, Identifiable, Codable {
    case keepOriginal = "keep"
    case stereoAAC = "stereo"
    case spatialFourChannelAAC = "spatial"
    case noAudio = "none"
    
    public var id: String { self.rawValue }
    public var label: String {
        switch self {
        case .keepOriginal: return "Ponechat původní"
        case .stereoAAC: return "Stereo (AAC)"
        case .spatialFourChannelAAC: return "Prostorové audio (4 kanály)"
        case .noAudio: return "Bez zvuku"
        }
    }
}

public struct ExportSettings: Codable, Hashable {
    public var outputFormat: OutputFormat
    public var videoCodec: VideoCodec
    public var resolution: ExportResolution
    public var frameRateMode: FrameRateMode
    public var qualityPreset: QualityPreset
    public var audioMode: AudioMode
    public var audioBitrate: Int // in kbps, e.g. 768
    public var customVideoBitrateMbps: Int
    public var customWidth: Int
    public var customHeight: Int
    public var destinationFolder: URL?

    public var effectiveVideoBitrate: String {
        if qualityPreset == .custom {
            return "\(max(1, customVideoBitrateMbps))M"
        }
        return qualityPreset.videoBitrate
    }

    public var effectiveResolution: (width: Int, height: Int)? {
        if resolution == .custom {
            let safeWidth = max(2, customWidth)
            let safeHeight = max(2, customHeight)
            return (safeWidth, safeHeight)
        }
        return resolution.dimensions
    }
    
    public static var `default`: ExportSettings {
        return ExportSettings(
            outputFormat: .mp4,
            videoCodec: .hevcVideoToolbox,
            resolution: .r4k,
            frameRateMode: .original,
            qualityPreset: .high,
            audioMode: .spatialFourChannelAAC,
            audioBitrate: 768,
            customVideoBitrateMbps: 40,
            customWidth: 3840,
            customHeight: 1920,
            destinationFolder: nil
        )
    }
    
    public init(
        outputFormat: OutputFormat,
        videoCodec: VideoCodec,
        resolution: ExportResolution,
        frameRateMode: FrameRateMode,
        qualityPreset: QualityPreset,
        audioMode: AudioMode,
        audioBitrate: Int,
        customVideoBitrateMbps: Int = 40,
        customWidth: Int = 3840,
        customHeight: Int = 1920,
        destinationFolder: URL? = nil
    ) {
        self.outputFormat = outputFormat
        self.videoCodec = videoCodec
        self.resolution = resolution
        self.frameRateMode = frameRateMode
        self.qualityPreset = qualityPreset
        self.audioMode = audioMode
        self.audioBitrate = audioBitrate
        self.customVideoBitrateMbps = customVideoBitrateMbps
        self.customWidth = customWidth
        self.customHeight = customHeight
        self.destinationFolder = destinationFolder
    }
}
