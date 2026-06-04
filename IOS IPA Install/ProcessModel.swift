import Coquille
import Foundation
import Observation
import OSLog

private let logger = Logger(subsystem: "IOS IPA Installer", category: "Extension")

enum ProcessError: LocalizedError {
    case invalidECID(String)
    case cfgutilNotFound
    case invalidIPAFile
    case deviceNotFound
    case installationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidECID(let ecid):
            return "Invalid ECID format: \(ecid). Expected format: 0x[16 hex digits]"
        case .cfgutilNotFound:
            return "cfgutil not found. Please install Apple Configurator 2 or ensure cfgutil is in PATH"
        case .invalidIPAFile:
            return "Invalid or corrupted IPA file"
        case .deviceNotFound:
            return "Device not found or not connected"
        case .installationFailed(let reason):
            return "Installation failed: \(reason)"
        }
    }
}

@Observable
class ProcessModel {
    var output: String = ""
    var isProcessing: Bool = false
    var lastError: ProcessError?
    var installationSucceeded: Bool = false

    private let cfgutilPaths = [
        "/usr/local/bin/cfgutil",
        "/usr/bin/cfgutil",
        "/opt/homebrew/bin/cfgutil"
    ]

    func process(url: URL, ecid: String) async {
        await MainActor.run {
            isProcessing = true
            lastError = nil
            installationSucceeded = false
            output = "Preparing installation...\n\n"
        }

        do {
            try validateInputs(url: url, ecid: ecid)

            let cfgutilPath = try findCfgutil()
            await updateOutput("Found cfgutil at: \(cfgutilPath)\n")

            await updateOutput("Installing \(url.lastPathComponent) on device \(ecid)...\n\n")

            let success = try await runInstallation(cfgutilPath: cfgutilPath, url: url, ecid: ecid)

            await MainActor.run {
                installationSucceeded = success
            }

            if success {
                await updateOutput("\n✅ Installation completed successfully!")
            } else {
                throw ProcessError.installationFailed("Installation process completed but did not succeed. Check output for details.")
            }

        } catch let error as ProcessError {
            await handleError(error)
        } catch {
            await handleError(.installationFailed(error.localizedDescription))
        }

        await MainActor.run {
            isProcessing = false
        }
    }
    
    private func validateInputs(url: URL, ecid: String) throws {
        guard isValidECID(ecid) else {
            throw ProcessError.invalidECID(ecid)
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ProcessError.invalidIPAFile
        }
        
        guard url.pathExtension.lowercased() == "ipa" else {
            throw ProcessError.invalidIPAFile
        }
    }
    
    private func isValidECID(_ ecid: String) -> Bool {
        let trimmed = ecid.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^0x[0-9A-Fa-f]{13,16}$"
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }
    
    private func findCfgutil() throws -> String {
        for path in cfgutilPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        throw ProcessError.cfgutilNotFound
    }

    private func runInstallation(cfgutilPath: String, url: URL, ecid: String) async throws -> Bool {
        let path = url.path(percentEncoded: false)
        logger.info("Installing \(path) to device \(ecid)")

        var capturedOutput: String = ""

        let process = Process(
            command: .init(cfgutilPath, arguments: ["--ecid", ecid, "install-app", path]),
            stdout: { stdout in
                capturedOutput += stdout
                Task { await self.updateOutput(stdout) }
            },
            stderr: { stderr in
                capturedOutput += stderr
                Task { await self.updateOutput(stderr) }
            }
        )

        do {
            _ = try await process.run()

            // Process completed without throwing (exit code 0)
            // Check output for error indicators
            let outputLower = capturedOutput.lowercased()
            let errorIndicators = [
                "error:",
                "failed",
                "could not install",
                "installation failed",
                "unable to install",
                "not found",
                "denied",
                "rejected"
            ]

            for indicator in errorIndicators {
                if outputLower.contains(indicator) {
                    return false
                }
            }

            // Check for success indicators
            let successIndicators = [
                "installed",
                "complete",
                "success"
            ]

            for indicator in successIndicators {
                if outputLower.contains(indicator) {
                    return true
                }
            }

            // If no clear indicators, assume success if exit code was 0
            return true

        } catch {
            throw ProcessError.installationFailed(error.localizedDescription)
        }
    }
    
    private func updateOutput(_ text: String) async {
        await MainActor.run {
            output += text
        }
    }
    
    private func handleError(_ error: ProcessError) async {
        await MainActor.run {
            lastError = error
            output += "\n❌ \(error.localizedDescription)\n"
        }
        logger.error("\(error.localizedDescription)")
    }
}
