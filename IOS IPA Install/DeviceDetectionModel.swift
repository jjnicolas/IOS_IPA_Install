import Coquille
import Foundation
import Observation
import OSLog

private let logger = Logger(subsystem: "IOS IPA Installer", category: "DeviceDetection")

// cfgutil JSON response structure
struct CfgutilResponse: Decodable {
    let Command: String
    let Output: [String: CfgutilDevice]
    let `Type`: String
    let Devices: [String]
}

struct CfgutilDevice: Decodable {
    let locationID: Int?
    let UDID: String
    let ECID: String
    let name: String?
    let deviceType: String?
}

struct ConnectedDevice: Identifiable {
    let id = UUID()
    let deviceInfo: DeviceInfo
    let isConnected: Bool
}

@Observable
class DeviceDetectionModel {
    var connectedDevices: [ConnectedDevice] = []
    var isScanning: Bool = false
    var scanError: String?

    private let cfgutilPaths = [
        "/usr/local/bin/cfgutil",
        "/usr/bin/cfgutil",
        "/opt/homebrew/bin/cfgutil",
        // Bundled locations, used when "Install Automation Tools" was never run
        "/Applications/Apple Configurator.app/Contents/MacOS/cfgutil",
        "/Applications/Apple Configurator 2.app/Contents/MacOS/cfgutil"
    ]

    func scanForDevices(deviceManager: DeviceStorageManager) async {
        // Set scanning state immediately on main actor
        isScanning = true
        scanError = nil
        connectedDevices = []

        do {
            let cfgutilPath = try findCfgutil()

            let detectedDevices = try await getConnectedDevices(cfgutilPath: cfgutilPath)

            // AUTO-SAVE all detected devices
            await MainActor.run {
                deviceManager.saveOrUpdateDevices(detectedDevices)
            }

            // Build connected device list (all detected = all connected)
            let connected = detectedDevices.map { device in
                ConnectedDevice(deviceInfo: device, isConnected: true)
            }

            await MainActor.run {
                connectedDevices = connected
                isScanning = false
            }

            logger.info("Device scan complete. Found \(connected.count) devices")

        } catch {
            await MainActor.run {
                scanError = error.localizedDescription
                isScanning = false
            }
            logger.error("Device scan failed: \(error.localizedDescription)")
        }
    }

    func checkDeviceConnection(ecid: String) async -> Bool {
        do {
            let cfgutilPath = try findCfgutil()
            return await isDeviceConnected(cfgutilPath: cfgutilPath, ecid: ecid)
        } catch {
            logger.error("Failed to check device connection: \(error.localizedDescription)")
            return false
        }
    }

    private func findCfgutil() throws -> String {
        for path in cfgutilPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        throw ProcessError.cfgutilNotFound
    }

    /// Get connected devices with full metadata from cfgutil JSON output
    /// Falls back to legacy text parsing if JSON is not supported
    private func getConnectedDevices(cfgutilPath: String) async throws -> [DeviceInfo] {
        let task = Foundation.Process()
        task.executableURL = URL(fileURLWithPath: cfgutilPath)
        task.arguments = ["--format", "JSON", "list"]

        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = Pipe()

        try task.run()
        task.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let outputString = String(data: outputData, encoding: .utf8) ?? ""

        guard !outputString.isEmpty, let jsonData = outputString.data(using: .utf8) else {
            logger.warning("cfgutil JSON output empty, falling back to legacy parsing")
            return try await getConnectedDevicesLegacy(cfgutilPath: cfgutilPath)
        }

        do {
            let response = try JSONDecoder().decode(CfgutilResponse.self, from: jsonData)

            return response.Output.map { (_, device) in
                DeviceInfo(
                    name: "",
                    ecid: device.ECID,
                    udid: device.UDID,
                    deviceType: device.deviceType,
                    systemName: device.name,
                    locationID: device.locationID,
                    lastSeen: Date()
                )
            }
        } catch {
            logger.warning("JSON decoding failed: \(error.localizedDescription), falling back to legacy parsing")
            return try await getConnectedDevicesLegacy(cfgutilPath: cfgutilPath)
        }
    }

    /// Legacy fallback for older cfgutil versions without JSON support
    private func getConnectedDevicesLegacy(cfgutilPath: String) async throws -> [DeviceInfo] {
        let task = Foundation.Process()
        task.executableURL = URL(fileURLWithPath: cfgutilPath)
        task.arguments = ["list"]

        let outputPipe = Pipe()
        task.standardOutput = outputPipe

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            throw ProcessError.deviceNotFound
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let outputString = String(data: outputData, encoding: .utf8) ?? ""
        let outputLines = outputString.split(separator: "\n").map(String.init)
        let ecids = parseECIDsFromOutput(outputLines)

        return ecids.map { ecid in
            DeviceInfo(
                name: "",
                ecid: ecid,
                lastSeen: Date()
            )
        }
    }

    private func parseECIDsFromOutput(_ lines: [String]) -> [String] {
        var ecids: [String] = []

        for line in lines {
            // cfgutil list output typically shows ECID in format like:
            // "ECID: 0x1234567890ABCD"
            if let range = line.range(of: "ECID:\\s*(0x[0-9A-Fa-f]+)", options: .regularExpression) {
                let ecidString = String(line[range])
                if let ecidValue = ecidString.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) {
                    ecids.append(ecidValue)
                }
            }
            // Also check for ECID in plain format
            else if let range = line.range(of: "0x[0-9A-Fa-f]{13,16}", options: .regularExpression) {
                let ecid = String(line[range])
                if !ecids.contains(ecid) {
                    ecids.append(ecid)
                }
            }
        }

        return ecids
    }

    private func matchDevices(detected: [String], known: [DeviceInfo]) -> [ConnectedDevice] {
        var matched: [ConnectedDevice] = []

        for detectedECID in detected {
            if let device = known.first(where: { $0.ecid.lowercased() == detectedECID.lowercased() }) {
                matched.append(ConnectedDevice(deviceInfo: device, isConnected: true))
            }
        }

        return matched
    }

    private func isDeviceConnected(cfgutilPath: String, ecid: String) async -> Bool {
        let process = Process(
            command: .init(cfgutilPath, arguments: ["--ecid", ecid, "list"]),
            stdout: { _ in },
            stderr: { _ in }
        )

        do {
            _ = try await process.run()
            return true
        } catch {
            return false
        }
    }
}
