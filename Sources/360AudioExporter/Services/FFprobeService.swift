import Foundation

public protocol MediaProbeService {
    func probe(url: URL, ffprobePath: String) async throws -> MediaProbe
}

public final class FFprobeService: MediaProbeService {
    
    public init() {}
    
    private struct RawFFprobeOutput: Codable {
        struct Stream: Codable {
            let index: Int
            let codec_name: String?
            let codec_type: String?
            let width: Int?
            let height: Int?
            let r_frame_rate: String?
            let channels: Int?
            let channel_layout: String?
            let sample_rate: String?
            let bit_rate: String?
            let side_data_list: [SideData]?
            
            enum CodingKeys: String, CodingKey {
                case index, codec_name, codec_type, width, height, r_frame_rate, channels, channel_layout, sample_rate, bit_rate
                case side_data_list = "side_data_list"
            }
        }
        
        struct SideData: Codable {
            let side_data_type: String?
            let projection: String?
            
            enum CodingKeys: String, CodingKey {
                case side_data_type = "side_data_type"
                case projection
            }
        }
        
        struct Format: Codable {
            let duration: String?
            let format_name: String?
            let size: String?
            let bit_rate: String?
            
            enum CodingKeys: String, CodingKey {
                case duration
                case format_name = "format_name"
                case size
                case bit_rate = "bit_rate"
            }
        }
        
        let streams: [Stream]?
        let format: Format?
    }
    
    public func probe(url: URL, ffprobePath: String) async throws -> MediaProbe {
        guard FileManager.default.fileExists(atPath: ffprobePath) else {
            throw NSError(domain: "FFprobeService", code: 404, userInfo: [NSLocalizedDescriptionKey: "ffprobe binary not found at \(ffprobePath)"])
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffprobePath)
        process.arguments = [
            "-v", "quiet",
            "-print_format", "json",
            "-show_format",
            "-show_streams",
            url.path
        ]
        
        let outPipe = Pipe()
        let errPipe = Pipe()
        
        process.standardOutput = outPipe
        process.standardError = errPipe
        
        try process.run()
        
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errStr = String(data: errData, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "FFprobeService", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "ffprobe failed: \(errStr)"])
        }
        
        let rawOutput = try JSONDecoder().decode(RawFFprobeOutput.self, from: outData)
        
        var duration: Double?
        if let durStr = rawOutput.format?.duration {
            duration = Double(durStr)
        }
        
        let containerFormat = rawOutput.format?.format_name
        
        var audioStreams: [AudioStreamInfo] = []
        var videoStreams: [VideoStreamInfo] = []
        var isLikely360 = false
        var videoWidth: Int?
        var videoHeight: Int?
        var videoCodec: String?
        var videoFrameRate: Double?
        
        if let streams = rawOutput.streams {
            for stream in streams {
                let type = stream.codec_type ?? ""
                if type == "video" {
                    let codec = stream.codec_name ?? "unknown"
                    let width = stream.width ?? 0
                    let height = stream.height ?? 0
                    
                    var fps: Double?
                    if let rFpsStr = stream.r_frame_rate {
                        let parts = rFpsStr.components(separatedBy: "/")
                        if parts.count == 2, let num = Double(parts[0]), let den = Double(parts[1]), den > 0 {
                            fps = num / den
                        } else {
                            fps = Double(rFpsStr)
                        }
                    }
                    
                    let bitRate = stream.bit_rate != nil ? Int(stream.bit_rate!) : nil
                    let videoInfo = VideoStreamInfo(
                        index: stream.index,
                        codec: codec,
                        width: width,
                        height: height,
                        frameRate: fps,
                        bitrate: bitRate
                    )
                    videoStreams.append(videoInfo)
                    
                    if videoWidth == nil {
                        videoWidth = width
                        videoHeight = height
                        videoCodec = codec
                        videoFrameRate = fps
                    }
                    
                    // Check for spherical projection metadata
                    if let sideDataList = stream.side_data_list {
                        for sideData in sideDataList {
                            let sType = sideData.side_data_type?.lowercased() ?? ""
                            let sProj = sideData.projection?.lowercased() ?? ""
                            if sType.contains("spherical") || sProj.contains("equirectangular") {
                                isLikely360 = true
                            }
                        }
                    }
                    
                    // Extra heuristics: common 360 video aspect ratio (exactly 2:1, e.g., 3840x1920 or 5760x2880)
                    if width > 0 && height > 0 && width == height * 2 {
                        isLikely360 = true
                    }
                    
                } else if type == "audio" {
                    let codec = stream.codec_name ?? "unknown"
                    let channels = stream.channels ?? 2
                    let layout = stream.channel_layout
                    let rate = stream.sample_rate != nil ? Int(stream.sample_rate!) : nil
                    let bitRate = stream.bit_rate != nil ? Int(stream.bit_rate!) : nil
                    
                    let audioInfo = AudioStreamInfo(
                        index: stream.index,
                        codec: codec,
                        channels: channels,
                        channelLayout: layout,
                        sampleRate: rate,
                        bitrate: bitRate
                    )
                    audioStreams.append(audioInfo)
                }
            }
        }
        
        return MediaProbe(
            duration: duration,
            width: videoWidth,
            height: videoHeight,
            frameRate: videoFrameRate,
            videoCodec: videoCodec,
            audioStreams: audioStreams,
            videoStreams: videoStreams,
            containerFormat: containerFormat,
            isLikely360: isLikely360
        )
    }
}
