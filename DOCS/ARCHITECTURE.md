# TetherFlow Architecture Documentation

## Overview

TetherFlow is a macOS Menu Bar application built with SwiftUI that provides intelligent network cloaking when connected to mobile hotspots. The application uses a privileged helper tool architecture (SMJobBless pattern) to safely modify system network parameters.

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      User Space (App)                        │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                 SwiftUI Views                        │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │    │
│  │  │MenuBar   │  │Dashboard │  │Profile Management│   │    │
│  │  │  View    │  │   View   │  │    (Add/Edit)    │   │    │
│  │  └────┬─────┘  └────┬─────┘  └────────┬─────────┘   │    │
│  │       └─────────────┼─────────────────┘              │    │
│  │                     │                                │    │
│  │              ┌──────▼──────┐                         │    │
│  │              │  AppState   │  @Published              │    │
│  │              │  (Observable│  Reactive UI Updates     │    │
│  │              │   Object)   │                         │    │
│  │              └──────┬──────┘                         │    │
│  └─────────────────────┼────────────────────────────────┘    │
│                        │                                     │
│  ┌─────────────────────┼────────────────────────────────┐    │
│  │              Services Layer                           │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │    │
│  │  │WiFiMonitor│ │Profile   │ │Cloaking  │ │ Metrics  │ │    │
│  │  │          │ │  Store   │ │ Engine   │ │ Collector│ │    │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ │    │
│  │       └────────────┴────────────┴────────────┘        │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │    │
│  │  │  XPC     │ │  Safety  │ │ Reversion│ │ Session  │ │    │
│  │  │ Client   │ │ Monitor  │ │ Verifier │ │  Store   │ │    │
│  │  └────┬─────┘ └──────────┘ └──────────┘ └──────────┘ │    │
│  └───────┼───────────────────────────────────────────────┘    │
│          │                                                    │
└──────────┼────────────────────────────────────────────────────┘
           │ XPC Connection (NSXPCConnection)
           │ Authenticated, Code-Signed
┌──────────┼────────────────────────────────────────────────────┐
│          ▓          Privileged Space (Root)                   │
│          ▓                                                    │
│  ┌───────▼──────┐  ┌──────────────┐  ┌──────────────┐        │
│  │   XPC        │  │  Network     │  │    DNS       │        │
│  │  Server      │  │  Modifier    │  │ Configurator │        │
│  │              │  │  (sysctl)    │  │(networksetup)│        │
│  │ ┌──────────┐ │  └──────┬───────┘  └──────┬───────┘        │
│  │ │  XPC     │ │         │                 │                │
│  │ │ Protocol │ │         └────────┬────────┘                │
│  │ └──────────┘ │                  │                         │
│  └──────────────┘                  ▼                         │
│                            ┌──────────────┐                  │
│                            │   System     │                  │
│                            │   Commands   │                  │
│                            │ sysctl/pfctl │                  │
│                            │ networksetup │                  │
│                            └──────────────┘                  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. UI Layer (SwiftUI)

#### MenuBarView
- **Purpose**: Main Menu Bar interface with status display
- **Responsibilities**:
  - Display current cloaking status (idle/active/reverting/error)
  - Quick profile selection
  - Kill switch access
  - Navigation to Dashboard and Profile management

#### DashboardView
- **Purpose**: Real-time monitoring dashboard
- **Responsibilities**:
  - Network speed visualization (ASCII charts)
  - Data usage progress bars
  - Session statistics
  - Safety threshold indicators
  - Kill switch button

#### ProfileListView & Add/Edit Views
- **Purpose**: CRUD operations for hotspot profiles
- **Responsibilities**:
  - List configured profiles
  - Add new profiles with settings
  - Edit existing profiles
  - Delete profiles

### 2. State Management

#### AppState (ObservableObject)
- **Pattern**: MVVM with Combine
- **Responsibilities**:
  - Central state management
  - Reactive UI updates via @Published properties
  - Coordination between services
  - Error handling and user notifications

### 3. Core Services

#### WiFiMonitor
- **Protocol**: `WiFiMonitoring`
- **Responsibilities**:
  - Monitor current Wi-Fi connection using CoreWLAN
  - Detect connection changes
  - Match connected SSID against configured profiles
  - Notify AppState of changes

#### ProfileStore
- **Responsibilities**:
  - CRUD operations for HotspotProfile
  - UserDefaults persistence
  - JSON serialization
  - Profile validation

#### CloakingEngine (Actor)
- **Responsibilities**:
  - Coordinate activation/deactivation
  - Manage cloaking state machine
  - Error handling and retry logic
  - Emergency deactivation

#### XPCClient (Actor)
- **Responsibilities**:
  - Manage NSXPCConnection
  - Authenticate helper tool
  - Send commands to privileged helper
  - Handle reconnection logic

#### MetricsCollector
- **Responsibilities**:
  - Collect network interface statistics
  - Calculate upload/download speeds
  - Track data usage
  - Provide real-time updates to Dashboard

#### SafetyMonitor
- **Responsibilities**:
  - Monitor data usage against thresholds
  - Calculate risk levels
  - Trigger alerts when limits approached

#### ReversionVerifier (Actor)
- **Responsibilities**:
  - Verify network settings restored after disconnection
  - Retry mechanism for failed reversion
  - Force reversion if needed

#### SessionStore
- **Responsibilities**:
  - Persist cloaking session history
  - Calculate statistics (average duration, most used SSID)
  - Export to JSON

### 4. XPC Layer

#### HelperInstaller
- **Responsibilities**:
  - SMJobBless workflow
  - Helper tool installation/removal
  - Version checking
  - Authorization dialogs

#### XPCServer (in Helper Tool)
- **Responsibilities**:
  - Accept XPC connections
  - Validate client code signature
  - Execute privileged commands
  - Return results

#### XPCServiceProtocol
- **Purpose**: Defines XPC communication interface
- **Methods**:
  - `applyNetworkModification(ttl:mtu:)`
  - `revertNetworkModification()`
  - `verifySettingsApplied()`

### 5. Network Configuration

#### NetworkModifier
- **Responsibilities**:
  - Execute sysctl for TTL modification
  - Execute networksetup for MTU modification
  - Verify changes applied

#### DNSConfigurator
- **Responsibilities**:
  - Configure encrypted DNS (DoH/DoT)
  - Restore original DNS on disconnect
  - Support custom DNS servers

#### TrafficShaper (Actor)
- **Responsibilities**:
  - Configure pfctl rules
  - Delay/throttle background traffic
  - Manage traffic categories

## Data Flow

### Cloaking Activation Flow

```
┌─────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  WiFi   │───▶│  WiFiMonitor│───▶│  AppState   │───▶│CloakingEngine│
│Connected│    │ SSID Match  │    │Profile Found│    │  (Actor)    │
└─────────┘    └─────────────┘    └─────────────┘    └──────┬──────┘
                                                             │
                              ┌──────────────────────────────┘
                              ▼
                       ┌─────────────┐
                       │  XPCClient  │
                       │   (Actor)   │
                       └──────┬──────┘
                              │ XPC
                              ▼
                       ┌─────────────┐
                       │  XPCServer  │
                       │   (Root)    │
                       └──────┬──────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │  sysctl  │   │networksetup│  │  pfctl   │
        │  TTL=65  │   │ MTU=1400  │   │  Rules   │
        └──────────┘   └──────────┘   └──────────┘
```

### Disconnection/Reversion Flow

```
┌─────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  WiFi   │───▶│  WiFiMonitor│───▶│  AppState   │───▶│CloakingEngine│
│Disconnected│  │   Detect    │    │ Auto-Revert │    │             │
└─────────┘    └─────────────┘    └─────────────┘    └──────┬──────┘
                                                             │
                              ┌──────────────────────────────┘
                              ▼
                       ┌─────────────┐
                       │ReversionVerifier│
                       │   (Actor)   │
                       └──────┬──────┘
                              │
                              ▼
                       ┌─────────────┐
                       │  XPCClient  │
                       └──────┬──────┘
                              │
                              ▼
                       ┌─────────────┐
                       │ TTL=64/MTU=1500│
                       │   Restore   │
                       └─────────────┘
```

## Security Architecture

### Privilege Escalation

TetherFlow uses the macOS `SMJobBless` pattern for secure privilege escalation:

1. **Code Signing**: Both app and helper are code-signed
2. **Launchd Plist**: Helper registered with system launchd
3. **XPC Authentication**: Helper validates app's code signature
4. **Audit Logging**: All privileged operations logged

```
┌─────────────────────────────────────────────────────────┐
│                    Security Model                        │
│                                                          │
│  App (User)           XPC (Authenticated)      Helper   │
│  ┌────────┐           ┌──────────────┐        ┌───────┐ │
│  │Signed  │◄─────────►│ Code Signature│◄──────►│Signed │ │
│  │w/ DevID│           │   Validation  │        │w/ DevID│ │
│  └────────┘           └──────────────┘        └───┬───┘ │
│                                                   │     │
│                                           ┌───────▼───┐ │
│                                           │  Root     │ │
│                                           │ Privileges │ │
│                                           └───────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Input Sanitization

All user inputs are sanitized before use:

1. **SSID Validation**: Length, character restrictions
2. **Numeric Validation**: TTL (1-255), MTU (1280-1500)
3. **DNS Validation**: IP address format, URL validation
4. **File Validation**: JSON schema validation for imports

## Concurrency Model

### Actor-Based Isolation

Critical services use Swift actors for thread safety:

```swift
actor CloakingEngine {
    private var state: State = .idle
    
    func activate(...) async throws { ... }
    func deactivate() async throws { ... }
}

actor XPCClient {
    private var connection: NSXPCConnection?
    
    func connect() async throws { ... }
    func sendCommand(...) async throws { ... }
}
```

### Main Actor UI

All UI updates happen on `@MainActor`:

```swift
@MainActor
class AppState: ObservableObject {
    @Published var status: AppStatus = .idle
    @Published var profiles: [HotspotProfile] = []
}
```

## Persistence

### UserDefaults

- HotspotProfile storage
- App settings
- Keyboard shortcuts

### JSON Files

- Session history (`sessions.json`)
- Profile exports

### Keychain

- Sensitive configuration (future)

## Error Handling

### Error Types

```swift
enum CloakingError: Error {
    case xpcConnectionFailed
    case helperNotInstalled
    case networkModificationFailed
    case invalidProfile
    case timeout
}
```

### Retry Strategy

- XPC calls: 3 retries with exponential backoff
- Network modifications: 3 attempts
- Reversion verification: 3 attempts

## Performance Considerations

### Resource Usage Targets

- CPU Usage: <0.1% when idle
- Memory Footprint: <50 MB
- XPC Latency: <10ms average

### Optimizations

- Actor isolation prevents data races without locks
- Lazy loading of views
- Efficient Combine publishers
- Background queue for file I/O

## Testing Strategy

### Unit Tests

- Service layer tests
- Model validation tests
- XPC communication tests

### Integration Tests

- Full cloaking lifecycle
- XPC end-to-end
- Profile import/export

### UI Tests

- Critical user flows
- Menu bar interactions
- Dashboard functionality

### Performance Tests

- CPU usage benchmarks
- Memory leak detection
- XPC latency measurements

## Deployment

### Code Signing

- Developer ID for distribution
- Notarization for Gatekeeper
- Hardened runtime enabled

### Helper Installation

- First-run SMJobBless workflow
- Automatic version updates
- Clean uninstallation support

---

**Document Version**: 1.0  
**Last Updated**: 2026-02-05
