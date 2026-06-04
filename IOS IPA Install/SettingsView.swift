//
//  SettingsView.swift
//  IOS IPA Install
//
//  Created by Julien Nicolas on 7/16/24.
//
import SwiftUI

struct SettingsView: View {
    @State private var deviceManager = DeviceStorageManager()
    @State private var showingAddDevice = false
    @State private var editingDevice: DeviceInfo?
    @State private var showingHelp = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerView

                devicesListCard

                aboutECIDCard

                Spacer(minLength: 20)
            }
            .padding(24)
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(.windowBackgroundColor))
        .navigationTitle("Preferences")
        .sheet(isPresented: $showingAddDevice) {
            AddDeviceSheet(deviceManager: deviceManager)
        }
        .sheet(item: $editingDevice) { device in
            EditDeviceSheet(device: device, deviceManager: deviceManager)
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Device Configuration")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            HStack {
                Text("Devices are auto-discovered when connected. Customize names or add manually.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }

    private var devicesListCard: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Known Devices", systemImage: "iphone.and.arrow.forward")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { showingAddDevice = true }) {
                    Label("Add Device", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
            }

            if deviceManager.devices.isEmpty {
                emptyDevicesView
            } else {
                devicesList
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separatorColor), lineWidth: 0.5)
        )
    }

    private var emptyDevicesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.slash")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No devices configured")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Add your first device to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var devicesList: some View {
        VStack(spacing: 8) {
            ForEach(deviceManager.devices) { device in
                DeviceRow(device: device, onEdit: {
                    editingDevice = device
                }, onDelete: {
                    deviceManager.deleteDevice(device)
                })
            }
        }
    }

    private var aboutECIDCard: some View {
        VStack(spacing: 16) {
            HStack {
                Label("About ECID", systemImage: "info.circle")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { showingHelp = true }) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingHelp) {
                    enhancedHelpContent
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("The ECID (Electronic Chip ID) is a unique 64-bit identifier that distinguishes your iOS device from all others. It's essential for device-specific operations and installations.")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Find your ECID using any of these methods:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 6) {
                        methodRow(icon: "iphone", title: "iOS Settings", description: "Settings → General → About → ECID")
                        methodRow(icon: "desktopcomputer", title: "Apple Configurator 2", description: "Connect device and view device information")
                        methodRow(icon: "hammer.fill", title: "Xcode", description: "Window → Devices and Simulators → Select device")
                    }
                }

                Divider()
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Format Example:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text("0x1234567890ABCD")
                        .font(.caption.monospaced())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.textBackgroundColor))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color(.separatorColor), lineWidth: 0.5)
                                )
                        )
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separatorColor), lineWidth: 0.5)
        )
    }

    private func methodRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.accentColor)
                .frame(width: 20, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var enhancedHelpContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Finding Your Device ECID")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Text("The ECID is a unique identifier for your iOS device. Here are several ways to locate it:")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                helpMethodCard(
                    icon: "iphone",
                    title: "iOS Device Settings",
                    steps: ["Open Settings app", "Navigate to General", "Tap About", "Look for ECID field"],
                    color: .blue
                )

                helpMethodCard(
                    icon: "desktopcomputer",
                    title: "Apple Configurator 2",
                    steps: ["Connect your iOS device", "Open Apple Configurator 2", "Select your device", "View device information panel"],
                    color: .green
                )

                helpMethodCard(
                    icon: "hammer.fill",
                    title: "Xcode (Developer Tool)",
                    steps: ["Open Xcode", "Go to Window menu", "Select Devices and Simulators", "Choose your connected device"],
                    color: .orange
                )
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Expected Format:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }

                Text("0x1234567890ABCD")
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.textBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(.separatorColor), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.primary)

                Text("• Starts with '0x' prefix\n• Followed by 13-16 hexadecimal characters (0-9, A-F)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    private func helpMethodCard(icon: String, title: String, steps: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(color)
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(color)
                            .frame(width: 16, alignment: .leading)
                        Text(step)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                }
            }
            .padding(.leading, 8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct DeviceRow: View {
    let device: DeviceInfo
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            deviceIcon
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(device.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if !device.name.isEmpty && device.name != device.systemName && device.systemName != nil {
                        Text("(Custom)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if device.udid != nil {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .help("Auto-detected device")
                    }
                }

                if let modelName = device.deviceType {
                    Text(DeviceTypeMapper.friendlyName(for: modelName))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    Text(device.ecid)
                        .font(.caption2.monospaced())
                        .foregroundColor(.secondary)

                    if let lastSeen = device.lastSeen {
                        Text("• Last seen: \(lastSeen.formatted(.relative(presentation: .named)))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            if isHovering {
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .help("Edit device")

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .help("Delete device")
                }
                .transition(.opacity)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color(.selectedControlColor).opacity(0.3) : Color(.textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separatorColor), lineWidth: 0.5)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
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

struct AddDeviceSheet: View {
    @Environment(\.dismiss) var dismiss
    let deviceManager: DeviceStorageManager

    @State private var deviceName = ""
    @State private var deviceECID = ""
    @State private var isValidECID = false

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "iphone.badge.plus")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Add New Device")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            Form {
                TextField("Device Name (e.g., My iPhone)", text: $deviceName)
                    .textFieldStyle(.roundedBorder)

                TextField("ECID (e.g., 0x1234567890ABCDEF)", text: $deviceECID)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: deviceECID) { _, newValue in
                        validateECID(newValue)
                    }

                if !deviceECID.isEmpty && !isValidECID {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Invalid ECID format")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.vertical)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add Device") {
                    let device = DeviceInfo(name: deviceName, ecid: deviceECID)
                    deviceManager.addDevice(device)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(deviceName.isEmpty || !isValidECID)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 450)
    }

    private func validateECID(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^0x[0-9A-Fa-f]{13,16}$"
        isValidECID = trimmed.range(of: pattern, options: .regularExpression) != nil
    }
}

struct EditDeviceSheet: View {
    @Environment(\.dismiss) var dismiss
    let device: DeviceInfo
    let deviceManager: DeviceStorageManager

    @State private var deviceName = ""
    @State private var deviceECID = ""
    @State private var isValidECID = true

    private var isAutoDetected: Bool {
        device.udid != nil
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Edit Device")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            Form {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Name (optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Leave empty to use device name", text: $deviceName)
                        .textFieldStyle(.roundedBorder)
                }

                if let deviceType = device.deviceType {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(DeviceTypeMapper.friendlyName(for: deviceType))
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }

                if let systemName = device.systemName {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Device Name:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(systemName)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }

                if let udid = device.udid {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("UDID:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(udid)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("ECID:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if isAutoDetected {
                        Text(device.ecid)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    } else {
                        TextField("ECID", text: $deviceECID)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .onChange(of: deviceECID) { _, newValue in
                                validateECID(newValue)
                            }

                        if !deviceECID.isEmpty && !isValidECID {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Invalid ECID format")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save Changes") {
                    var updatedDevice = device
                    updatedDevice.name = deviceName
                    if !isAutoDetected {
                        updatedDevice.ecid = deviceECID
                    }
                    deviceManager.updateDevice(updatedDevice)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isAutoDetected ? false : (!isValidECID || deviceECID.isEmpty))
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 450)
        .onAppear {
            deviceName = device.name
            deviceECID = device.ecid
        }
    }

    private func validateECID(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^0x[0-9A-Fa-f]{13,16}$"
        isValidECID = trimmed.range(of: pattern, options: .regularExpression) != nil
    }
}

#Preview("Settings - Empty") {
    SettingsView()
        .frame(width: 700, height: 600)
}

#Preview("Settings View") {
    SettingsView()
        .frame(width: 700, height: 600)
}

#Preview("Device Row") {
    DeviceRow(
        device: DeviceInfo(name: "My iPhone", ecid: "0x1234567890ABCD"),
        onEdit: {},
        onDelete: {}
    )
    .padding()
    .frame(width: 500)
}

#Preview("Add Device Sheet") {
    AddDeviceSheet(deviceManager: DeviceStorageManager())
}

#Preview("Edit Device Sheet") {
    EditDeviceSheet(
        device: DeviceInfo(name: "iPhone 15 Pro", ecid: "0x1234567890ABCD"),
        deviceManager: DeviceStorageManager()
    )
}
