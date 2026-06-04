# Technical Architecture Documentation

## Overview

iOS IPA Install is a macOS SwiftUI application that provides a graphical interface for installing iOS Package Archive (.ipa) files to development devices using Apple's `cfgutil` command-line tool.

## Architecture Components

### 1. Application Entry Point

**File**: `IPA_InstallApp.swift`

The main application uses SwiftUI's document-based app architecture:

```swift
@main
struct IPA_InstallApp: App {
    var body: some Scene {
        DocumentGroup(viewing: IPADocument.self) { fileConfig in
            ShellOutputView(url: fileConfig.fileURL)
        }
        Settings {
            SettingsView()
        }
    }
}
```

**Key Features:**
- Document-based architecture for handling .ipa files
- Integrated settings panel for ECID configuration
- File association with .ipa files for "Open with" functionality

### 2. Document Model

**File**: `IPADocument.swift`

Implements SwiftUI's `FileDocument` protocol for handling .ipa files:

```swift
struct IPADocument: FileDocument {
    static var readableContentTypes: [UTType] { [.ipa] }
    // Read-only implementation - doesn't read file contents
    // Only validates file accessibility for path-based operations
}
```

**Key Features:**
- Custom UTType definition for .ipa files
- Read-only document model (no file editing)
- File validation without content reading
- Comprehensive error handling with `IPADocumentError` enum

**Error Types:**
- `notImplementedError`: For unsupported operations
- `invalidFileFormat`: For malformed .ipa files
- `fileAccessError`: For file system access issues

### 3. Process Management

**File**: `ProcessModel.swift`

Core business logic using the Observable pattern:

```swift
@Observable
class ProcessModel {
    var output: String = ""
    var isProcessing: Bool = false
    var lastError: ProcessError?
}
```

**Key Responsibilities:**
- ECID validation using regex patterns
- cfgutil path detection across common locations
- Device connectivity verification
- IPA installation process management
- Real-time output streaming

**Process Flow:**
1. **Input Validation**: ECID format and file existence
2. **Tool Detection**: Locate cfgutil in standard paths
3. **Device Check**: Verify device connectivity via cfgutil
4. **Installation**: Execute cfgutil install-app command
5. **Output Streaming**: Real-time stdout/stderr capture

**Error Handling:**
- `invalidECID`: Regex validation for 0x[13-16 hex digits]
- `cfgutilNotFound`: Tool availability checking
- `deviceNotFound`: Connectivity verification
- `installationFailed`: Process execution errors

### 4. User Interface

#### Main View - `ShellOutputView.swift`

Primary interface combining status display and output streaming:

**Components:**
- **Status Bar**: Shows processing state, ECID configuration
- **Output Display**: Monospaced, scrollable terminal-like output
- **Error Banner**: Prominent error display with context
- **Auto-scroll**: Automatic scrolling to latest output

**State Management:**
- Reactive to ProcessModel changes
- AppStorage integration for ECID persistence
- Automatic process initiation on file load

#### Settings View - `SettingsView.swift`

Device configuration interface:

**Features:**
- ECID input field with real-time validation
- Visual validation feedback (green checkmark/orange warning)
- Contextual help popover with ECID location instructions
- Persistent storage via AppStorage

**Validation Logic:**
```swift
let pattern = "^0x[0-9A-Fa-f]{13,16}$"
```

### 5. External Dependencies

#### Coquille Framework

**Purpose**: Modern Swift process execution library
**Version**: 0.3.0
**Repository**: https://github.com/alexrozanski/Coquille.git

**Usage Benefits:**
- Async/await process execution
- Real-time stdout/stderr streaming
- Better error handling than Foundation.Process
- Type-safe command construction

**Integration Example:**
```swift
let process = Process(
    command: .init(cfgutilPath, arguments: ["--ecid", ecid, "install-app", path]),
    stdout: { stdout in Task { await self.updateOutput(stdout) } },
    stderr: { stderr in Task { await self.updateOutput(stderr) } }
)
```

## Data Flow Architecture

```
User Interaction
       ↓
   Document Open (.ipa file)
       ↓
   IPADocument Validation
       ↓
   ShellOutputView Initialization
       ↓
   ProcessModel.process() Execution
       ↓
   cfgutil Command Execution
       ↓
   Real-time Output Streaming
       ↓
   UI Updates (Observable Pattern)
```

## File Type Associations

**Info.plist Configuration:**
- Document type: `com.apple.itunes.ipa`
- Role: Viewer (read-only)
- Handler rank: Alternate
- File extension: `.ipa`

## Security Considerations

### Input Validation
- ECID format validation prevents command injection
- File path validation ensures .ipa file integrity
- Process argument sanitization via Coquille framework

### Sandboxing
- App Sandbox entitlements (empty entitlements file)
- File access limited to user-selected documents
- No network access required

### External Tool Dependency
- Relies on system-installed cfgutil
- Path validation prevents arbitrary command execution
- Error handling for missing dependencies

## Performance Characteristics

### Memory Usage
- Minimal memory footprint (SwiftUI + small models)
- Streaming output prevents large memory accumulation
- Observable pattern for efficient UI updates

### Process Execution
- Asynchronous operation prevents UI blocking
- Real-time output streaming for user feedback
- Proper process cleanup and error handling

### File Handling
- Document-based architecture for efficient file management
- No file content loading (path-only operations)
- Lazy loading patterns for better performance

## Deployment Architecture

### Build Configuration
- **Target Platform**: macOS 15.0+
- **Swift Version**: 5.9+
- **Xcode Version**: 15+
- **Deployment Target**: macOS Sequoia and later

### App Distribution
- Designed for development environment usage
- Requires Apple Configurator 2 installation
- No App Store distribution (uses private APIs)

### System Integration
- File association registration
- macOS Services integration potential
- Command-line tool dependency management

## Error Recovery Patterns

### Graceful Degradation
- Missing cfgutil: Clear error message with installation instructions
- Device disconnection: Retry suggestions and troubleshooting
- Invalid files: Format validation and user guidance

### User Experience
- Non-blocking error display
- Contextual help for common issues
- Progress indicators for long-running operations

### Logging Strategy
- OSLog integration for system-level logging
- Structured logging with categories
- Debug information for troubleshooting

## Extensibility Points

### Future Enhancements
- Multiple device support
- Installation history
- Batch installation capabilities
- Custom cfgutil path configuration
- Installation script generation

### Plugin Architecture Potential
- Process execution abstraction
- Custom validation rules
- Extended file type support
- Integration with other development tools