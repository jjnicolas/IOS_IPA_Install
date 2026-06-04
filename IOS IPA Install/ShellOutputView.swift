import SwiftUI

struct ShellOutputView: View {
    @State var detectionModel = DeviceDetectionModel()
    @State var deviceManager = DeviceStorageManager()
    @State private var showingDeviceWindows: [ConnectedDevice] = []
    @State private var hasScanned = false

    var url: URL?

    var body: some View {
        VStack(spacing: 0) {
            deviceDetectionView
        }
        .navigationTitle(url?.lastPathComponent ?? "IPA Installer")
        .task {
            guard let url, !hasScanned else { return }
            hasScanned = true
            await detectionModel.scanForDevices(deviceManager: deviceManager)
        }
    }


    private var deviceDetectionView: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: detectionModel.isScanning ? "antenna.radiowaves.left.and.right" : "iphone.and.arrow.forward")
                    .font(.system(size: 44))
                    .foregroundColor(.accentColor)
                    .symbolEffect(.pulse, options: .repeating, isActive: detectionModel.isScanning)

                Text(detectionModel.isScanning ? "Scanning for Devices..." : "Device Detection")
                    .font(.title3)
                    .fontWeight(.semibold)

                if let url {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(url.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 24)

            // Status Section
            if detectionModel.isScanning {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.vertical, 12)
            } else if let error = detectionModel.scanError {
                errorView(error)
            } else if detectionModel.connectedDevices.isEmpty {
                noMatchingDevicesView
            } else {
                matchedDevicesView
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Detection Error")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )

            Button(action: rescanDevices) {
                Label("Retry Scan", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 12)
    }

    private var noMatchingDevicesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.title)
                .foregroundColor(.secondary)

            Text("No Devices Found")
                .font(.subheadline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 6) {
                Text("Make sure:")
                    .font(.caption)
                    .fontWeight(.medium)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                        Text("Your iOS device is connected via USB")
                    }
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                        Text("The device is unlocked and trusted")
                    }
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                        Text("Apple Configurator 2 is installed")
                    }
                }
                .font(.caption2)
            }
            .foregroundColor(.secondary)
            .padding(12)
            .frame(maxWidth: 280)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
            )

            Button(action: rescanDevices) {
                Label("Rescan", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .padding(.top, 6)
        }
    }

    private var matchedDevicesView: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.green)
                Text("Found \(detectionModel.connectedDevices.count) Connected Device\(detectionModel.connectedDevices.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }

            VStack(spacing: 10) {
                ForEach(detectionModel.connectedDevices) { connectedDevice in
                    MatchedDeviceRow(
                        device: connectedDevice.deviceInfo,
                        onInstall: {
                            openInstallWindow(for: connectedDevice.deviceInfo)
                        }
                    )
                }
            }
            .padding(.horizontal, 12)

            Button(action: rescanDevices) {
                Label("Rescan Devices", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .padding(.top, 6)
        }
    }

    private func rescanDevices() {
        hasScanned = false
        Task {
            hasScanned = true
            await detectionModel.scanForDevices(deviceManager: deviceManager)
        }
    }

    private func openSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preferences") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openInstallWindow(for device: DeviceInfo) {
        guard let url else { return }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Install to \(device.displayName)"
        window.contentView = NSHostingView(
            rootView: DeviceSelectionView(device: device, ipaURL: url)
        )
        window.contentMinSize = NSSize(width: 700, height: 400)
        window.contentMaxSize = NSSize(width: 900, height: 600)
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false
    }
}

struct MatchedDeviceRow: View {
    let device: DeviceInfo
    let onInstall: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            deviceIcon
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(device.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(device.friendlyModelName)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(device.ecid)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)

                Button(action: onInstall) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Install")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.green.opacity(0.3), lineWidth: 1.5)
        )
    }

    private var deviceIcon: some View {
        Group {
            if let deviceType = device.deviceType {
                if deviceType.contains("iPad") {
                    Image(systemName: "ipad")
                } else {
                    Image(systemName: "iphone")
                }
            } else {
                Image(systemName: "iphone")
            }
        }
    }
}

#Preview("No Devices Configured") {
    ShellOutputView(url: URL(fileURLWithPath: "/Users/test/Downloads/TestApp.ipa"))
}

#Preview("Device Detection with URL") {
    ShellOutputView(url: URL(fileURLWithPath: "/Users/test/Downloads/MyApp.ipa"))
}

#Preview("Matched Device Row") {
    MatchedDeviceRow(
        device: DeviceInfo(name: "My iPhone", ecid: "0x1234567890ABCD"),
        onInstall: {}
    )
    .padding()
    .frame(width: 500)
}
