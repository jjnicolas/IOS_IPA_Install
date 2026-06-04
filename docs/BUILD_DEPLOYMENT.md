# Build and Deployment Guide

## Table of Contents

1. [Build Environment Setup](#build-environment-setup)
2. [Project Configuration](#project-configuration)
3. [Dependencies Management](#dependencies-management)
4. [Build Process](#build-process)
5. [Code Signing and Notarization](#code-signing-and-notarization)
6. [Distribution Methods](#distribution-methods)
7. [Continuous Integration](#continuous-integration)
8. [Troubleshooting](#troubleshooting)

## Build Environment Setup

### Development Requirements

#### Hardware Requirements
- **Mac Computer**: Intel or Apple Silicon Mac
- **RAM**: Minimum 8GB, recommended 16GB+
- **Storage**: At least 10GB free space for Xcode and dependencies
- **macOS Version**: macOS 14.0 (Sonoma) or later for development

#### Software Requirements
- **Xcode**: Version 15.0 or later
- **Command Line Tools**: Latest version
- **Swift**: 5.9+ (included with Xcode)
- **Git**: For version control

#### Development Dependencies
- **Apple Configurator 2**: Required for cfgutil tool
- **Apple Developer Account**: For code signing (development or distribution)

### Environment Setup Steps

#### 1. Install Xcode

```bash
# Install from Mac App Store or
# Download from Apple Developer portal

# Verify installation
xcode-select --version
```

#### 2. Install Command Line Tools

```bash
xcode-select --install
```

#### 3. Configure Git (if not already done)

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

#### 4. Install Apple Configurator 2

```bash
# Install from Mac App Store
# This provides the cfgutil command-line tool
```

## Project Configuration

### Xcode Project Settings

#### General Settings

```
Target: IOS IPA Install
Bundle Identifier: com.yourcompany.ios-ipa-install
Version: 1.0.0
Build: 1
Deployment Target: macOS 15.0
```

#### Build Settings Key Configuration

```
PRODUCT_NAME = "IOS IPA Install"
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.ios-ipa-install
MACOSX_DEPLOYMENT_TARGET = 15.0
SWIFT_VERSION = 5.0
ENABLE_HARDENED_RUNTIME = YES
CODE_SIGN_ENTITLEMENTS = IOS IPA Install/IPA_Install.entitlements
```

#### Info.plist Configuration

**Document Types**: Registers .ipa file association
```xml
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>IPA</string>
        <key>CFBundleTypeRole</key>
        <string>Viewer</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>com.apple.itunes.ipa</string>
        </array>
    </dict>
</array>
```

**UTType Declarations**: Custom type definitions
```xml
<key>UTImportedTypeDeclarations</key>
<array>
    <dict>
        <key>UTTypeIdentifier</key>
        <string>com.apple.itunes.ipa</string>
        <key>UTTypeDescription</key>
        <string>IOS Package Archive</string>
        <key>UTTypeTagSpecification</key>
        <dict>
            <key>public.filename-extension</key>
            <array>
                <string>ipa</string>
            </array>
        </dict>
    </dict>
</array>
```

#### Entitlements Configuration

**IPA_Install.entitlements**: Minimal sandbox permissions
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict/>
</plist>
```

**For Distribution** (if needed):
```xml
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
</dict>
```

## Dependencies Management

### Swift Package Manager

#### Package.resolved Analysis

```json
{
  "pins" : [
    {
      "identity" : "coquille",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/alexrozanski/Coquille.git",
      "state" : {
        "revision" : "cb28716215a56760c66a4f635a1f71d6a2e2a42a",
        "version" : "0.3.0"
      }
    }
  ],
  "version" : 3
}
```

#### Adding Dependencies in Xcode

1. **Open Project**: `IOS IPA Install.xcodeproj`
2. **Select Project**: Click project name in navigator
3. **Package Dependencies**: Click "Package Dependencies" tab
4. **Add Package**: Click "+" button
5. **Enter URL**: `https://github.com/alexrozanski/Coquille.git`
6. **Version Rules**: "Up to Next Major Version" from 0.3.0

#### Dependency Update Process

```bash
# In Xcode: File > Packages > Update to Latest Package Versions
# Or manually update Package.resolved
```

### External Tool Dependencies

#### cfgutil Dependency

**Installation Paths** (checked by application):
```
/usr/local/bin/cfgutil
/usr/bin/cfgutil
/opt/homebrew/bin/cfgutil
```

**Verification Script**:
```bash
#!/bin/bash
# verify_dependencies.sh

echo "Checking cfgutil availability..."
for path in "/usr/local/bin/cfgutil" "/usr/bin/cfgutil" "/opt/homebrew/bin/cfgutil"; do
    if [ -f "$path" ]; then
        echo "✓ Found cfgutil at: $path"
        "$path" --version
        exit 0
    fi
done

echo "❌ cfgutil not found. Please install Apple Configurator 2."
exit 1
```

## Build Process

### Development Build

#### Quick Build and Run

```bash
# Command line build
xcodebuild -project "IOS IPA Install.xcodeproj" -scheme "IOS IPA Install" build

# Or in Xcode: ⌘R (Build and Run)
```

#### Clean Build

```bash
# Clean and build
xcodebuild -project "IOS IPA Install.xcodeproj" -scheme "IOS IPA Install" clean build

# Or in Xcode: ⇧⌘K (Clean), then ⌘B (Build)
```

### Release Build

#### Archive Creation

```bash
# Command line archive
xcodebuild -project "IOS IPA Install.xcodeproj" \
           -scheme "IOS IPA Install" \
           -archivePath "./build/IOS_IPA_Install.xcarchive" \
           archive

# Or in Xcode: Product > Archive
```

#### Build Configuration

**Release Settings**:
```
BUILD_CONFIGURATION = Release
CODE_SIGN_IDENTITY = "Developer ID Application: Your Name (TEAMID)"
ENABLE_HARDENED_RUNTIME = YES
```

### Build Scripts

#### Pre-build Validation

```bash
#!/bin/bash
# scripts/pre_build.sh

echo "Pre-build validation..."

# Check Xcode version
XCODE_VERSION=$(xcodebuild -version | head -n 1 | awk '{print $2}')
echo "Xcode version: $XCODE_VERSION"

# Verify dependencies
./scripts/verify_dependencies.sh

# Check code signing
security find-identity -v -p codesigning

echo "Pre-build validation complete."
```

#### Post-build Processing

```bash
#!/bin/bash
# scripts/post_build.sh

BUILD_DIR="$1"
PRODUCT_NAME="$2"

echo "Post-build processing..."

# Verify app bundle
echo "Verifying app bundle structure..."
ls -la "$BUILD_DIR/$PRODUCT_NAME.app/Contents/"

# Check code signing
echo "Verifying code signature..."
codesign --verify --verbose "$BUILD_DIR/$PRODUCT_NAME.app"

# Check entitlements
echo "Checking entitlements..."
codesign -d --entitlements - "$BUILD_DIR/$PRODUCT_NAME.app"

echo "Post-build processing complete."
```

## Code Signing and Notarization

### Development Code Signing

#### Certificate Requirements

1. **Apple Developer Account**: Required for code signing
2. **Developer ID Application Certificate**: For distribution outside App Store
3. **Team ID**: Associated with your developer account

#### Xcode Configuration

```
Signing & Capabilities:
- Team: [Your Development Team]
- Bundle Identifier: com.yourcompany.ios-ipa-install
- Signing Certificate: Apple Development / Developer ID Application
- Provisioning Profile: Xcode Managed Profile
```

#### Manual Code Signing

```bash
# Sign the application
codesign --force --options runtime --sign "Developer ID Application: Your Name (TEAMID)" \
         "IOS IPA Install.app"

# Verify signature
codesign --verify --verbose "IOS IPA Install.app"

# Check signature details
codesign -dv "IOS IPA Install.app"
```

### Distribution Code Signing

#### Hardened Runtime

**Entitlements for Hardened Runtime**:
```xml
<key>com.apple.security.cs.allow-jit</key>
<false/>
<key>com.apple.security.cs.allow-unsigned-executable-memory</key>
<false/>
<key>com.apple.security.cs.disable-library-validation</key>
<false/>
```

#### Notarization Process

**Step 1: Create App Archive**
```bash
# Create distributable archive
xcodebuild -exportArchive \
           -archivePath "./build/IOS_IPA_Install.xcarchive" \
           -exportOptionsPlist "./scripts/ExportOptions.plist" \
           -exportPath "./dist/"
```

**ExportOptions.plist**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

**Step 2: Create Distribution Package**
```bash
# Create ZIP for notarization
ditto -c -k --keepParent "IOS IPA Install.app" "IOS_IPA_Install.zip"
```

**Step 3: Submit for Notarization**
```bash
# Submit to Apple for notarization
xcrun notarytool submit "IOS_IPA_Install.zip" \
                --apple-id "your.email@example.com" \
                --password "app-specific-password" \
                --team-id "YOUR_TEAM_ID" \
                --wait
```

**Step 4: Staple Notarization**
```bash
# Staple the notarization ticket
xcrun stapler staple "IOS IPA Install.app"

# Verify notarization
xcrun stapler validate "IOS IPA Install.app"
```

### Automated Signing Script

```bash
#!/bin/bash
# scripts/sign_and_notarize.sh

set -e

APP_PATH="$1"
DEVELOPER_ID="$2"
APPLE_ID="$3"
APP_PASSWORD="$4"
TEAM_ID="$5"

echo "Signing application..."
codesign --force --options runtime --sign "$DEVELOPER_ID" "$APP_PATH"

echo "Creating distribution archive..."
ditto -c -k --keepParent "$APP_PATH" "${APP_PATH%.*}.zip"

echo "Submitting for notarization..."
xcrun notarytool submit "${APP_PATH%.*}.zip" \
                --apple-id "$APPLE_ID" \
                --password "$APP_PASSWORD" \
                --team-id "$TEAM_ID" \
                --wait

echo "Stapling notarization..."
xcrun stapler staple "$APP_PATH"

echo "Verifying final package..."
xcrun stapler validate "$APP_PATH"
codesign --verify --verbose "$APP_PATH"

echo "Build signed and notarized successfully!"
```

## Distribution Methods

### Direct Distribution

#### DMG Creation

```bash
#!/bin/bash
# scripts/create_dmg.sh

APP_NAME="IOS IPA Install"
VERSION="1.0.0"
DMG_NAME="IOS_IPA_Install_v${VERSION}"

# Create temporary directory
mkdir -p "./dmg_tmp"
cp -R "./dist/${APP_NAME}.app" "./dmg_tmp/"

# Create Applications link
ln -s /Applications "./dmg_tmp/Applications"

# Create DMG
hdiutil create -volname "$DMG_NAME" \
               -srcfolder "./dmg_tmp" \
               -ov -format UDZO \
               "./dist/${DMG_NAME}.dmg"

# Cleanup
rm -rf "./dmg_tmp"

echo "DMG created: ./dist/${DMG_NAME}.dmg"
```

#### ZIP Distribution

```bash
# Create ZIP archive for distribution
cd "./dist"
zip -r "IOS_IPA_Install_v1.0.0.zip" "IOS IPA Install.app"
```

### Package Installer

#### pkgbuild Creation

```bash
# Create installer package
pkgbuild --root "./dist" \
         --identifier "com.yourcompany.ios-ipa-install" \
         --version "1.0.0" \
         --install-location "/Applications" \
         "./dist/IOS_IPA_Install_Installer.pkg"
```

#### Advanced Package Options

**Component Property List**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>BundleIsRelocatable</key>
    <false/>
    <key>BundleIsVersionChecked</key>
    <true/>
    <key>BundleOverwriteAction</key>
    <string>upgrade</string>
</dict>
</plist>
```

### Homebrew Cask (Future)

**Cask Definition Example**:
```ruby
cask "ios-ipa-install" do
  version "1.0.0"
  sha256 "sha256_hash_here"
  
  url "https://github.com/yourcompany/ios-ipa-install/releases/download/v#{version}/IOS_IPA_Install_v#{version}.dmg"
  name "iOS IPA Install"
  desc "Install iOS IPA files to development devices"
  homepage "https://github.com/yourcompany/ios-ipa-install"
  
  app "IOS IPA Install.app"
end
```

## Continuous Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/build.yml
name: Build and Test

on:
  push:
    branches: [ main, dev ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Select Xcode Version
      run: sudo xcode-select -s /Applications/Xcode_15.0.app
    
    - name: Build
      run: |
        xcodebuild -project "IOS IPA Install.xcodeproj" \
                   -scheme "IOS IPA Install" \
                   -configuration Release \
                   build
    
    - name: Run Tests
      run: |
        xcodebuild -project "IOS IPA Install.xcodeproj" \
                   -scheme "IOS IPA Install" \
                   -configuration Debug \
                   test
    
    - name: Archive
      if: github.ref == 'refs/heads/main'
      run: |
        xcodebuild -project "IOS IPA Install.xcodeproj" \
                   -scheme "IOS IPA Install" \
                   -configuration Release \
                   -archivePath "./build/IOS_IPA_Install.xcarchive" \
                   archive
```

### Release Workflow

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build and Sign
      env:
        DEVELOPER_ID: ${{ secrets.DEVELOPER_ID }}
        APPLE_ID: ${{ secrets.APPLE_ID }}
        APP_PASSWORD: ${{ secrets.APP_PASSWORD }}
        TEAM_ID: ${{ secrets.TEAM_ID }}
      run: |
        # Build, sign, and notarize
        ./scripts/build_release.sh
    
    - name: Create Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
        draft: false
        prerelease: false
    
    - name: Upload Assets
      uses: actions/upload-release-asset@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        upload_url: ${{ steps.create_release.outputs.upload_url }}
        asset_path: ./dist/IOS_IPA_Install.dmg
        asset_name: IOS_IPA_Install.dmg
        asset_content_type: application/octet-stream
```

### Local CI Scripts

```bash
#!/bin/bash
# scripts/ci_build.sh

set -e

echo "Starting CI build process..."

# Clean previous builds
rm -rf ./build ./dist
mkdir -p ./build ./dist

# Pre-build validation
./scripts/pre_build.sh

# Build
echo "Building application..."
xcodebuild -project "IOS IPA Install.xcodeproj" \
           -scheme "IOS IPA Install" \
           -configuration Release \
           -derivedDataPath "./build/DerivedData" \
           build

# Test
echo "Running tests..."
xcodebuild -project "IOS IPA Install.xcodeproj" \
           -scheme "IOS IPA Install" \
           -configuration Debug \
           test

# Archive
echo "Creating archive..."
xcodebuild -project "IOS IPA Install.xcodeproj" \
           -scheme "IOS IPA Install" \
           -configuration Release \
           -archivePath "./build/IOS_IPA_Install.xcarchive" \
           archive

# Export
echo "Exporting application..."
xcodebuild -exportArchive \
           -archivePath "./build/IOS_IPA_Install.xcarchive" \
           -exportOptionsPlist "./scripts/ExportOptions.plist" \
           -exportPath "./dist/"

echo "CI build completed successfully!"
```

## Troubleshooting

### Common Build Issues

#### Swift Package Manager Issues

**Problem**: Package resolution failures
```bash
# Clear package cache
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf .build

# Reset packages in Xcode
# File > Packages > Reset Package Caches
```

**Problem**: Package version conflicts
```bash
# Update to latest compatible versions
# File > Packages > Update to Latest Package Versions
```

#### Code Signing Issues

**Problem**: Code signing identity not found
```bash
# List available identities
security find-identity -v -p codesigning

# Import certificates if needed
security import certificate.p12 -k ~/Library/Keychains/login.keychain
```

**Problem**: Provisioning profile issues
```bash
# Clean provisioning profiles
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*

# Re-download in Xcode
# Xcode > Preferences > Accounts > Download Manual Profiles
```

#### Build Path Issues

**Problem**: Spaces in paths causing build failures
```bash
# Ensure no spaces in project path
# Move project to path without spaces if necessary
mv "/path with spaces/project" "/path_without_spaces/project"
```

### Dependency Issues

#### cfgutil Not Found

**Diagnosis**:
```bash
# Check if Apple Configurator 2 is installed
ls -la /Applications/ | grep -i configurator

# Check cfgutil paths
which cfgutil
find /usr -name cfgutil 2>/dev/null
```

**Solutions**:
1. Install Apple Configurator 2 from Mac App Store
2. Restart applications after installation
3. Check PATH environment variable

#### Coquille Compilation Issues

**Problem**: Coquille build failures
```bash
# Check Swift version compatibility
swift --version

# Verify Xcode version
xcodebuild -version
```

**Solution**: Update to compatible versions as specified in Package.swift

### Performance Issues

#### Slow Build Times

**Optimization Strategies**:
```bash
# Use build system optimizations
xcodebuild -showBuildTimingSummary

# Clear derived data periodically
rm -rf ~/Library/Developer/Xcode/DerivedData
```

#### Memory Issues During Build

**Monitoring**:
```bash
# Monitor memory usage during build
top -pid $(pgrep xcodebuild)

# Increase available memory for build
# Close unnecessary applications
```

### Notarization Issues

#### Notarization Failures

**Common Issues**:
1. **Hardened Runtime**: Ensure proper entitlements
2. **Code Signing**: Verify Developer ID certificate
3. **App-specific Password**: Check credentials

**Debugging**:
```bash
# Check notarization status
xcrun notarytool history --apple-id "your.email@example.com" \
                        --password "app-password" \
                        --team-id "TEAM_ID"

# Get detailed notarization log
xcrun notarytool log "submission-id" \
                    --apple-id "your.email@example.com" \
                    --password "app-password" \
                    --team-id "TEAM_ID"
```

### Debug Information

#### Build Settings for Debugging

```
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
ENABLE_TESTABILITY = YES (Debug only)
GCC_OPTIMIZATION_LEVEL = 0 (Debug only)
SWIFT_OPTIMIZATION_LEVEL = -Onone (Debug only)
```

#### Crash Report Analysis

```bash
# Symbolicate crash reports
atos -o "IOS IPA Install.app/Contents/MacOS/IOS IPA Install" -l 0x100000000 0x100001234

# Or use Xcode for automatic symbolication
# Window > Organizer > Crashes
```

This comprehensive build and deployment guide covers all aspects of building, signing, and distributing the iOS IPA Install application, from development builds through production release processes.