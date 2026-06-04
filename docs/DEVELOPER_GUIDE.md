# Developer Guide

## Table of Contents

1. [Development Environment Setup](#development-environment-setup)
2. [Project Structure](#project-structure)
3. [Architecture Patterns](#architecture-patterns)
4. [Development Workflow](#development-workflow)
5. [Testing Strategy](#testing-strategy)
6. [Contributing Guidelines](#contributing-guidelines)
7. [Code Style and Standards](#code-style-and-standards)
8. [Debugging and Profiling](#debugging-and-profiling)
9. [Release Process](#release-process)
10. [Extension Points](#extension-points)

## Development Environment Setup

### Prerequisites

- **Xcode**: Version 15.0 or later
- **macOS**: Version 15.0 (Sequoia) or later for deployment target
- **Swift**: Version 5.9+ (included with Xcode)
- **Git**: For version control
- **Apple Configurator 2**: For cfgutil dependency testing

### Clone and Setup

```bash
git clone <repository-url>
cd IOS_IPA_Install
open "IOS IPA Install.xcodeproj"
```

### Project Configuration

#### Build Settings

- **Deployment Target**: macOS 15.0
- **Swift Language Version**: Swift 5
- **Code Signing**: Development team configuration required
- **App Sandbox**: Enabled with minimal entitlements

#### Dependencies

The project uses Swift Package Manager for dependency management:

```swift
// Package.swift equivalent configuration
dependencies: [
    .package(url: "https://github.com/alexrozanski/Coquille.git", from: "0.3.0")
]
```

**Dependency Overview**:
- **Coquille**: Modern Swift process execution library
  - Async/await support
  - Real-time output streaming
  - Type-safe command construction

### IDE Configuration

#### Recommended Xcode Settings

```
Editor > Format > Swift
- Indent: 4 spaces
- Line length: 120 characters
- Organize imports on save

Build Settings > Swift Compiler
- Strict Concurrency Checking: Complete
- Swift Language Version: 5
```

#### Code Analysis

Enable all Swift compiler warnings:
- Treat warnings as errors in CI/release builds
- Enable strict concurrency checking
- Use SwiftLint for additional style enforcement (optional)

## Project Structure

### File Organization

```
IOS IPA Install/
├── IPA_InstallApp.swift          # Main app entry point
├── Models/
│   ├── IPADocument.swift         # Document model for .ipa files
│   └── ProcessModel.swift        # Business logic and process management
├── Views/
│   ├── ShellOutputView.swift     # Main installation interface
│   └── SettingsView.swift        # ECID configuration interface
├── Resources/
│   ├── Assets.xcassets/          # Images and icons
│   ├── Info.plist               # App configuration
│   └── IPA_Install.entitlements # Sandbox permissions
└── Preview Content/              # SwiftUI preview assets
```

### Architecture Layers

1. **Presentation Layer**: SwiftUI views and view models
2. **Business Logic Layer**: ProcessModel and validation logic
3. **Data Layer**: Document handling and persistence
4. **Integration Layer**: External tool communication (cfgutil)

### Dependency Graph

```
IPA_InstallApp
    ├── ShellOutputView
    │   ├── ProcessModel
    │   └── SettingsView (via AppStorage)
    ├── SettingsView
    └── IPADocument
```

## Architecture Patterns

### Observable Pattern

Uses Swift's new `@Observable` macro for reactive programming:

```swift
@Observable
class ProcessModel {
    var output: String = ""
    var isProcessing: Bool = false
    // UI automatically updates when these properties change
}
```

**Benefits**:
- Automatic UI updates
- Type-safe observation
- Minimal boilerplate
- Better performance than traditional Combine

### Document-Based Architecture

Leverages SwiftUI's DocumentGroup for file handling:

```swift
DocumentGroup(viewing: IPADocument.self) { fileConfig in
    ShellOutputView(url: fileConfig.fileURL)
}
```

**Advantages**:
- Built-in file association
- Automatic document management
- System integration (Recent Documents, etc.)
- Sandboxing compliance

### Error Handling Strategy

Structured error handling with user-friendly messages:

```swift
enum ProcessError: LocalizedError {
    case invalidECID(String)
    case cfgutilNotFound
    
    var errorDescription: String? {
        // Provide clear, actionable error messages
    }
}
```

**Pattern Benefits**:
- Centralized error definitions
- Localization support
- Type-safe error handling
- Clear error propagation

### Async/Await Integration

Modern concurrency for process execution:

```swift
func process(url: URL, ecid: String) async {
    await MainActor.run {
        isProcessing = true
    }
    
    do {
        try await runInstallation(...)
    } catch {
        await handleError(error)
    }
}
```

## Development Workflow

### Git Workflow

#### Branch Strategy

```bash
main              # Production-ready code
├── dev          # Development integration
├── feature/*    # Feature development
├── bugfix/*     # Bug fixes
└── hotfix/*     # Critical production fixes
```

#### Commit Message Format

```
type(scope): description

[optional body]

[optional footer]
```

**Types**: feat, fix, docs, style, refactor, test, chore

**Examples**:
```
feat(process): add device connectivity validation
fix(ui): correct ECID validation regex pattern
docs(readme): update installation instructions
```

### Development Tasks

#### Setting Up Development

```bash
# Clone repository
git clone <repo-url>
cd IOS_IPA_Install

# Open in Xcode
open "IOS IPA Install.xcodeproj"

# Build and run
⌘R in Xcode
```

#### Common Development Tasks

**Add New Features**:
1. Create feature branch: `git checkout -b feature/new-feature`
2. Implement changes following architecture patterns
3. Add tests for new functionality
4. Update documentation
5. Create pull request

**Debug Installation Issues**:
1. Enable verbose logging in ProcessModel
2. Test with various IPA files and device configurations
3. Monitor cfgutil output for specific error patterns
4. Use Xcode debugger for UI state inspection

**Update Dependencies**:
1. Update Package.resolved in Xcode
2. Test compatibility with new versions
3. Update documentation if APIs change

### Code Generation

#### SwiftUI Previews

Use previews for rapid UI development:

```swift
#Preview {
    SettingsView()
        .frame(width: 450, height: 300)
}
```

#### Localization Support

Prepare for future internationalization:

```swift
Text("Installation completed successfully!")
    .localized() // When localization is added
```

## Testing Strategy

### Unit Testing

#### Test Structure

```swift
@testable import IOS_IPA_Install
import XCTest

final class ProcessModelTests: XCTestCase {
    var processModel: ProcessModel!
    
    override func setUp() {
        processModel = ProcessModel()
    }
    
    func testValidECID() {
        XCTAssertTrue(processModel.isValidECID("0x1234567890ABCD"))
        XCTAssertFalse(processModel.isValidECID("invalid"))
    }
}
```

#### Testing Categories

1. **ECID Validation Tests**
   - Valid format testing
   - Invalid format edge cases
   - Boundary conditions (13-16 hex digits)

2. **Process Model Tests**
   - State management verification
   - Error handling validation
   - Async operation testing

3. **Document Model Tests**
   - File validation logic
   - Error condition handling
   - UTType registration

#### Mock Testing

Create mocks for external dependencies:

```swift
class MockCfgutil {
    static func simulateInstallation() -> AsyncStream<String> {
        // Return mock installation output
    }
}
```

### Integration Testing

#### End-to-End Testing

1. **File Association Testing**
   - Test .ipa file opening
   - Verify document initialization
   - Validate UI state transitions

2. **Process Execution Testing**
   - Mock cfgutil interactions
   - Test error scenarios
   - Verify output streaming

3. **Settings Persistence Testing**
   - AppStorage functionality
   - Settings validation
   - UI state synchronization

### UI Testing

#### SwiftUI Testing

```swift
func testSettingsView() {
    let view = SettingsView()
    // Test view rendering and interaction
}
```

#### Accessibility Testing

- VoiceOver navigation
- Keyboard accessibility
- Color contrast validation
- Text scaling support

### Performance Testing

#### Memory Usage

- Monitor memory growth during long installations
- Verify proper cleanup after process completion
- Test with large IPA files

#### Responsiveness

- Ensure UI remains responsive during processing
- Test auto-scroll performance
- Validate async operation efficiency

## Contributing Guidelines

### Code Review Process

#### Pull Request Requirements

1. **Description**: Clear explanation of changes and motivation
2. **Testing**: Evidence of testing (unit tests, manual testing)
3. **Documentation**: Updated documentation for user-facing changes
4. **Screenshots**: UI changes require before/after screenshots

#### Review Checklist

- [ ] Code follows project style guidelines
- [ ] Changes include appropriate tests
- [ ] Documentation is updated
- [ ] No breaking changes without justification
- [ ] Error handling is comprehensive
- [ ] Performance impact is considered

### Issue Management

#### Bug Reports

```markdown
**Bug Description**: Clear description of the issue
**Steps to Reproduce**: 
1. Step one
2. Step two
3. Expected vs actual behavior

**Environment**:
- macOS version
- Xcode version
- Device information
- IPA file characteristics

**Logs**: Relevant console output or error messages
```

#### Feature Requests

```markdown
**Feature Description**: What should be added/changed
**Use Case**: Why is this feature needed
**Proposed Solution**: How should it work
**Alternatives**: Other approaches considered
```

### Development Standards

#### Code Quality

1. **Swift Style Guide**: Follow Swift API Design Guidelines
2. **SwiftUI Best Practices**: Use proper state management
3. **Error Handling**: Comprehensive error coverage
4. **Documentation**: Clear comments for complex logic
5. **Testing**: High test coverage for critical paths

#### Security Considerations

1. **Input Validation**: Sanitize all user inputs
2. **Process Execution**: Validate command arguments
3. **File Access**: Use secure file handling practices
4. **Sandboxing**: Minimal privilege principles

## Code Style and Standards

### Swift Conventions

#### Naming

```swift
// Good
class ProcessModel { }
func validateECID(_ ecid: String) -> Bool { }
var isProcessing: Bool = false

// Avoid
class processModel { } // PascalCase for types
func validate_ecid(_ ecid: String) -> Bool { } // camelCase for functions
var is_processing: Bool = false // camelCase for variables
```

#### Error Handling

```swift
// Preferred: Structured error types
enum ProcessError: LocalizedError {
    case invalidECID(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidECID(let ecid):
            return "Invalid ECID format: \(ecid)"
        }
    }
}

// Avoid: Generic errors
throw NSError(domain: "Error", code: 1, userInfo: nil)
```

#### Async/Await

```swift
// Good: Proper async function design
func process(url: URL, ecid: String) async throws {
    try await performValidation()
    try await executeInstallation()
}

// Avoid: Callback-based async
func process(url: URL, ecid: String, completion: @escaping (Result<Void, Error>) -> Void)
```

### SwiftUI Patterns

#### View Composition

```swift
// Good: Composed views with single responsibility
var body: some View {
    VStack {
        statusBar
        outputDisplay
        errorBanner
    }
}

private var statusBar: some View { /* ... */ }
private var outputDisplay: some View { /* ... */ }
```

#### State Management

```swift
// Good: Appropriate state scope
@State private var showingHelp = false        // View-local state
@AppStorage("Phone_ECID") private var ecid   // Persistent state
@Observable class ProcessModel { }           // Shared business logic
```

### Documentation Standards

#### Code Comments

```swift
/// Validates device ECID format using regex pattern
/// - Parameter ecid: Device Electronic Chip ID
/// - Returns: true if format is valid (0x followed by 13-16 hex digits)
private func isValidECID(_ ecid: String) -> Bool {
    let pattern = "^0x[0-9A-Fa-f]{13,16}$"
    return ecid.range(of: pattern, options: .regularExpression) != nil
}
```

#### README Updates

- Keep feature list current
- Update installation instructions
- Maintain troubleshooting section
- Document new dependencies

## Debugging and Profiling

### Xcode Debugging

#### Breakpoint Strategies

```swift
// Conditional breakpoints for specific scenarios
if ecid.contains("invalid") {
    // Breakpoint here for debugging invalid ECID handling
    print("Debug: Invalid ECID detected")
}
```

#### Debug Console

```swift
// Use structured logging
private let logger = Logger(subsystem: "IOS IPA Install", category: "ProcessModel")

logger.debug("Starting installation process for \(url.lastPathComponent)")
logger.error("Installation failed: \(error.localizedDescription)")
```

### Performance Profiling

#### Instruments Integration

1. **Time Profiler**: Monitor CPU usage during installation
2. **Allocations**: Track memory usage patterns
3. **Leaks**: Verify proper memory cleanup
4. **Network**: Monitor any network activity (if applicable)

#### Performance Metrics

- App launch time
- UI responsiveness during processing
- Memory usage with large files
- Process execution overhead

### Logging Strategy

#### OSLog Categories

```swift
private let logger = Logger(subsystem: "IOS IPA Install", category: "ProcessModel")
private let uiLogger = Logger(subsystem: "IOS IPA Install", category: "UI")
private let documentLogger = Logger(subsystem: "IOS IPA Install", category: "Document")
```

#### Log Levels

- **Debug**: Development information
- **Info**: General application flow
- **Error**: Error conditions requiring attention
- **Fault**: Critical failures

### Common Debugging Scenarios

#### Process Execution Issues

1. Enable verbose cfgutil output
2. Log command arguments before execution
3. Monitor process exit codes
4. Capture and log stderr output

#### UI State Problems

1. Use SwiftUI inspector in Xcode
2. Add logging to view lifecycle methods
3. Monitor observable property changes
4. Verify state synchronization

## Release Process

### Version Management

#### Semantic Versioning

```
MAJOR.MINOR.PATCH
1.0.0 - Initial release
1.0.1 - Bug fix release
1.1.0 - New feature release
2.0.0 - Breaking changes
```

#### Release Branches

```bash
# Create release branch
git checkout -b release/1.1.0

# Finalize changes
git commit -m "chore: prepare release 1.1.0"

# Merge to main
git checkout main
git merge release/1.1.0
git tag v1.1.0
```

### Build Configuration

#### Release Build Settings

```xml
<!-- Info.plist updates for release -->
<key>CFBundleVersion</key>
<string>1.1.0</string>
<key>CFBundleShortVersionString</key>
<string>1.1.0</string>
```

#### Code Signing

- Configure development team
- Use appropriate provisioning profiles
- Enable hardened runtime for distribution

### Distribution

#### Developer Distribution

1. Archive build in Xcode
2. Export for Developer ID distribution
3. Notarize with Apple
4. Create distribution package

#### Testing

- Test on clean macOS installation
- Verify cfgutil dependency detection
- Test with various .ipa files
- Validate error scenarios

### Release Checklist

- [ ] Version numbers updated
- [ ] Release notes prepared
- [ ] Testing completed
- [ ] Documentation updated
- [ ] Build signed and notarized
- [ ] Distribution package created
- [ ] Release tagged in Git

## Extension Points

### Future Enhancement Areas

#### Multi-Device Support

```swift
// Potential extension for multiple devices
struct DeviceManager {
    func listConnectedDevices() async -> [Device]
    func installToDevice(_ device: Device, ipa: URL) async throws
}
```

#### Batch Installation

```swift
// Batch processing capability
struct BatchInstaller {
    func installIPAs(_ ipas: [URL], to devices: [Device]) async throws
}
```

#### Custom Tool Integration

```swift
// Support for alternative installation tools
protocol InstallationTool {
    func install(ipa: URL, to device: Device) async throws
}

class IDeviceInstaller: InstallationTool { /* ... */ }
class CFGUtilInstaller: InstallationTool { /* ... */ }
```

### Plugin Architecture

#### Command Line Integration

```swift
// Potential CLI interface
struct CLIInterface {
    func install(ipa: String, ecid: String) async throws
    func listDevices() async throws -> [Device]
}
```

#### Integration APIs

```swift
// External app integration
public class IPAInstallAPI {
    public static func install(ipa: URL, ecid: String) async throws
    public static func validateECID(_ ecid: String) -> Bool
}
```

### Testing Infrastructure

#### Automated Testing

```swift
// UI automation for regression testing
class AutomatedTests {
    func testInstallationFlow() async throws
    func testErrorScenarios() async throws
    func testSettingsConfiguration() async throws
}
```

#### Mock Services

```swift
// Development and testing mocks
class MockCFGUtil: InstallationTool {
    func simulateSuccess() { /* ... */ }
    func simulateFailure() { /* ... */ }
    func simulateDeviceNotFound() { /* ... */ }
}
```

This developer guide provides comprehensive information for anyone contributing to or extending the iOS IPA Install project. It covers all aspects from environment setup through advanced extension points, ensuring consistent development practices and code quality.