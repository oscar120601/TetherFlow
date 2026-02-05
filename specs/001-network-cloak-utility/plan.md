# Implementation Plan: macOS Network Cloaking & Optimization Utility

**Branch**: `001-network-cloak-utility` | **Date**: 2026-02-05 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-network-cloak-utility/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Build a macOS menu bar application that automatically cloaks network traffic when connected to a configured mobile hotspot. The app uses the Privileged Helper Tool pattern to safely modify system-level network parameters (TTL, MTU) via XPC communication. Key features include: automatic SSID detection, protocol spoofing, intelligent traffic shaping, encrypted DNS, real-time monitoring dashboard, and emergency kill-switch. The solution ensures MacBook traffic appears identical to on-device mobile traffic from ISP perspective.

## Technical Context

**Language/Version**: Swift 6.0, Objective-C (for XPC protocol), C (for sysctl calls)  
**Primary Dependencies**: 
- ServiceManagement.framework (SMJobBless for privilege escalation)
- CoreWLAN (Wi-Fi SSID monitoring)
- Network.framework (connectivity detection)
- SwiftUI (menu bar UI)
  
**Storage**: UserDefaults (for HotspotProfile persistence), JSON files (for configuration)  
**Testing**: XCTest (unit tests), XCUITest (UI automation)  
**Target Platform**: macOS 13+ (Ventura and later)  
**Project Type**: macOS Menu Bar App with Privileged Helper Tool  
**Performance Goals**: CPU usage < 0.1%, Memory < 100MB, Activation latency < 3 seconds  
**Constraints**: 
- Requires Apple Developer ID for SMJobBless distribution
- Must pass App Notarization
- Root privileges required only for Helper Tool
- Zero-state reversion mandatory on disconnect

**Scale/Scope**: Single-user desktop application, local network modifications only

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Code Quality Excellence ✅
- **Naming**: Swift API Design Guidelines followed
- **Complexity**: Helper Tool kept minimal (<500 lines)
- **Documentation**: XML docs for all public APIs
- **Reviews**: PR required for all changes

### Principle II: Testing Standards ✅
- **Coverage Target**: 80% minimum
- **Test Types**: Unit tests (Swift), Integration tests (XPC), Contract tests
- **TDD**: XPC protocol tests written first
- **CI**: Automated test execution on build

### Principle III: User Experience Consistency ✅
- **UI Pattern**: Native macOS menu bar extra
- **Accessibility**: Full keyboard navigation support
- **Response Time**: <200ms UI feedback
- **Error Handling**: User-friendly alerts

### Principle IV: Performance Requirements ✅
- **CPU**: <0.1% target (well under 1% limit)
- **Memory**: <100MB during operation
- **Activation**: <3 seconds (under 1 second goal)
- **Kill-switch**: <2 seconds reversion

**Constitution Compliance**: ✅ PASSED - All principles satisfied

## Project Structure

### Documentation (this feature)

```text
specs/001-network-cloak-utility/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
TetherFlow/
├── TetherFlow/                              # Main macOS App (Menu Bar)
│   ├── TetherFlowApp.swift                  # App entry point
│   ├── ContentView.swift                    # SwiftUI main view
│   ├── MenuBarView.swift                    # Menu bar extra UI
│   ├── DashboardView.swift                  # Monitoring dashboard
│   ├── Models/
│   │   ├── HotspotProfile.swift             # Hotspot configuration model
│   │   ├── AppState.swift                   # App state management
│   │   └── NetworkMetrics.swift             # Real-time metrics
│   ├── Services/
│   │   ├── WiFiMonitor.swift                # CoreWLAN SSID monitoring
│   │   ├── XPCClient.swift                  # XPC communication client
│   │   ├── NetworkConfigurator.swift        # High-level network config
│   │   └── TrafficShaper.swift              # Background traffic management
│   └── Utils/
│       ├── Constants.swift                  # App constants
│       └── Logger.swift                     # Unified logging
│
├── TetherFlowHelper/                        # Privileged Helper Tool (Root)
│   ├── main.m                               # Helper entry point
│   ├── HelperProtocol.h                     # XPC protocol definition
│   ├── Helper.m                             # Helper implementation
│   ├── NetworkModifier.c                    # C-level sysctl operations
│   ├── NetworkModifier.h                    # C wrapper header
│   └── Helper-Info.plist                    # Launchd configuration
│
├── TetherFlow.xcodeproj/                    # Xcode project
├── Tests/
│   ├── TetherFlowTests/                     # Unit tests
│   │   ├── HotspotProfileTests.swift
│   │   ├── WiFiMonitorTests.swift
│   │   └── NetworkMetricsTests.swift
│   ├── TetherFlowUITests/                   # UI tests
│   │   └── MenuBarUITests.swift
│   └── IntegrationTests/                    # XPC integration tests
│       └── XPCCommunicationTests.swift
│
├── Scripts/
│   ├── setup-helper.sh                      # Helper installation script
│   └── codesign-check.sh                    # Code signing validation
│
└── Resources/
    ├── Assets.xcassets/                     # App icons
    ├── Info.plist                           # App Info.plist
    └── Helper-Launchd.plist                 # Helper launchd template
```

**Structure Decision**: macOS app with Privileged Helper Tool pattern. Two main targets: TetherFlow (UI app, user space) and TetherFlowHelper (daemon, root space). XPC bridges the two.

## Phase 0: Research & Decisions

### Research Topics

#### R1: SMJobBless Best Practices
**Decision**: Use ServiceManagement.framework SMJobBless API for secure helper installation  
**Rationale**: Apple-recommended approach for privileged helper tools; handles code signing validation automatically  
**Alternatives Considered**: 
- Authorization Services (deprecated in favor of SMJobBless)
- Manual setuid binaries (security risk, not App Store compatible)

#### R2: TTL Modification Method
**Decision**: Use `sysctlbyname("net.inet.ip.ttl", ...)` via C wrapper  
**Rationale**: Direct kernel parameter access; lowest latency; no shell overhead  
**Alternatives Considered**:
- `networksetup` command (slower, requires parsing output)
- pfctl rules (complex, doesn't actually modify TTL)

#### R3: Wi-Fi Monitoring
**Decision**: CoreWLAN CWWiFiClient with KVO observers  
**Rationale**: Native framework, real-time SSID change notifications  
**Alternatives Considered**:
- `system_profiler` polling (inefficient, slow)
- `airport` command (private API, unreliable)

#### R4: Traffic Shaping
**Decision**: Use `pfctl` (Packet Filter) for intelligent throttling  
**Rationale**: Built-in macOS firewall; can delay/shape without blocking  
**Alternatives Considered**:
- Complete blocking (breaks background apps)
- NetworkExtension (too heavyweight for this use case)

#### R5: Encrypted DNS
**Decision**: Use Network.framework with DoH/DoT configuration  
**Rationale**: Native iOS/macOS networking; handles DNS over HTTPS/TLS automatically  
**Alternatives Considered**:
- Manual DNS server configuration (less secure)
- Third-party DNS libraries (unnecessary dependency)

---

*Research output continues in [research.md](research.md)*

## Phase 1: Design & Contracts

### Data Model

See [data-model.md](data-model.md) for detailed entity definitions.

Key entities:
- `HotspotProfile`: SSID, TTL, MTU, auto-activate, background traffic settings
- `AppState`: cloaking status, current SSID, session data transferred
- `NetworkMetrics`: upload/download speeds, peak usage, session duration
- `SafetyThreshold`: hourly/daily limits, alert status

### API Contracts

See `/contracts/` directory for detailed protocol definitions.

**XPC Protocol** (HelperProtocol):
```objc
- (void)applyCloakingWithTTL:(int)ttl mtu:(int)mtu interface:(NSString *)interface withReply:(void (^)(BOOL))reply;
- (void)resetNetworkSettingsWithInterface:(NSString *)interface withReply:(void (^)(BOOL))reply;
- (void)getCurrentTTLWithReply:(void (^)(int))reply;
```

### Quick Start

See [quickstart.md](quickstart.md) for development environment setup.

## Complexity Tracking

> No constitution violations identified. All design decisions align with principles.

| Component | Complexity Justification |
|-----------|------------------------|
| Privileged Helper Tool | Required for root-level sysctl modifications; industry standard |
| XPC Communication | Secure IPC required by SMJobBless; no simpler alternative |
| C Wrapper for sysctl | Performance requirement; direct kernel access needed |
| Traffic Shaping | Constitution requirement for intelligent handling vs blocking |

## Next Steps

1. ✅ Phase 0 Complete: Research decisions documented
2. ✅ Phase 1 Complete: Data model, contracts, quickstart defined
3. ⏳ **Ready for**: `/speckit.tasks` - Generate actionable implementation tasks

Run `/speckit.tasks` to break the implementation plan into executable tasks.
