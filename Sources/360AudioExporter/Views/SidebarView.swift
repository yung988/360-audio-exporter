import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showSettings: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Orbit 360")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("A simple 360° video transcoder for VR-ready exports.")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)
            .padding(.top, 16)

            Text("Workflow")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.horizontal, 8)
            
            // Mode 1 Selection Button
            Button(action: {
                appState.selectedMode = .export360Video
                showSettings = false
            }) {
                SidebarButtonContent(
                    iconName: "globe",
                    title: "Convert 360° Video",
                    subtitle: "Create clean VR-ready exports",
                    isSelected: appState.selectedMode == .export360Video && !showSettings
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Mode 2 Selection Button
            Button(action: {
                appState.selectedMode = .attachSpatialAudio
                showSettings = false
            }) {
                SidebarButtonContent(
                    iconName: "waveform.circle",
                    title: "Restore Spatial Audio",
                    subtitle: "Replace stereo with original ambisonic audio",
                    isSelected: appState.selectedMode == .attachSpatialAudio && !showSettings
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Settings Button
            Button(action: {
                showSettings = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape")
                        .font(.title3)
                    Text("Settings")
                        .font(.body)
                }
                .foregroundColor(showSettings ? .blue : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(showSettings ? Color.blue.opacity(0.1) : Color.clear)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 12)
        .frame(width: 230)
        .background(Color(red: 0.055, green: 0.059, blue: 0.067))
    }
}

struct SidebarButtonContent: View {
    let iconName: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(isSelected ? .white : .blue)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
                )
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .gray)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    isSelected
                        ? Color(red: 0.114, green: 0.380, blue: 0.882) // mockup blue
                        : (isHovering ? Color.gray.opacity(0.08) : Color.gray.opacity(0.03))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
