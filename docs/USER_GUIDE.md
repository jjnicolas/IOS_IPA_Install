# iOS IPA Install - User Guide

## Table of Contents

1. [Overview](#overview)
2. [System Requirements](#system-requirements)
3. [Installation](#installation)
4. [Initial Setup](#initial-setup)
5. [Installing IPA Files](#installing-ipa-files)
6. [Settings Configuration](#settings-configuration)
7. [Troubleshooting](#troubleshooting)
8. [Screenshots and UI Guide](#screenshots-and-ui-guide)

## Overview

iOS IPA Install is a macOS application that simplifies the process of installing iOS Package Archive (.ipa) files to development devices. It provides a user-friendly graphical interface for Apple's `cfgutil` command-line tool, making iOS app installation accessible without terminal commands.

### Key Features

- **Drag & Drop Installation**: Simple right-click installation from Finder
- **Real-time Progress**: Live installation progress with detailed output
- **Device Management**: Easy ECID configuration for targeted installations
- **Error Handling**: Clear error messages with troubleshooting guidance
- **Validation**: Automatic format checking and device connectivity verification

## System Requirements

### Minimum Requirements

- **Operating System**: macOS 15.0 (Sequoia) or later
- **Hardware**: Any Mac capable of running macOS Sequoia
- **Development Tools**: Apple Configurator 2 (provides cfgutil)
- **Device**: iOS device connected via USB cable

### Recommended Setup

- **Xcode**: Latest version for development workflow integration
- **iOS Device**: In Developer Mode for app installation
- **USB Cable**: Reliable Lightning/USB-C cable for stable connection

## Installation

### Step 1: Install Prerequisites

1. **Install Apple Configurator 2**
   - Open the Mac App Store
   - Search for "Apple Configurator 2"
   - Click "Get" to install the free application
   - Wait for installation to complete

2. **Verify cfgutil Installation**
   - Apple Configurator 2 automatically installs cfgutil
   - The app will automatically detect cfgutil in common locations:
     - `/usr/local/bin/cfgutil`
     - `/usr/bin/cfgutil`
     - `/opt/homebrew/bin/cfgutil`

### Step 2: Install iOS IPA Install

1. **Download the Application**
   - Obtain the iOS IPA Install.app from your distribution source
   - Move the application to your Applications folder

2. **First Launch**
   - Double-click to launch the application
   - macOS may show a security warning for first-time launch
   - If prompted, go to System Settings > Privacy & Security and click "Open Anyway"

## Initial Setup

### Configure Your Device ECID

Before installing any IPA files, you must configure your device's ECID (Electronic Chip ID).

#### Finding Your Device ECID

**Method 1: iOS Device Settings**
1. Open Settings on your iOS device
2. Navigate to General > About
3. Scroll down to find "ECID"
4. Note the value (format: 0x followed by hex digits)

**Method 2: Apple Configurator 2**
1. Connect your iOS device via USB
2. Open Apple Configurator 2
3. Select your device from the list
4. View device information to find ECID

**Method 3: Xcode**
1. Open Xcode
2. Go to Window > Devices and Simulators
3. Select your connected device
4. Find ECID in the device information panel

#### Setting ECID in iOS IPA Install

1. Launch iOS IPA Install
2. Go to "iOS IPA Install" menu > Settings (or press ⌘,)
3. Enter your device ECID in the text field
4. Verify the green checkmark appears (indicates valid format)
5. Close the settings window

**ECID Format Requirements:**
- Must start with "0x"
- Followed by 13-16 hexadecimal digits
- Example: `0x1234567890ABCD`

## Installing IPA Files

### Method 1: Right-Click Installation (Recommended)

1. **Locate Your IPA File**
   - Open Finder and navigate to your .ipa file
   - Ensure the file has a .ipa extension

2. **Open with iOS IPA Install**
   - Right-click on the .ipa file
   - Select "Open With" > "iOS IPA Install"
   - If not available, choose "Other..." and select iOS IPA Install

3. **Monitor Installation**
   - The application window opens automatically
   - View real-time installation progress
   - Wait for "Installation completed successfully!" message

### Method 2: Drag and Drop

1. **Launch iOS IPA Install**
   - Open the application from Applications folder

2. **Drag IPA File**
   - Drag your .ipa file onto the application window
   - Installation begins automatically

### Installation Process Details

#### Status Indicators

**Top Status Bar:**
- **Installing...**: Shows progress indicator during installation
- **Installation Failed**: Red warning when errors occur
- **Ready**: Green checkmark when installation completes
- **ECID Display**: Shows configured device ECID

#### Real-time Output

The main window displays:
- Preparation messages
- cfgutil tool detection
- Device connectivity verification
- Installation progress
- Success or error messages

#### Typical Installation Flow

```
Preparing installation...

Found cfgutil at: /usr/local/bin/cfgutil
Checking device connectivity...
✓ Device connected
Installing YourApp.ipa on device 0x1234567890ABCD...

[Installation progress output]

✅ Installation completed successfully!
```

## Settings Configuration

### Device Configuration Section

**ECID Input Field:**
- Enter your device's Electronic Chip ID
- Real-time format validation
- Visual feedback (green checkmark or orange warning)
- Persistent storage across app sessions

**Help Button:**
- Click the "?" icon for detailed ECID finding instructions
- Popover with step-by-step guidance
- Multiple method explanations

### About ECID Section

Informational panel explaining:
- What ECID is and why it's needed
- Common locations to find ECID
- Format requirements and examples

### Settings Persistence

All settings are automatically saved and persist between app launches using macOS UserDefaults.

## Troubleshooting

### Common Issues and Solutions

#### "Invalid ECID format" Error

**Problem**: ECID doesn't match required format
**Solution**: 
- Verify ECID starts with "0x"
- Ensure 13-16 hexadecimal digits follow
- Check for typos or extra characters
- Copy directly from device settings to avoid errors

#### "cfgutil not found" Error

**Problem**: Apple Configurator 2 not installed or cfgutil not accessible
**Solutions**:
- Install Apple Configurator 2 from Mac App Store
- Restart terminal/applications after installation
- Check if cfgutil exists at common paths
- Reinstall Apple Configurator 2 if necessary

#### "Device not found or not connected" Error

**Problem**: Target device not accessible via cfgutil
**Solutions**:
- Verify USB cable connection
- Unlock iOS device and trust computer if prompted
- Ensure device is not sleeping or locked
- Try different USB port or cable
- Restart both Mac and iOS device
- Check device is in Developer Mode (iOS 16+)

#### "Installation failed" Errors

**Problem**: IPA installation process failed
**Common Causes & Solutions**:

1. **Provisioning Issues**
   - Ensure IPA is properly signed for your device
   - Check provisioning profile includes your device UDID
   - Verify certificate is valid and not expired

2. **Device Storage**
   - Free up space on iOS device
   - Remove old test builds of the same app

3. **App Already Installed**
   - Delete existing version of app from device
   - Clear app data if necessary

4. **Developer Mode**
   - Enable Developer Mode on iOS 16+ devices
   - Go to Settings > Privacy & Security > Developer Mode

#### "Invalid or corrupted IPA file" Error

**Problem**: IPA file is malformed or inaccessible
**Solutions**:
- Verify file integrity (not corrupted during download/transfer)
- Ensure file has .ipa extension
- Try re-downloading or re-building the IPA
- Check file permissions (readable by user)

### Advanced Troubleshooting

#### Verbose Output Analysis

Monitor the detailed output in the main window for specific error messages:
- CFBundleIdentifier conflicts
- Code signing issues
- Device compatibility problems
- Network connectivity issues

#### Manual cfgutil Testing

Test cfgutil directly in Terminal:
```bash
/usr/local/bin/cfgutil --ecid 0xYOUR_ECID list
/usr/local/bin/cfgutil --ecid 0xYOUR_ECID install-app /path/to/your.ipa
```

#### Log File Locations

macOS system logs may contain additional information:
- Console.app > Log Reports
- Search for "cfgutil" or "iOS IPA Install"

### Getting Help

#### Application Logs

iOS IPA Install uses OSLog for system-level logging:
- Open Console.app
- Filter by process "iOS IPA Install"
- Look for error messages and stack traces

#### Reset Settings

To reset all application settings:
1. Quit iOS IPA Install
2. Open Terminal
3. Run: `defaults delete com.yourcompany.ios-ipa-install`
4. Restart the application

## Screenshots and UI Guide

### Main Application Window

**Description**: The primary interface showing installation progress

**Elements**:
- **Navigation Title**: Shows IPA file name or "IPA Installer"
- **Status Bar**: Top section with processing state and ECID display
  - Progress indicator during installation
  - Status icons (processing/error/success)
  - ECID configuration display
- **Output Area**: Large scrollable text area with monospaced font
  - Real-time command output
  - Installation progress messages
  - Error details and success confirmations
- **Error Banner**: Orange-highlighted error display (when applicable)
  - Warning icon
  - Error title and detailed description

### Settings Window

**Description**: Device configuration interface

**Elements**:
- **Device Configuration Section**:
  - ECID input field with placeholder text
  - Help button (question mark icon) with popover
  - Validation feedback (green checkmark or orange warning)
  - Format requirements display
- **About ECID Section**:
  - Informational text about ECID purpose
  - List of methods to find ECID
  - Step-by-step instructions

### Help Popover

**Description**: Contextual help for ECID configuration

**Content**:
- "Finding Your Device ECID" header
- Three methods with detailed steps:
  - iOS Settings path
  - Apple Configurator 2 instructions
  - Xcode device window guidance
- Format explanation with example
- Compact, focused information display

### Status Indicators

**Processing State**:
- Animated progress indicator
- "Installing..." text
- Grayed out elements during processing

**Success State**:
- Green checkmark icon
- "Ready" status text
- Completion message in output

**Error State**:
- Orange warning triangle
- "Installation Failed" text
- Error banner with details

### File Association

**Finder Integration**:
- Right-click context menu on .ipa files
- "Open With" > "iOS IPA Install" option
- Application icon appears for associated files

**Application Icon**:
- Custom app icon design
- Multiple resolutions for different contexts
- Clear visual association with iOS development

### Output Formatting

**Text Characteristics**:
- Monospaced font for terminal-like appearance
- Text selection enabled for copying
- Auto-scrolling to latest output
- Preserved formatting from cfgutil output
- Color coding for different message types (when applicable)

**Message Types**:
- Preparation and status updates
- Tool detection confirmations
- Device connectivity results
- Installation progress details
- Success confirmations with checkmark emoji
- Error messages with warning emoji

This comprehensive user guide covers all aspects of using iOS IPA Install, from initial setup through troubleshooting common issues. The application is designed to be intuitive, but this guide provides the detailed information needed for successful iOS app installation on development devices.