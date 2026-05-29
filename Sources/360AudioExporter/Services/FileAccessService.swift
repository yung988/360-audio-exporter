import AppKit
import UniformTypeIdentifiers

public final class FileAccessService {
    
    @MainActor
    public static func selectFile(allowedExtensions: [String]) -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if !allowedExtensions.isEmpty {
            panel.allowedContentTypes = allowedExtensions.compactMap { ext in
                UTType(filenameExtension: ext)
            }
        }
        
        let response = panel.runModal()
        if response == .OK {
            return panel.url
        }
        return nil
    }
    
    @MainActor
    public static func selectDirectory() -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        
        let response = panel.runModal()
        if response == .OK {
            return panel.url
        }
        return nil
    }
}
