# API and Code Documentation

## Swift Files Documentation

### 1. IPA_InstallApp.swift

Main application entry point implementing SwiftUI App protocol.

#### `IPA_InstallApp`

```swift
@main
struct IPA_InstallApp: App
```

**Description**: Main application structure using document-based architecture.

**Properties**:
- `body: some Scene` - Application scene configuration

**Scene Configuration**:
- **DocumentGroup**: Handles .ipa file associations and viewing
- **Settings**: Provides access to ECID configuration

**Usage**:
```swift
DocumentGroup(viewing: IPADocument.self) { fileConfig in
    ShellOutputView(url: fileConfig.fileURL)
}
```

---

### 2. IPADocument.swift

Document model for handling iOS Package Archive files.

#### `UTType Extension`

```swift
extension UTType {
    static var ipa: UTType {
        UTType(importedAs: "com.apple.itunes.ipa")
    }
}
```

**Description**: Extends UTType to support .ipa file recognition.

#### `IPADocumentError`

```swift
enum IPADocumentError: LocalizedError
```

**Cases**:
- `.notImplementedError(String)` - For unsupported operations
- `.invalidFileFormat` - When file format is invalid
- `.fileAccessError` - When file cannot be accessed

**Properties**:
- `errorDescription: String?` - Localized error descriptions

#### `IPADocument`

```swift
struct IPADocument: FileDocument
```

**Description**: Document model conforming to FileDocument protocol for .ipa files.

**Properties**:
- `text: String` - Document content placeholder
- `static var readableContentTypes: [UTType]` - Supported file types

**Initializers**:
```swift
init(text: String = "")
init(configuration: ReadConfiguration) throws
```

**Methods**:
```swift
func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper
```

**Usage Notes**:
- Read-only implementation (writing throws `notImplementedError`)
- Validates file accessibility without reading contents
- Designed for path-based operations with cfgutil

---

### 3. ProcessModel.swift

Core business logic for IPA installation process management.

#### `ProcessError`

```swift
enum ProcessError: LocalizedError
```

**Cases**:
- `.invalidECID(String)` - ECID format validation failure
- `.cfgutilNotFound` - cfgutil tool not available
- `.invalidIPAFile` - IPA file validation failure
- `.deviceNotFound` - Target device not connected
- `.installationFailed(String)` - Installation process failure

**Properties**:
- `errorDescription: String?` - Detailed error descriptions with guidance

#### `ProcessModel`

```swift
@Observable
class ProcessModel
```

**Description**: Observable model managing the IPA installation process.

**Properties**:
```swift
var output: String = ""           // Real-time process output
var isProcessing: Bool = false    // Processing state flag
var lastError: ProcessError?      // Last encountered error
```

**Private Properties**:
```swift
private let cfgutilPaths = [      // Common cfgutil installation paths
    "/usr/local/bin/cfgutil",
    "/usr/bin/cfgutil", 
    "/opt/homebrew/bin/cfgutil"
]
```

**Public Methods**:

##### `process(url: URL, ecid: String) async`

**Description**: Main processing method for IPA installation.

**Parameters**:
- `url: URL` - Path to the .ipa file
- `ecid: String` - Target device ECID

**Process Flow**:
1. Input validation (ECID format, file existence)
2. cfgutil tool detection
3. Device connectivity verification
4. IPA installation execution
5. Real-time output streaming

**Error Handling**: Catches and handles all ProcessError types.

**Private Methods**:

##### `validateInputs(url: URL, ecid: String) throws`

**Description**: Validates input parameters before processing.

**Validation Checks**:
- ECID format using regex pattern
- File existence verification
- .ipa extension validation

##### `isValidECID(_ ecid: String) -> Bool`

**Description**: Validates ECID format using regular expressions.

**Pattern**: `^0x[0-9A-Fa-f]{13,16}$`
- Must start with "0x"
- Followed by 13-16 hexadecimal digits
- Case-insensitive hex validation

##### `findCfgutil() throws -> String`

**Description**: Locates cfgutil executable in common installation paths.

**Search Paths**:
1. `/usr/local/bin/cfgutil` (manual installation)
2. `/usr/bin/cfgutil` (system installation)
3. `/opt/homebrew/bin/cfgutil` (Homebrew installation)

**Returns**: Full path to cfgutil executable
**Throws**: `ProcessError.cfgutilNotFound` if not found

##### `checkDeviceConnectivity(cfgutilPath: String, ecid: String) async throws`

**Description**: Verifies target device is connected and accessible.

**Process Execution**:
```swift
cfgutil --ecid [ECID] list
```

**Error Handling**: Throws `ProcessError.deviceNotFound` on failure

##### `runInstallation(cfgutilPath: String, url: URL, ecid: String) async throws`

**Description**: Executes the IPA installation process.

**Command Execution**:
```swift
cfgutil --ecid [ECID] install-app [IPA_PATH]
```

**Features**:
- Real-time stdout/stderr streaming
- Asynchronous execution using Coquille
- Progress updates via output streaming

##### `updateOutput(_ text: String) async`

**Description**: Thread-safe output updating on main actor.

**Usage**: Called from process output streams to update UI.

##### `handleError(_ error: ProcessError) async`

**Description**: Centralized error handling with logging and UI updates.

**Actions**:
- Updates `lastError` property
- Appends error to output stream
- Logs error using OSLog

---

### 4. SettingsView.swift

SwiftUI view for device ECID configuration.

#### `SettingsView`

```swift
struct SettingsView: View
```

**Description**: Settings interface for device configuration.

**Properties**:
```swift
@AppStorage("Phone_ECID") private var ecid = "0x1234567890ABCD"  // Persistent ECID storage
@State private var isValidECID = true                           // Validation state
@State private var showingHelp = false                         // Help popover state
```

**Layout Structure**:
- **Device Configuration Section**: ECID input with validation
- **About ECID Section**: Information and guidance
- **Help Popover**: Detailed ECID location instructions

**Methods**:

##### `validateECID(_ value: String)`

**Description**: Real-time ECID validation with visual feedback.

**Validation Logic**:
- Trims whitespace
- Applies regex pattern: `^0x[0-9A-Fa-f]{13,16}$`
- Updates validation state for UI feedback

**Visual Feedback**:
- Green checkmark for valid ECID
- Orange warning for invalid format
- Descriptive error messages

##### `helpContent: some View`

**Description**: Comprehensive help content for ECID discovery.

**Content Sections**:
- iOS Settings method
- Apple Configurator 2 method  
- Xcode method
- Format examples

**UI Configuration**:
- Fixed frame size: 450x300
- Form-based layout
- Navigation title integration

---

### 5. ShellOutputView.swift

Main interface view combining output display and status monitoring.

#### `ShellOutputView`

```swift
struct ShellOutputView: View
```

**Description**: Primary user interface for IPA installation process.

**Properties**:
```swift
@State var model = ProcessModel()                    // Process management model
@AppStorage("Phone_ECID") private var ecid = ""     // Device ECID from settings
var url: URL?                                       // IPA file URL
```

**Layout Components**:

##### `statusBar: some View`

**Description**: Top status bar showing processing state and configuration.

**Status Indicators**:
- **Processing**: Progress indicator with "Installing..." text
- **Error**: Warning icon with "Installation Failed" text  
- **Complete**: Checkmark with "Ready" text
- **ECID Display**: Shows current ECID or "Not Set"

**Styling**:
- Control background color
- Separator border
- Horizontal padding and vertical spacing

##### `errorBanner(_ error: ProcessError) -> some View`

**Description**: Prominent error display banner.

**Features**:
- Orange warning icon
- Error title and description
- Orange-themed background and border
- Rounded corner styling

**Layout**:
- Horizontal stack with icon, text, and spacer
- Vertical text stack for title and description
- Background with opacity and stroke overlay

**Main View Structure**:

```swift
VStack(spacing: 0) {
    statusBar
    ScrollViewReader { proxy in
        ScrollView {
            // Error banner (conditional)
            // Output text display
        }
    }
}
```

**Features**:
- **Auto-scroll**: Automatic scrolling to latest output
- **Text Selection**: Enabled for output copying
- **Monospaced Font**: Terminal-like appearance
- **Real-time Updates**: Reactive to model changes

**Lifecycle Methods**:

##### `onAppear`

**Description**: Handles view initialization and automatic processing.

**Logic**:
- Checks for valid URL and ECID configuration
- Automatically starts installation process
- Shows configuration warning if ECID not set

**Auto-start Conditions**:
```swift
if let url, !ecid.isEmpty {
    Task { await model.process(url: url, ecid: ecid) }
}
```

---

## Data Models and Types

### Uniform Type Identifiers (UTI)

```swift
static var ipa: UTType {
    UTType(importedAs: "com.apple.itunes.ipa")
}
```

**Purpose**: Enables macOS file association and "Open with" functionality.

### AppStorage Integration

```swift
@AppStorage("Phone_ECID") private var ecid: String
```

**Purpose**: Persistent storage for device ECID across app launches.

### Observable Pattern

```swift
@Observable
class ProcessModel
```

**Purpose**: Reactive UI updates using Swift's observation framework.

## Error Handling Patterns

### Comprehensive Error Types

All error enums conform to `LocalizedError` for user-friendly messages:

```swift
var errorDescription: String? {
    switch self {
    case .invalidECID(let ecid):
        return "Invalid ECID format: \(ecid). Expected format: 0x[16 hex digits]"
    // Additional cases...
    }
}
```

### Async Error Propagation

```swift
do {
    try await runInstallation(...)
} catch let error as ProcessError {
    await handleError(error)
} catch {
    await handleError(.installationFailed(error.localizedDescription))
}
```

### UI Error Display

- Non-blocking error banners
- Status indicators
- Contextual error messages
- Recovery suggestions

## Integration Patterns

### Process Execution with Coquille

```swift
let process = Process(
    command: .init(cfgutilPath, arguments: ["--ecid", ecid, "install-app", path]),
    stdout: { stdout in
        Task { await self.updateOutput(stdout) }
    },
    stderr: { stderr in
        Task { await self.updateOutput(stderr) }
    }
)
```

### SwiftUI + Combine Integration

- `@Observable` for reactive data flow
- `@AppStorage` for persistence
- `@State` for view-local state management
- `Task` for async operations

### File System Integration

- Document-based app architecture
- UTType declarations for file associations
- Secure file access through user selection