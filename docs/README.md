# iOS IPA Install - Documentation Overview

## Project Overview

iOS IPA Install is a modern macOS application built with SwiftUI that provides a user-friendly interface for installing iOS Package Archive (.ipa) files to development devices. The application leverages Apple's `cfgutil` command-line tool while providing comprehensive error handling, real-time progress monitoring, and intuitive device management.

## Documentation Structure

### 📋 [Technical Architecture](./TECHNICAL_ARCHITECTURE.md)
Comprehensive overview of the application's technical design, architecture patterns, and component relationships.

**Key Topics:**
- SwiftUI document-based architecture
- Observable pattern implementation
- Process execution with Coquille framework
- Error handling strategies
- Security considerations
- Performance characteristics

### 🔧 [API and Code Documentation](./API_DOCUMENTATION.md)
Detailed documentation of all Swift files, classes, methods, and data structures.

**Coverage:**
- Complete API reference for all source files
- Method signatures and parameter descriptions
- Error handling patterns
- Integration examples
- Data flow explanations

### 👥 [User Guide](./USER_GUIDE.md)
Complete guide for end users, from installation through troubleshooting.

**Includes:**
- System requirements and installation steps
- ECID configuration and device setup
- Step-by-step installation procedures
- Comprehensive troubleshooting guide
- UI descriptions and screenshots guidance

### 🛠 [Developer Guide](./DEVELOPER_GUIDE.md)
Essential information for developers contributing to or extending the project.

**Contains:**
- Development environment setup
- Architecture patterns and best practices
- Testing strategies and code quality standards
- Contributing guidelines and review process
- Extension points and future enhancement areas

### 🚀 [Build and Deployment](./BUILD_DEPLOYMENT.md)
Complete guide for building, signing, and distributing the application.

**Details:**
- Build environment configuration
- Code signing and notarization processes
- Distribution methods (DMG, PKG, direct)
- Continuous integration setup
- Troubleshooting build issues

## Quick Start

### For Users
1. Read the [User Guide](./USER_GUIDE.md#installation) for installation instructions
2. Configure your device ECID following the [setup guide](./USER_GUIDE.md#initial-setup)
3. Start installing IPA files using the [installation procedures](./USER_GUIDE.md#installing-ipa-files)

### For Developers
1. Follow the [Developer Guide](./DEVELOPER_GUIDE.md#development-environment-setup) for environment setup
2. Review the [Technical Architecture](./TECHNICAL_ARCHITECTURE.md) to understand the codebase
3. Check the [API Documentation](./API_DOCUMENTATION.md) for detailed code references
4. Use the [Build Guide](./BUILD_DEPLOYMENT.md) for compilation and distribution

## Project Structure

```
IOS_IPA_Install/
├── docs/                           # Documentation
│   ├── README.md                   # This overview
│   ├── TECHNICAL_ARCHITECTURE.md  # Architecture documentation
│   ├── API_DOCUMENTATION.md       # Code API reference
│   ├── USER_GUIDE.md              # End-user guide
│   ├── DEVELOPER_GUIDE.md         # Developer information
│   └── BUILD_DEPLOYMENT.md        # Build and deployment
├── IOS IPA Install/               # Source code
│   ├── IPA_InstallApp.swift       # Main app entry point
│   ├── IPADocument.swift          # Document model
│   ├── ProcessModel.swift         # Business logic
│   ├── ShellOutputView.swift      # Main UI
│   ├── SettingsView.swift         # Settings interface
│   ├── Assets.xcassets/           # Images and icons
│   ├── Info.plist                 # App configuration
│   └── IPA_Install.entitlements   # Sandbox permissions
├── IOS IPA Install.xcodeproj/     # Xcode project
└── README.md                      # Main project README
```

## Key Features

### 🎯 User-Focused Features
- **Drag & Drop Installation**: Right-click any .ipa file and select "Open with iOS IPA Install"
- **Real-time Progress**: Live installation output with status indicators
- **Device Management**: Simple ECID configuration with validation
- **Error Handling**: Clear, actionable error messages with troubleshooting guidance
- **Automatic Detection**: Finds cfgutil installation automatically

### 🏗 Technical Features
- **Modern SwiftUI**: Document-based app architecture
- **Async Processing**: Non-blocking installation with real-time output streaming
- **Process Management**: Robust execution using Coquille framework
- **Input Validation**: Comprehensive ECID and file validation
- **Logging Integration**: OSLog for system-level debugging
- **Sandbox Compliance**: Secure file access and minimal permissions

## Technology Stack

### Core Technologies
- **SwiftUI**: Modern declarative UI framework
- **Swift 5.9+**: Modern Swift with async/await support
- **macOS 15.0+**: Latest macOS features and APIs
- **Xcode 15+**: Development environment

### Dependencies
- **[Coquille 0.3.0](https://github.com/alexrozanski/Coquille)**: Modern Swift process execution
- **Apple Configurator 2**: Provides cfgutil command-line tool
- **OSLog**: System logging framework

### External Tools
- **cfgutil**: Apple's device management tool
- **Code Signing**: Apple Developer certificates
- **Notarization**: Apple's app validation service

## Architecture Highlights

### Observable Pattern
```swift
@Observable
class ProcessModel {
    var output: String = ""
    var isProcessing: Bool = false
    // Automatic UI updates when properties change
}
```

### Document-Based Design
```swift
DocumentGroup(viewing: IPADocument.self) { fileConfig in
    ShellOutputView(url: fileConfig.fileURL)
}
```

### Async Process Execution
```swift
let process = Process(
    command: .init(cfgutilPath, arguments: ["--ecid", ecid, "install-app", path]),
    stdout: { stdout in Task { await self.updateOutput(stdout) } },
    stderr: { stderr in Task { await self.updateOutput(stderr) } }
)
```

## Getting Started

### Prerequisites
- macOS 15.0 (Sequoia) or later
- Xcode 15.0 or later (for development)
- Apple Configurator 2 (for cfgutil)
- iOS development device

### Installation
1. **For Users**: Download the application and follow the [User Guide](./USER_GUIDE.md)
2. **For Developers**: Clone the repository and follow the [Developer Guide](./DEVELOPER_GUIDE.md)

### First Steps
1. Install Apple Configurator 2 from the Mac App Store
2. Configure your device ECID in application settings
3. Connect your iOS device via USB
4. Right-click any .ipa file and select "Open with iOS IPA Install"

## Support and Troubleshooting

### Common Issues
- **ECID Configuration**: See [ECID setup guide](./USER_GUIDE.md#configure-your-device-ecid)
- **cfgutil Not Found**: Install [Apple Configurator 2](./USER_GUIDE.md#step-1-install-prerequisites)
- **Device Not Connected**: Check [troubleshooting section](./USER_GUIDE.md#troubleshooting)
- **Installation Failures**: Review [error handling guide](./USER_GUIDE.md#installation-failed-errors)

### Development Issues
- **Build Problems**: Check [build troubleshooting](./BUILD_DEPLOYMENT.md#troubleshooting)
- **Code Signing**: Review [signing guide](./BUILD_DEPLOYMENT.md#code-signing-and-notarization)
- **Testing Setup**: Follow [testing strategies](./DEVELOPER_GUIDE.md#testing-strategy)

## Contributing

We welcome contributions! Please see the [Developer Guide](./DEVELOPER_GUIDE.md#contributing-guidelines) for:
- Code style guidelines
- Pull request process
- Testing requirements
- Documentation standards

### Quick Contributing Steps
1. Fork the repository
2. Create a feature branch
3. Follow the coding standards in the Developer Guide
4. Add tests for new functionality
5. Update documentation as needed
6. Submit a pull request

## License and Legal

This project is designed for iOS development workflows and requires:
- Apple Developer account for code signing
- Apple Configurator 2 for cfgutil dependency
- Compliance with Apple's developer program terms

## Documentation Maintenance

### Keeping Documentation Current
- Update version numbers in all guides when releasing
- Add new troubleshooting scenarios as they're discovered
- Update dependency versions and requirements
- Maintain screenshot descriptions for UI changes

### Documentation Standards
- Use clear, concise language
- Include code examples where helpful
- Maintain consistent formatting across all documents
- Update table of contents when adding sections

---

**Last Updated**: [Current Date]
**Documentation Version**: 1.0.0
**Application Version**: 1.0.0

For the most current information, always refer to the latest version of this documentation in the project repository.