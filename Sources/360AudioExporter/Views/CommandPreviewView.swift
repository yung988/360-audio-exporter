import SwiftUI

struct CommandPreviewView: View {
    @EnvironmentObject var appState: AppState
    @State private var isExpanded = false

    var body: some View {
        if let command = appState.commandPreview {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("FFmpeg command preview", systemImage: "terminal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Spacer()

                    Button(isExpanded ? "Skrýt" : "Zobrazit") {
                        isExpanded.toggle()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Text("Přesně tenhle příkaz aplikace spustí. Hodí se pro kontrolu nebo debug.")
                    .font(.caption2)
                    .foregroundColor(.gray)

                if isExpanded {
                    ScrollView(.horizontal) {
                        Text(command)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.green)
                            .textSelection(.enabled)
                            .padding(10)
                    }
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(8)
                }
            }
            .padding(12)
            .background(Color(red: 0.129, green: 0.137, blue: 0.149))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }
}
