import SwiftUI
import UniformTypeIdentifiers

struct MediaDropZoneView: View {
    @EnvironmentObject var appState: AppState
    let title: String
    let allowedExtensions: [String]
    let mode: ExportMode
    var isSecondary: Bool = false
    
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: isSecondary ? "waveform.path.badge.plus" : "video.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(isTargeted ? .blue : .gray)
            
            Text(title)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Podporované formáty: \(allowedExtensions.joined(separator: ", "))")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isTargeted ? Color.blue.opacity(0.05) : Color(red: 0.129, green: 0.137, blue: 0.149))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? Color.blue : Color.gray.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [6, 4])
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if let selectedURL = FileAccessService.selectFile(allowedExtensions: allowedExtensions) {
                Task {
                    await appState.probeAsset(url: selectedURL, mode: mode, isSecondary: isSecondary)
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                if let url = url {
                    // Check extension
                    let ext = url.pathExtension.lowercased()
                    if allowedExtensions.isEmpty || allowedExtensions.contains(ext) {
                        Task {
                            await appState.probeAsset(url: url, mode: mode, isSecondary: isSecondary)
                        }
                    }
                }
            }
            return true
        }
    }
}
