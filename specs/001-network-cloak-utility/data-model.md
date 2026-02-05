# Data Model: macOS Network Cloaking & Optimization Utility

**Date**: 2026-02-05  
**Feature**: macOS Network Cloaking & Optimization Utility

---

## Entity Overview

```
┌─────────────────────┐     ┌─────────────────────┐
│   HotspotProfile    │────<│    CloakingSession  │
│   (Configuration)   │     │    (Runtime State)  │
└─────────────────────┘     └─────────────────────┘
           │                           │
           │                    ┌──────┴──────┐
           │                    │             │
           ▼                    ▼             ▼
┌─────────────────────┐     ┌──────────┐  ┌──────────────┐
│   SafetyThreshold   │     │AppMetrics│  │NetworkMetrics│
│   (Limits/Alerts)   │     └──────────┘  └──────────────┘
└─────────────────────┘
```

---

## 1. HotspotProfile

**Purpose**: Stores configuration for a mobile hotspot that should trigger cloaking.

### Fields

| Field | Type | Default | Validation | Description |
|-------|------|---------|------------|-------------|
| `id` | UUID | auto-generated | required | Unique identifier for the profile |
| `ssid` | String | "" | non-empty, max 32 chars | Wi-Fi network name to match |
| `targetTTL` | Int | 65 | 64-255 | TTL value to set (65 → arrives as 64) |
| `targetMTU` | Int | 1400 | 1280-1500 | MTU for mobile network optimization |
| `autoActivate` | Bool | true | - | Whether to auto-activate on connect |
| `enableTrafficShaping` | Bool | true | - | Whether to shape background traffic |
| `hourlyDataThreshold` | Double | 10.0 | >0 | GB per hour before risk alert |
| `dailyDataThreshold` | Double | 50.0 | >0 | GB per day before risk alert |
| `useEncryptedDNS` | Bool | true | - | Enable DoH/DoT during cloaking |
| `dnsProvider` | String | "cloudflare" | enum | "cloudflare", "quad9", "custom" |
| `createdAt` | Date | now | required | Profile creation timestamp |
| `lastModified` | Date | now | required | Last modification timestamp |

### State Transitions

```
[Created] → [Active] → [Connected/Cloaking] → [Disconnected] → [Active]
                ↓
            [Deleted]
```

### Swift Definition

```swift
struct HotspotProfile: Codable, Identifiable, Equatable {
    let id: UUID
    let ssid: String
    var targetTTL: Int
    var targetMTU: Int
    var autoActivate: Bool
    var enableTrafficShaping: Bool
    var hourlyDataThreshold: Double  // GB
    var dailyDataThreshold: Double   // GB
    var useEncryptedDNS: Bool
    var dnsProvider: DNSProvider
    let createdAt: Date
    var lastModified: Date
    
    enum DNSProvider: String, Codable, CaseIterable {
        case cloudflare = "cloudflare"
        case quad9 = "quad9"
        case custom = "custom"
    }
    
    // Validation
    var isValid: Bool {
        !ssid.isEmpty && 
        ssid.count <= 32 &&
        targetTTL >= 64 && targetTTL <= 255 &&
        targetMTU >= 1280 && targetMTU <= 1500 &&
        hourlyDataThreshold > 0 &&
        dailyDataThreshold > 0
    }
}
```

---

## 2. CloakingSession

**Purpose**: Tracks an active cloaking session with real-time metrics.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Session unique identifier |
| `profileId` | UUID | Reference to HotspotProfile |
| `ssid` | String | The SSID being cloaked |
| `interface` | String | Network interface name (e.g., "en0") |
| `startTime` | Date | When cloaking began |
| `endTime` | Date? | When cloaking ended (nil if active) |
| `originalTTL` | Int | TTL value before modification |
| `originalMTU` | Int | MTU value before modification |
| `appliedTTL` | Int | TTL value applied (typically 65) |
| `appliedMTU` | Int | MTU value applied (typically 1400) |
| `status` | SessionStatus | Current session status |

### Status Enum

```swift
enum SessionStatus: String, Codable {
    case activating = "activating"      // In progress of applying settings
    case active = "active"              // Cloaking active
    case deactivating = "deactivating"  // In progress of reverting
    case completed = "completed"        // Successfully ended
    case failed = "failed"              // Error occurred
}
```

### Computed Properties

| Property | Type | Description |
|----------|------|-------------|
| `duration` | TimeInterval | Current or total session duration |
| `isActive` | Bool | Whether session is currently active |
| `dataTransferred` | NetworkMetrics | Associated metrics (see below) |

---

## 3. NetworkMetrics

**Purpose**: Real-time and historical network usage statistics.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `sessionId` | UUID | Reference to CloakingSession |
| `timestamp` | Date | When metrics were recorded |
| `bytesUploaded` | UInt64 | Total bytes uploaded this session |
| `bytesDownloaded` | UInt64 | Total bytes downloaded this session |
| `uploadSpeed` | Double | Current upload speed (bytes/sec) |
| `downloadSpeed` | Double | Current download speed (bytes/sec) |
| `peakUploadSpeed` | Double | Maximum upload speed observed |
| `peakDownloadSpeed` | Double | Maximum download speed observed |
| `packetsSent` | UInt64 | Total packets sent |
| `packetsReceived` | UInt64 | Total packets received |

### Computed Properties

```swift
var totalBytesTransferred: UInt64 { bytesUploaded + bytesDownloaded }
var totalGBTransferred: Double { Double(totalBytesTransferred) / 1_000_000_000 }
```

---

## 4. AppState

**Purpose**: Global application state for UI binding and coordination.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `isMonitoringEnabled` | Bool | Whether Wi-Fi monitoring is active |
| `currentSSID` | String? | Currently connected Wi-Fi SSID (nil if disconnected) |
| `currentInterface` | String? | Active network interface |
| `activeSession` | CloakingSession? | Currently active cloaking session |
| `status` | AppStatus | Overall app status |
| `lastError` | AppError? | Most recent error (if any) |
| `profiles` | [HotspotProfile] | All configured hotspot profiles |

### AppStatus Enum

```swift
enum AppStatus: String, Codable {
    case idle = "idle"                      // Not connected to any hotspot
    case scanning = "scanning"              // Checking if connected SSID matches
    case cloakingActive = "cloakingActive"  // Cloaking in progress
    case reverting = "reverting"            // Reverting to defaults
    case error = "error"                    // Error state
}
```

### Status Icon Mapping

| AppStatus | Menu Bar Icon | Color |
|-----------|---------------|-------|
| `idle` | antenna.radiowaves.left.and.right | Gray |
| `scanning` | antenna.radiowaves.left.and.right | Gray (animated) |
| `cloakingActive` | antenna.radiowaves.left.and.right | Green |
| `reverting` | arrow.uturn.backward | Yellow |
| `error` | exclamationmark.triangle | Red |

---

## 5. SafetyThreshold

**Purpose**: Tracks threshold compliance and alert states.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `profileId` | UUID | Reference to HotspotProfile |
| `sessionId` | UUID | Reference to CloakingSession |
| `hourlyLimitGB` | Double | Hourly data limit |
| `dailyLimitGB` | Double | Daily data limit |
| `hourlyUsageGB` | Double | Current hour usage |
| `dailyUsageGB` | Double | Current day usage |
| `hourlyAlertTriggered` | Bool | Whether hourly alert has been shown |
| `dailyAlertTriggered` | Bool | Whether daily alert has been shown |
| `lastResetHour` | Date | When hourly counter last reset |
| `lastResetDay` | Date | When daily counter last reset |

### Alert Logic

```swift
var shouldTriggerHourlyAlert: Bool {
    hourlyUsageGB >= hourlyLimitGB && !hourlyAlertTriggered
}

var shouldTriggerDailyAlert: Bool {
    dailyUsageGB >= dailyLimitGB && !dailyAlertTriggered
}

var riskLevel: RiskLevel {
    if dailyUsageGB >= dailyLimitGB { return .critical }
    if hourlyUsageGB >= hourlyLimitGB { return .high }
    if hourlyUsageGB >= hourlyLimitGB * 0.8 { return .medium }
    return .low
}
```

### RiskLevel Enum

```swift
enum RiskLevel: String, Codable {
    case low = "low"           // Green
    case medium = "medium"     // Yellow
    case high = "high"         // Orange
    case critical = "critical" // Red
}
```

---

## 6. AppError

**Purpose**: Standardized error representation for UI display and logging.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `code` | ErrorCode | Error type identifier |
| `message` | String | User-friendly error message |
| `timestamp` | Date | When error occurred |
| `recoverable` | Bool | Whether user can recover from this error |

### ErrorCode Enum

```swift
enum ErrorCode: String, Codable {
    // Configuration errors
    case invalidSSID = "invalid_ssid"
    case profileNotFound = "profile_not_found"
    case duplicateSSID = "duplicate_ssid"
    
    // Network errors
    case noActiveInterface = "no_active_interface"
    case ttlModificationFailed = "ttl_modification_failed"
    case mtuModificationFailed = "mtu_modification_failed"
    case helperNotAvailable = "helper_not_available"
    
    // XPC errors
    case xpcConnectionFailed = "xpc_connection_failed"
    case helperCommunicationError = "helper_communication_error"
    
    // System errors
    case wifiMonitoringFailed = "wifi_monitoring_failed"
    case trafficShapingFailed = "traffic_shaping_failed"
    case dnsConfigurationFailed = "dns_configuration_failed"
}
```

---

## Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                        User Action                           │
│                 (Add/Edit/Delete Profile)                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    HotspotProfile                           │
│              (Stored in UserDefaults)                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
         ┌─────────────┼─────────────┐
         │             │             │
         ▼             ▼             ▼
   Wi-Fi Connect   Manual Toggle   Auto-activate
         │             │             │
         └─────────────┴─────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                   CloakingSession                           │
│              (Created on activation)                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
         ┌─────────────┼─────────────┐
         │             │             │
         ▼             ▼             ▼
   NetworkMetrics  SafetyThreshold   AppState
   (Real-time)     (Threshold check) (UI binding)
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                      Alert Triggered                         │
│              (If thresholds exceeded)                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Storage Strategy

| Entity | Storage | Persistence | Reason |
|--------|---------|-------------|--------|
| HotspotProfile | UserDefaults | Permanent | Small config, keychain-secure |
| CloakingSession | UserDefaults + Memory | Session + recent history | State tracking |
| NetworkMetrics | In-memory + Log | Runtime only | High frequency, large volume |
| AppState | Memory | Runtime only | Transient UI state |
| SafetyThreshold | In-memory | Runtime only | Derived from session metrics |
| AppError | UserDefaults (last 10) | Recent history only | Error tracking |

---

## Validation Rules Summary

| Entity | Rule | Error Code |
|--------|------|------------|
| HotspotProfile | SSID non-empty | `invalidSSID` |
| HotspotProfile | SSID max 32 chars | `invalidSSID` |
| HotspotProfile | TTL 64-255 | `invalidConfiguration` |
| HotspotProfile | MTU 1280-1500 | `invalidConfiguration` |
| HotspotProfile | Thresholds > 0 | `invalidConfiguration` |
| CloakingSession | Valid profile exists | `profileNotFound` |
| NetworkMetrics | Non-negative values | (internal) |
| AppState | Consistent session state | `inconsistentState` |
