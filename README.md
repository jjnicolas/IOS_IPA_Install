# iOS IPA Install

A macOS application for installing iOS Package Archive (.ipa) files to development devices using Apple's `cfgutil` command-line tool. Features automatic device detection and friendly device names - just like Apple Configurator.

## 📚 Complete Documentation

**Comprehensive documentation is available in the [docs](./docs/) directory:**

- 📋 **[Technical Architecture](./docs/TECHNICAL_ARCHITECTURE.md)** - System design and architecture patterns
- 🔧 **[API Documentation](./docs/API_DOCUMENTATION.md)** - Complete code reference and API guide
- 👥 **[User Guide](./docs/USER_GUIDE.md)** - Installation, setup, and usage instructions
- 🛠 **[Developer Guide](./docs/DEVELOPER_GUIDE.md)** - Contributing and development information
- 🚀 **[Build & Deployment](./docs/BUILD_DEPLOYMENT.md)** - Build, signing, and distribution guide

## Quick Start

### For Users
1. Install Apple Configurator 2 from Mac App Store
2. Connect your iOS device via USB
3. Right-click any .ipa file → "Open with iOS IPA Install"
4. Your device appears automatically with its model name (e.g., "iPhone 13 Pro")
5. Click "Install" - done!

**That's it!** No manual ECID entry or device configuration needed. Devices are auto-discovered and saved for future use.

### For Developers
The Xcode project is generated from [`project.yml`](project.yml) with [XcodeGen](https://github.com/yonaskolb/XcodeGen) — it is **not** committed.
```bash
brew install xcodegen        # one-time
git clone <repository-url>
cd IOS_IPA_Install
make app                     # generate the project and build a Debug app
make run                     # build + launch
```
Or run `make project` to just generate `IOS IPA Install.xcodeproj`, then open it in Xcode.

### Release

Signed, notarized, Sparkle-updating direct distribution:

```bash
make release NOTARY_PROFILE=<your-notarytool-keychain-profile>
```

This builds the Release app (Developer ID + hardened runtime), notarizes and staples it,
generates an EdDSA-signed [Sparkle](https://sparkle-project.org) appcast, then publishes the
zip and `appcast.xml` as assets on the public `IOS-IPA-Install-releases` GitHub release
(marked `--latest`, which is what `SUFeedURL` points at) and tags this repo. See the
[`Makefile`](Makefile) for the individual `dist-app` / `notarize` steps.

One-time setup: create the public releases repo with an initial commit —
`gh repo create jjnicolas/IOS-IPA-Install-releases --public --add-readme`.

## Key Features

### v1.1.0 - Automatic Device Detection 🆕
- **🔍 Zero-Configuration Discovery**: Devices auto-appear when connected - no manual ECID entry required
- **📱 Friendly Model Names**: See "iPhone 13 Pro" or "iPad Air" instead of cryptic device codes
- **💾 Auto-Save Devices**: Detected devices automatically save for future use
- **🏷️ Custom Device Names**: Optional aliases override auto-detected names
- **✅ Smart Status Detection**: Accurate success/failure detection based on cfgutil output
- **📊 Rich Metadata Display**: Shows device model, system name, UDID, and last seen time
- **🔄 Backward Compatible**: Seamlessly migrates v1.0.0 device configurations

### Core Features
- **🎯 Right-Click Installation**: Context menu integration for any .ipa file in Finder
- **🪟 Per-Device Windows**: Dedicated installation window for each device
- **⚡ Real-time Output**: Live installation progress and status updates
- **🛡 Error Handling**: Comprehensive error detection with clear guidance
- **⚙️ Settings Management**: Full CRUD operations for device configurations
- **🌐 Multi-Device Support**: Install to multiple devices simultaneously
- **🔄 Automatic Updates**: Built-in [Sparkle](https://sparkle-project.org) updater with a "Check for Updates…" menu command

## System Requirements

- **macOS**: 15.0 (Sequoia) or later
- **Tools**: Apple Configurator 2 (provides cfgutil)
- **Hardware**: iOS development device with USB connection
- **Development**: Xcode 15+, Swift 5.9+, and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Technology Stack

- **SwiftUI**: Modern declarative UI framework
- **Swift 5.9+**: Async/await concurrency and Observable pattern
- **[Coquille](https://github.com/alexrozanski/Coquille)**: Modern process execution library
- **cfgutil**: Apple's device management command-line tool

## Architecture Overview

Built with modern SwiftUI document-based architecture:

```swift
@Observable
class ProcessModel {
    // Real-time process management with async/await
}

DocumentGroup(viewing: IPADocument.self) { fileConfig in
    ShellOutputView(url: fileConfig.fileURL)
}
```

**Core Components:**
- **IPADocument**: File association and document handling
- **DeviceInfo & DeviceStorageManager**: Multi-device storage with auto-save support
- **DeviceDetectionModel**: Async device scanning with JSON/legacy parsing
- **DeviceTypeMapper**: Maps device codes (iPhone14,2) to friendly names (iPhone 13 Pro)
- **DeviceSelectionView**: Per-device installation interface with rich metadata
- **ProcessModel**: Business logic, cfgutil execution, and smart success detection
- **ShellOutputView**: Device detection panel with auto-discovery
- **SettingsView**: Multi-device CRUD with auto-detected device badges

## Quick Example

### Automatic Workflow (v1.1.0+)
Just plug in your device and open an IPA file - that's it! The app will:
1. Auto-detect your device ("iPhone 13 Pro" @ ECID 0x1234567890ABCD)
2. Show it with a green indicator
3. Auto-save it for future use
4. Let you customize the name in Settings if desired

### Manual Configuration (Optional)
You can still manually add devices if needed:

**ECID Format:**
```
Format: 0x[13-16 hex digits]
Example: 0x1234567890ABCD
```

**Find ECID:**
- iOS Settings → General → About → ECID
- Apple Configurator 2 → Device Information
- Xcode → Devices and Simulators

Manual entry is useful for pre-configuring devices before they're connected or adding custom aliases.

## Support

- 📖 **Documentation**: Comprehensive guides in [./docs/](./docs/)
- 🐛 **Issues**: Use GitHub Issues for bug reports
- 💡 **Features**: Feature requests welcome via GitHub Issues
- 🔧 **Troubleshooting**: See [User Guide](./docs/USER_GUIDE.md#troubleshooting)

## Contributing

We welcome contributions! See the [Developer Guide](./docs/DEVELOPER_GUIDE.md#contributing-guidelines) for:
- Development environment setup
- Code style and standards
- Testing requirements
- Pull request process

## License

This project is designed for iOS development workflows and requires compliance with Apple's developer program terms.
