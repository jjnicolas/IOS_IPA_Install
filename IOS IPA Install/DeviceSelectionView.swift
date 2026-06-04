import SwiftUI

struct DeviceSelectionView: View {
    let device: DeviceInfo
    let ipaURL: URL
    @State var processModel = ProcessModel()
    @State private var hasStartedInstall = false

    var body: some View {
        VStack(spacing: 0) {
            if !hasStartedInstall {
                deviceInfoSection
            } else {
                installationProgressSection
            }
        }
        .frame(minWidth: 500, minHeight: 500)
    }

    private var deviceIcon: String {
        if let deviceType = device.deviceType, deviceType.contains("iPad") {
            return "ipad"
        }
        return "iphone"
    }

    private var deviceInfoSection: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: deviceIcon + ".gen3")
                    .font(.system(size: 50))
                    .foregroundColor(.accentColor)

                Text("Install to Device")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding(.top, 30)
            .padding(.bottom, 20)

            // Device Info Card
            VStack(spacing: 16) {
                infoRow(label: "Device", value: device.displayName, icon: deviceIcon)
                Divider()
                infoRow(label: "Model", value: device.friendlyModelName, icon: "apps.iphone")
                Divider()
                infoRow(label: "ECID", value: device.ecid, icon: "number", isMonospaced: true)
                Divider()
                infoRow(label: "IPA File", value: ipaURL.lastPathComponent, icon: "doc.fill")
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separatorColor), lineWidth: 0.5)
            )
            .padding(.horizontal, 30)
            .padding(.bottom, 30)

            // Install Button
            Button(action: startInstallation) {
                HStack {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("Install Now")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 30)
            .padding(.bottom, 30)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var installationProgressSection: some View {
        VStack(spacing: 0) {
            statusBar

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if let error = processModel.lastError {
                            errorBanner(error)
                        }

                        Text(processModel.output)
                            .monospaced()
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("output")
                    }
                    .padding()
                }
                .onChange(of: processModel.output) { _, _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("output", anchor: .bottom)
                    }
                }
            }
        }
    }

    private func infoRow(label: String, value: String, icon: String, isMonospaced: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(isMonospaced ? .body.monospaced() : .body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()
        }
    }

    private var statusBar: some View {
        HStack {
            if processModel.isProcessing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Installing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if processModel.lastError != nil {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Installation Failed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if processModel.installationSucceeded && !processModel.isProcessing {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Installation Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .border(Color(NSColor.separatorColor), width: 0.5)
    }

    private func errorBanner(_ error: ProcessError) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Installation Error")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private func startInstallation() {
        hasStartedInstall = true
        Task {
            await processModel.process(url: ipaURL, ecid: device.ecid)
        }
    }
}

#Preview("Device Selection - Ready") {
    DeviceSelectionView(
        device: DeviceInfo(
            name: "My iPhone 15 Pro",
            ecid: "0x1234567890ABCD"
        ),
        ipaURL: URL(fileURLWithPath: "/Users/test/Downloads/MyApp.ipa")
    )
}

#Preview("Matched Device Row") {
    MatchedDeviceRow(
        device: DeviceInfo(
            name: "iPad Pro",
            ecid: "0x1234567890ABC"
        ),
        onInstall: {}
    )
    .padding()
}
