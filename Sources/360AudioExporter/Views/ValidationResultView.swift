import SwiftUI

struct ValidationResultView: View {
    @EnvironmentObject var appState: AppState
    let result: ValidationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: result.hasWarnings ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(result.hasWarnings ? .orange : .green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.hasWarnings ? "Export completed with warnings" : "Export created successfully")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(result.message)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 8)
            
            // Warnings list
            if result.hasWarnings {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(result.warnings, id: \.self) { warning in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(.orange)
                            Text(warning)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(10)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Technical Specs Card
            VStack(alignment: .leading, spacing: 10) {
                Text("Output validation:")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                Group {
                    HStack {
                        Text("Video stream:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(result.videoOk ? "OK" : "Missing")
                            .fontWeight(.semibold)
                            .foregroundColor(result.videoOk ? .green : .red)
                    }
                    
                    HStack {
                        Text("360° projection:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(result.projectionOk ? "Yes (equirectangular)" : "Not detected")
                            .fontWeight(.semibold)
                            .foregroundColor(result.projectionOk ? .green : .orange)
                    }
                    
                    HStack {
                        Text("Audio channels:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(result.channels) ch (\(result.channels == 4 ? "Ambisonic" : "Standard"))")
                            .fontWeight(.semibold)
                            .foregroundColor(result.channels >= 4 ? .green : .orange)
                    }
                    
                    HStack {
                        Text("Audio codec:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(result.codec)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("Duration:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(result.durationOk ? "OK (matches source)" : "Different")
                            .fontWeight(.semibold)
                            .foregroundColor(result.durationOk ? .green : .orange)
                    }
                }
                .font(.caption)
            }
            .padding(14)
            .background(Color(red: 0.129, green: 0.137, blue: 0.149))
            .cornerRadius(10)
            
            // File Destination Path Info
            if let job = appState.currentJob ?? appState.lastCompletedJob {
                VStack(alignment: .leading, spacing: 4) {
                    Text("File:")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(job.outputURL.lastPathComponent)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text(job.outputURL.path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            // Action button
            HStack {
                Spacer()
                Button("Close") {
                    appState.showValidationDetails = false
                    appState.validationResult = nil
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(width: 440)
        .background(Color(red: 0.086, green: 0.090, blue: 0.102))
    }
}

struct BatchValidationSummaryView: View {
    @EnvironmentObject var appState: AppState
    let results: [CompletedExportResult]

    private var warningCount: Int {
        results.filter { $0.validationResult.hasWarnings }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: warningCount == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(warningCount == 0 ? .green : .orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Batch export complete")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("\(results.count) video\(results.count == 1 ? "" : "s") exported. \(warningCount) warning\(warningCount == 1 ? "" : "s") found during validation.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(results) { item in
                        BatchValidationRow(item: item)
                    }
                }
            }
            .frame(maxHeight: 320)

            HStack {
                Spacer()
                Button("Close") {
                    appState.showValidationDetails = false
                    appState.validationResult = nil
                    appState.completedExportResults = []
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 620)
        .background(Color(red: 0.086, green: 0.090, blue: 0.102))
    }
}

private struct BatchValidationRow: View {
    let item: CompletedExportResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: item.validationResult.hasWarnings ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundColor(item.validationResult.hasWarnings ? .orange : .green)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.sourceFileName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(item.outputURL.lastPathComponent)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)

                    Text(item.outputURL.path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.85))
                        .lineLimit(1)
                }

                Spacer()

                Text(item.validationResult.hasWarnings ? "Warnings" : "OK")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(item.validationResult.hasWarnings ? .orange : .green)
            }

            if item.validationResult.hasWarnings {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(item.validationResult.warnings, id: \.self) { warning in
                        Text("• \(warning)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.leading, 24)
            }
        }
        .padding(10)
        .background(Color(red: 0.129, green: 0.137, blue: 0.149))
        .cornerRadius(8)
    }
}
