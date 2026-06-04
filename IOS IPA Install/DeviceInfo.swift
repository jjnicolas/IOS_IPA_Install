import Foundation
import SwiftUI

struct DeviceInfo: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var ecid: String

    // Auto-populated fields from cfgutil JSON
    var udid: String?
    var deviceType: String?
    var systemName: String?
    var locationID: Int?
    var lastSeen: Date?

    // Computed property for display name with smart priority
    var displayName: String {
        // Priority: custom name > system name > friendly model > "Unknown Device"
        if !name.isEmpty && name != "My iPhone" {
            return name
        }
        if let systemName = systemName, !systemName.isEmpty {
            return systemName
        }
        if let deviceType = deviceType {
            return DeviceTypeMapper.friendlyName(for: deviceType)
        }
        return "Unknown Device"
    }

    // Computed property for friendly model name
    var friendlyModelName: String {
        guard let deviceType = deviceType else { return "Unknown Model" }
        return DeviceTypeMapper.friendlyName(for: deviceType)
    }

    init(id: UUID = UUID(),
         name: String,
         ecid: String,
         udid: String? = nil,
         deviceType: String? = nil,
         systemName: String? = nil,
         locationID: Int? = nil,
         lastSeen: Date? = nil) {
        self.id = id
        self.name = name
        self.ecid = ecid
        self.udid = udid
        self.deviceType = deviceType
        self.systemName = systemName
        self.locationID = locationID
        self.lastSeen = lastSeen
    }
}

@Observable
class DeviceStorageManager {
    private let storageKey = "SavedDevices"
    var devices: [DeviceInfo] = []

    init() {
        loadDevices()
    }

    func loadDevices() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([DeviceInfo].self, from: data) {
            devices = decoded
        } else {
            // Migration: Check if old single ECID exists
            if let oldECID = UserDefaults.standard.string(forKey: "Phone_ECID"),
               !oldECID.isEmpty,
               isValidECID(oldECID) {
                devices = [DeviceInfo(name: "My iPhone", ecid: oldECID)]
                saveDevices()
            }
        }
    }

    func saveDevices() {
        if let encoded = try? JSONEncoder().encode(devices) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    func addDevice(_ device: DeviceInfo) {
        devices.append(device)
        saveDevices()
    }

    func updateDevice(_ device: DeviceInfo) {
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index] = device
            saveDevices()
        }
    }

    func deleteDevice(_ device: DeviceInfo) {
        devices.removeAll { $0.id == device.id }
        saveDevices()
    }

    func deleteDevices(at offsets: IndexSet) {
        devices.remove(atOffsets: offsets)
        saveDevices()
    }

    func findDevice(byECID ecid: String) -> DeviceInfo? {
        devices.first { $0.ecid.lowercased() == ecid.lowercased() }
    }

    /// Auto-save or update a detected device
    /// Preserves user's custom name while updating auto-detected metadata
    func saveOrUpdateDevice(_ detectedDevice: DeviceInfo) {
        if let existingIndex = devices.firstIndex(where: { $0.ecid.lowercased() == detectedDevice.ecid.lowercased() }) {
            // Device exists - update metadata, preserve user's custom name
            var existing = devices[existingIndex]

            // Update auto-detected fields
            existing.udid = detectedDevice.udid
            existing.deviceType = detectedDevice.deviceType
            existing.systemName = detectedDevice.systemName
            existing.locationID = detectedDevice.locationID
            existing.lastSeen = detectedDevice.lastSeen

            // Only update name if user hasn't set a custom one
            if existing.name.isEmpty || existing.name == "My iPhone" {
                existing.name = detectedDevice.systemName ?? ""
            }

            devices[existingIndex] = existing
        } else {
            // New device - add it with system name as default
            var newDevice = detectedDevice
            newDevice.name = detectedDevice.systemName ?? "My Device"
            devices.append(newDevice)
        }

        saveDevices()
    }

    /// Batch save or update multiple detected devices
    func saveOrUpdateDevices(_ detectedDevices: [DeviceInfo]) {
        for device in detectedDevices {
            saveOrUpdateDevice(device)
        }
    }

    private func isValidECID(_ ecid: String) -> Bool {
        let trimmed = ecid.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^0x[0-9A-Fa-f]{13,16}$"
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }
}
