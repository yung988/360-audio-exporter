import Foundation

public enum ExportMode: String, CaseIterable, Identifiable, Codable {
    case export360Video = "export360"
    case attachSpatialAudio = "attachSpatial"
    
    public var id: String { self.rawValue }
    public var label: String {
        switch self {
        case .export360Video: return "Export 360° video"
        case .attachSpatialAudio: return "Přidat prostorové audio"
        }
    }
}

public enum AttachAudioMode: String, CaseIterable, Identifiable, Codable {
    case replace = "replace"
    case add = "add"
    case keepStereoAndAddSpatial = "keepStereoAndAddSpatial"
    
    public var id: String { self.rawValue }
    public var label: String {
        switch self {
        case .replace: return "Nahradit audio"
        case .add: return "Přidat jako další audio stopu"
        case .keepStereoAndAddSpatial: return "Ponechat původní stereo + přidat spatial"
        }
    }
}

public struct ExportJob: Identifiable, Codable {
    public let id: UUID
    public var mode: ExportMode
    public var inputVideo: MediaAsset
    public var secondarySource: MediaAsset? // Used in mode 2 (spatial audio source)
    public var settings: ExportSettings
    public var attachAudioMode: AttachAudioMode // Specific to mode 2
    public var outputURL: URL
    
    public init(
        id: UUID = UUID(),
        mode: ExportMode,
        inputVideo: MediaAsset,
        secondarySource: MediaAsset? = nil,
        settings: ExportSettings,
        attachAudioMode: AttachAudioMode = .replace,
        outputURL: URL
    ) {
        self.id = id
        self.mode = mode
        self.inputVideo = inputVideo
        self.secondarySource = secondarySource
        self.settings = settings
        self.attachAudioMode = attachAudioMode
        self.outputURL = outputURL
    }
}
