# Quick Start Guide: TetherFlow Development

**Date**: 2026-02-05  
**Feature**: macOS Network Cloaking & Optimization Utility  
**Purpose**: Development environment setup and build instructions

---

## Prerequisites

### Required Software

| Tool | Version | Purpose | Download |
|------|---------|---------|----------|
| macOS | 13.0+ (Ventura) | Development OS | System Settings |
| Xcode | 15.0+ | IDE, Swift 6, macOS SDK | App Store |
| Swift | 6.0+ | Programming language | Bundled with Xcode |
| Apple Developer Account | Active | Code signing, SMJobBless | [developer.apple.com](https://developer.apple.com) |

### Optional Tools

| Tool | Purpose | Install |
|------|---------|---------|
| Homebrew | Package management | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |
| SwiftLint | Code style linting | `brew install swiftlint` |
| Git | Version control | Bundled with Xcode |

---

## Development Environment Setup

### Step 1: Clone Repository

```bash
git clone <repository-url>
cd TetherFlow
```

### Step 2: Configure Code Signing

This project requires proper code signing for SMJobBless to work.

#### 2.1 Open Project in Xcode

```bash
open TetherFlow.xcodeproj
```

#### 2.2 Configure Signing for Main App

1. Select `TetherFlow` target
2. Go to **Signing & Capabilities** tab
3. Select your **Team** from dropdown
4. Update **Bundle Identifier** if needed (format: `com.yourcompany.tetherflow`)

#### 2.3 Configure Signing for Helper Tool

1. Select `TetherFlowHelper` target
2. Go to **Signing & Capabilities** tab
3. Select the same **Team**
4. Set Bundle Identifier: `com.yourcompany.tetherflow.helper`

> **Important**: The helper bundle ID MUST be the main app bundle ID + ".helper"

#### 2.4 Update Info.plist References

Ensure these files have matching bundle IDs:

- `TetherFlow/Info.plist` → `CFBundleIdentifier`
- `TetherFlowHelper/Info.plist` → `CFBundleIdentifier`
- `TetherFlowHelper/Helper-Info.plist` → `CFBundleIdentifier`
- `HelperProtocol.h` → `kMainAppBundleIdentifier`, `kHelperBundleIdentifier`

### Step 3: Configure SMJobBless

#### 3.1 Create Launchd Plist

Create `Resources/Helper-Launchd.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.yourcompany.tetherflow.helper</string>
    <key>MachServices</key>
    <dict>
        <key>com.yourcompany.tetherflow.helper</key>
        <true/>
    </dict>
    <key>ProgramArguments</key>
    <array>
        <string>/Library/PrivilegedHelperTools/com.yourcompany.tetherflow.helper</string>
    </array>
</dict>
</plist>
```

#### 3.2 Add to Build Phases

1. Select `TetherFlow` target
2. Go to **Build Phases**
3. Add **Copy Files** phase:
   - Destination: `Wrapper`
   - Subpath: `Contents/Library/LaunchServices`
   - Add `Helper-Launchd.plist`

### Step 4: Build and Run

#### 4.1 Build Helper Tool First

```bash
# Build helper
xcodebuild -project TetherFlow.xcodeproj \
  -scheme TetherFlowHelper \
  -configuration Debug \
  build
```

#### 4.2 Build Main App

```bash
# Build main app
xcodebuild -project TetherFlow.xcodeproj \
  -scheme TetherFlow \
  -configuration Debug \
  build
```

#### 4.3 Run from Xcode

1. Select `TetherFlow` scheme
2. Press **Cmd+R** or click **Run**
3. First run will prompt for admin credentials to install helper

---

## Development Workflow

### Project Structure

```
TetherFlow/
├── TetherFlow/              # Main app source
│   ├── Models/              # Data models
│   ├── Services/            # Business logic
│   ├── Views/               # SwiftUI views
│   └── Utils/               # Utilities
├── TetherFlowHelper/        # Privileged helper
│   ├── HelperProtocol.h     # XPC protocol
│   ├── Helper.m             # Helper implementation
│   └── NetworkModifier.c    # C sysctl wrapper
└── Tests/                   # Test suites
```

### Build Configurations

| Configuration | Purpose | Signing |
|--------------|---------|---------|
| Debug | Development | Developer ID |
| Release | Distribution | Developer ID + Notarization |

### Testing

#### Unit Tests

```bash
xcodebuild test -project TetherFlow.xcodeproj \
  -scheme TetherFlow \
  -destination 'platform=macOS'
```

#### UI Tests

```bash
xcodebuild test -project TetherFlow.xcodeproj \
  -scheme TetherFlowUITests \
  -destination 'platform=macOS'
```

#### Manual Testing Checklist

- [ ] App launches and shows menu bar icon
- [ ] Can add/edit/delete hotspot profiles
- [ ] SSID detection works when connecting to Wi-Fi
- [ ] Cloaking activates automatically on configured hotspot
- [ ] Menu bar icon turns green when cloaking active
- [ ] TTL is set to 65 (verify with `sysctl net.inet.ip.ttl`)
- [ ] MTU is set correctly (verify with `networksetup -getMTU en0`)
- [ ] Cloaking deactivates on disconnect
- [ ] Emergency kill-switch works
- [ ] Dashboard shows real-time metrics
- [ ] Data threshold alerts trigger correctly

---

## Debugging

### View System Logs

```bash
# Stream logs for the app
log stream --predicate 'subsystem == "com.yourcompany.tetherflow"' --level debug

# Stream logs for helper
log stream --predicate 'process == "com.yourcompany.tetherflow.helper"' --level debug
```

### Check Helper Installation

```bash
# Verify helper is installed
ls -la /Library/PrivilegedHelperTools/

# Check launchd status
launchctl list | grep tetherflow

# View helper logs
cat /var/log/tetherflow-helper.log
```

### Verify Network Settings

```bash
# Check current TTL
sysctl net.inet.ip.ttl

# Check interface MTU
networksetup -getMTU en0

# List network interfaces
networksetup -listallhardwareports
```

### Common Issues

| Issue | Solution |
|-------|----------|
| "Helper not found" error | Build helper target first; check code signing |
| XPC connection fails | Verify bundle IDs match in all files |
| SMJobBless fails | Must use Developer ID (not ad-hoc); check team selection |
| TTL not changing | Verify helper has root privileges; check system logs |
| App doesn't show in menu bar | Check `LSUIElement` is set to YES in Info.plist |

---

## Distribution

### Prepare for Release

#### 1. Archive Build

```bash
xcodebuild archive \
  -project TetherFlow.xcodeproj \
  -scheme TetherFlow \
  -archivePath TetherFlow.xcarchive
```

#### 2. Export App

```bash
xcodebuild -exportArchive \
  -archivePath TetherFlow.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ./build
```

#### 3. Notarize

```bash
# Submit for notarization
xcrun altool --notarize-app \
  --primary-bundle-id "com.yourcompany.tetherflow" \
  --username "your@email.com" \
  --password "@keychain:AC_PASSWORD" \
  --file TetherFlow.app

# Staple ticket
xcrun stapler staple TetherFlow.app
```

### ExportOptions.plist Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
```

---

## Resources

### Documentation

- [Apple SMJobBless Sample](https://developer.apple.com/library/archive/samplecode/SMJobBless/Introduction/Intro.html)
- [SwiftUI MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra)
- [CoreWLAN Framework](https://developer.apple.com/documentation/corewlan)
- [Network.framework](https://developer.apple.com/documentation/network)

### Tools

- [Hopper](https://www.hopperapp.com/) - Disassembler for debugging
- [Proxyman](https://proxyman.io/) - HTTP/HTTPS debugging proxy
- [Wireshark](https://www.wireshark.org/) - Network protocol analyzer

---

## Getting Help

### Check These First

1. System Console logs (`Console.app`)
2. Xcode build logs
3. `log stream` output
4. `/var/log/system.log`

### Debug Mode

Enable verbose logging:

```bash
# In Terminal before running app
export TETHERFLOW_DEBUG=1
export TETHERFLOW_LOG_LEVEL=debug

# Then launch app
open TetherFlow.app
```

---

**Ready to build?** Start with Step 1 above and follow through. The first build may take 5-10 minutes as Xcode indexes and builds dependencies.
