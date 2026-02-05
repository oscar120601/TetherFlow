# TetherFlow

**macOS Network Cloaking & Optimization Utility**

TetherFlow automatically "hijacks" the network protocol layer when you connect to a specific mobile hotspot, ensuring all MacBook network traffic appears identical to local on-device mobile traffic from the ISP's perspective, enabling true unlimited tethering.

## Features

- 🔒 **Intelligent Context Awareness**: Automatically recognizes configured Wi-Fi SSIDs
- 🎭 **Multi-Layer Identity Cloaking**: Modifies TTL and MTU to match mobile device signatures
- 🚦 **Traffic Pattern Sanitization**: Intelligently delays desktop-specific background requests
- 🔐 **Encrypted DNS**: Defaults to DoH/DoT to prevent ISP analysis
- 📊 **Monitoring Dashboard**: Real-time upload/download speeds with safety thresholds
- 🚨 **Emergency Kill-Switch**: One-click instant network stack reset
- 🔄 **Zero-State Reversion**: Instantly reverts settings when disconnecting

## Architecture

TetherFlow uses the **Privileged Helper Tool** pattern (SMJobBless) for safe modification of system-level network parameters:

```
┌─────────────────────┐     XPC      ┌─────────────────────┐
│   TetherFlow App    │◄────────────►│  TetherFlowHelper   │
│   (SwiftUI +        │              │  (Root Privilege)   │
│    CoreWLAN)        │              │  - sysctl TTL       │
│   User Space        │              │  - networksetup MTU │
└─────────────────────┘              │  - pfctl shaping    │
                                     └─────────────────────┘
```

## Requirements

- macOS 13.0+ (Ventura)
- Apple Developer ID (for code signing)
- Xcode 15.0+

## Project Structure

```
TetherFlow/
├── TetherFlow/              # Main macOS App (Menu Bar)
│   ├── Models/              # HotspotProfile, AppState, CloakingSession
│   ├── Services/            # WiFiMonitor, XPCClient, NetworkConfigurator
│   └── Views/               # SwiftUI interface
├── TetherFlowHelper/        # Privileged Helper Tool
│   ├── Helper.m             # XPC service implementation
│   └── NetworkModifier.c    # C sysctl wrapper
└── Tests/                   # Unit and integration tests
```

## Quick Start

See [quickstart.md](specs/001-network-cloak-utility/quickstart.md) for detailed setup instructions.

### Build

```bash
# Build helper tool first
xcodebuild -project TetherFlow.xcodeproj -scheme TetherFlowHelper -configuration Debug build

# Build main app
xcodebuild -project TetherFlow.xcodeproj -scheme TetherFlow -configuration Debug build
```

### Run

1. Open `TetherFlow.xcodeproj` in Xcode
2. Select `TetherFlow` scheme
3. Press **Cmd+R** to run
4. First run will prompt for admin credentials to install helper

## Configuration

1. Add your mobile hotspot SSID in the app
2. Configure cloaking options (TTL, MTU, traffic shaping)
3. Set safety thresholds for data usage alerts
4. Connect to your hotspot - cloaking activates automatically

## How It Works

### TTL Spoofing

Sets outgoing packet TTL to **65** so it arrives at the ISP as **64** (matching mobile device standards):

```
TTL_Initial = 65  =>  TTL_Arrival_at_ISP = 64
```

### MTU Optimization

Adjusts MTU to **1400 bytes** (optimized for mobile networks):

```bash
networksetup -setMTU en0 1400
```

### Traffic Shaping

Uses `pfctl` to intelligently delay desktop-specific traffic:
- macOS software updates
- Large iCloud syncs
- App Store downloads

## Safety

- ✅ **Automatic Reversion**: Settings reset when disconnecting from hotspot
- ✅ **Kill Switch**: One-click emergency reset
- ✅ **Data Thresholds**: Alerts when usage exceeds safe limits
- ✅ **Code Signed**: Uses Apple SMJobBless for secure privilege escalation

## Development

This project follows the **Spec-Driven Development** methodology using [GitHub Spec Kit](https://github.com/github/spec-kit).

### Documentation

- [Feature Specification](specs/001-network-cloak-utility/spec.md)
- [Implementation Plan](specs/001-network-cloak-utility/plan.md)
- [Research Decisions](specs/001-network-cloak-utility/research.md)
- [Data Model](specs/001-network-cloak-utility/data-model.md)
- [API Contracts](specs/001-network-cloak-utility/contracts/)

### Testing

```bash
# Run all tests
xcodebuild test -project TetherFlow.xcodeproj -scheme TetherFlow
```

## License

MIT License - See LICENSE file for details.

## Disclaimer

This tool is for educational and legitimate use cases only. Users are responsible for complying with their ISP's terms of service.
