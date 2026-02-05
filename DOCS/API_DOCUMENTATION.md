# TetherFlow API Documentation

## Table of Contents

- [Overview](#overview)
- [Services](#services)
- [Data Models](#data-models)
- [Views](#views)
- [XPC Protocol](#xpc-protocol)
- [Utilities](#utilities)

---

## Overview

TetherFlow is structured with a clear separation between UI, Services, and Data Models. Services handle business logic, Views render the UI, and Models represent the data.

---

## Services

### CloakingEngine

Core coordinator for activation/deactivation of network cloaking.

```swift
actor CloakingEngine {
    /// Current state of the cloaking engine
    var state: State { get }
    
    /// Activate cloaking for a profile on a specific interface
    /// - Parameters:
    ///   - profile: The hotspot profile to apply
    ///   - interface: Network interface name (e.g., "en0")
    /// - Returns: The active cloaking session
    /// - Throws: CloakingError if activation fails
    func activate(profile: HotspotProfile, interface: String) async throws -> CloakingSession
    
    /// Deactivate active cloaking
    /// - Parameter session: Optional session to deactivate (uses active if nil)
    /// - Throws: CloakingError if deactivation fails
    func deactivate(session: CloakingSession?) async throws
    
    /// Emergency deactivation - always succeeds
    func emergencyDeactivate() async
    
    /// Verify cloaking is still active
    /// - Parameter interface: Network interface to check
    /// - Returns: True if cloaking is verified active
    func verifyActive(interface: String) async -> Bool
}

extension CloakingEngine {
    enum State {
        case idle
        case activating
        case active(session: CloakingSession)
        case deactivating
        case error(CloakingError)
    }
    
    enum CloakingError: Error {
        case xpcConnectionFailed
        case helperNotInstalled
        case networkModificationFailed(String)
        case invalidProfile
        case timeout
        case alreadyActive
        case notActive
    }
}
```

### WiFiMonitor

Monitors Wi-Fi connection status and detects configured hotspots.

```swift
protocol WiFiMonitoring {
    /// Current Wi-Fi connection status
    var currentNetwork: WiFiNetwork? { get }
    
    /// Publisher for network changes
    var networkPublisher: AnyPublisher<WiFiNetwork?, Never> { get }
    
    /// Start monitoring
    func startMonitoring()
    
    /// Stop monitoring
    func stopMonitoring()
    
    /// Check if current network matches any profile
    func checkForMatchingProfile(in profiles: [HotspotProfile]) -> HotspotProfile?
}

class WiFiMonitor: WiFiMonitoring, ObservableObject {
    init()
}

struct WiFiNetwork {
    let ssid: String
    let bssid: String
    let interface: String
    let isConnected: Bool
}
```

### ProfileStore

Manages persistence and CRUD operations for hotspot profiles.

```swift
class ProfileStore: ObservableObject {
    /// All saved profiles
    var profiles: [HotspotProfile] { get }
    
    /// Publisher for profile changes
    var profilesPublisher: AnyPublisher<[HotspotProfile], Never> { get }
    
    /// Initialize with default storage
    init()
    
    /// Save a profile
    func saveProfile(_ profile: HotspotProfile)
    
    /// Update existing profile
    func updateProfile(_ profile: HotspotProfile)
    
    /// Delete a profile
    func deleteProfile(_ profile: HotspotProfile)
    
    /// Find profile by SSID
    func findProfile(ssid: String) -> HotspotProfile?
    
    /// Load profiles from storage
    func loadProfiles() -> [HotspotProfile]
    
    /// Export profiles to JSON
    func exportToJSON() throws -> Data
    
    /// Import profiles from JSON
    func importFromJSON(_ data: Data) throws -> [HotspotProfile]
}
```

### XPCClient

Manages XPC communication with the privileged helper tool.

```swift
actor XPCClient {
    /// Connection status
    var isConnected: Bool { get }
    
    /// Current helper version
    var helperVersion: String? { get }
    
    /// Establish connection to helper
    /// - Throws: XPCError.connectionFailed
    func connect() async throws
    
    /// Disconnect from helper
    func disconnect()
    
    /// Send command to modify network settings
    /// - Parameters:
    ///   - ttl: Target TTL value
    ///   - mtu: Target MTU value
    ///   - interface: Network interface
    /// - Returns: True if successful
    func sendModification(ttl: Int, mtu: Int, interface: String) async throws -> Bool
    
    /// Send revert command
    /// - Parameter interface: Network interface
    /// - Returns: True if successful
    func sendRevert(interface: String) async throws -> Bool
    
    /// Verify settings are applied
    /// - Parameters:
    ///   - ttl: Expected TTL
    ///   - mtu: Expected MTU
    ///   - interface: Network interface
    /// - Returns: True if verified
    func verifySettings(ttl: Int, mtu: Int, interface: String) async throws -> Bool
}

enum XPCError: Error {
    case connectionFailed
    connectionInterrupted
    case invalidResponse
    case helperNotFound
    case codeSignatureInvalid
    case timeout
}
```

### HelperInstaller

Manages installation of the privileged helper tool.

```swift
class HelperInstaller {
    /// Current installation status
    var status: InstallationStatus { get }
    
    /// Check if helper is installed
    func isHelperInstalled() async -> Bool
    
    /// Install the helper (requires admin authentication)
    /// - Returns: True if installation successful
    /// - Throws: InstallationError
    func installHelper() async throws -> Bool
    
    /// Remove the helper
    /// - Returns: True if removal successful
    func removeHelper() async throws -> Bool
    
    /// Verify helper is working
    func verifyHelper() async -> Bool
}

enum InstallationStatus {
    case notInstalled
    case installed(version: String)
    case needsUpdate(current: String, required: String)
    case unknown
}

enum InstallationError: Error {
    case authorizationFailed
    case blessingFailed
    case helperNotFound
    case versionMismatch
}
```

### MetricsCollector

Collects real-time network metrics.

```swift
class MetricsCollector: ObservableObject {
    /// Current upload speed in bytes/sec
    var currentUploadSpeed: Double { get }
    
    /// Current download speed in bytes/sec
    var currentDownloadSpeed: Double { get }
    
    /// Total bytes uploaded this session
    var totalUploaded: UInt64 { get }
    
    /// Total bytes downloaded this session
    var totalDownloaded: UInt64 { get }
    
    /// History of speed measurements
    var speedHistory: [SpeedSample] { get }
    
    /// Initialize for interface
    init(interface: String)
    
    /// Start collecting metrics
    func startCollecting()
    
    /// Stop collecting metrics
    func stopCollecting()
    
    /// Reset all counters
    func reset()
}

struct SpeedSample {
    let timestamp: Date
    let upload: Double
    let download: Double
}
```

### SafetyMonitor

Monitors data usage against safety thresholds.

```swift
class SafetyMonitor: ObservableObject {
    /// Current risk level
    var currentRiskLevel: RiskLevel { get }
    
    /// Hourly usage in GB
    var hourlyUsage: Double { get }
    
    /// Daily usage in GB
    var dailyUsage: Double { get }
    
    /// Check if thresholds exceeded
    func checkThresholds(profile: HotspotProfile) -> [ThresholdAlert]
    
    /// Reset counters
    func reset()
}

enum RiskLevel: Int, Comparable {
    case low = 0      // < 50% of threshold
    case medium = 1   // 50-75%
    case high = 2     // 75-90%
    case critical = 3 // > 90%
}

struct ThresholdAlert {
    let type: ThresholdType
    let current: Double
    let limit: Double
    let percentage: Double
    
    enum ThresholdType {
        case hourly
        case daily
    }
}
```

### DNSConfigurator

Configures encrypted DNS settings.

```swift
actor DNSConfigurator {
    /// Current DNS configuration
    var currentConfig: DNSConfig? { get }
    
    /// Apply DNS configuration
    /// - Parameters:
    ///   - config: DNS configuration to apply
    ///   - interface: Network interface
    func applyDNS(_ config: DNSConfig, interface: String) async throws
    
    /// Restore original DNS
    /// - Parameter interface: Network interface
    func restoreDNS(interface: String) async throws
    
    /// Verify DNS is applied
    func verifyDNS(interface: String) async -> Bool
}

struct DNSConfig: Codable {
    let provider: DNSProvider
    let servers: [String]
    let dohURL: String?
    let dotHostname: String?
}

enum DNSProvider: String, Codable, CaseIterable {
    case cloudflare = "Cloudflare"
    case quad9 = "Quad9"
    case custom = "Custom"
}
```

### ReversionVerifier

Verifies network settings are properly restored.

```swift
actor ReversionVerifier {
    /// Verify all settings reverted
    /// - Parameter interface: Network interface
    /// - Returns: Reversion status
    func verifyReversion(interface: String) async -> ReversionStatus
    
    /// Force reversion if verification fails
    /// - Parameter interface: Network interface
    /// - Returns: True if successful
    func forceReversion(interface: String) async -> Bool
}

enum ReversionStatus {
    case fullyRestored
    case partiallyRestored(failed: [String])
    case verificationFailed
}
```

### SessionStore

Persists cloaking session history.

```swift
class SessionStore {
    /// Save a completed session
    func saveSession(_ session: CloakingSession)
    
    /// Get all sessions
    func getAllSessions() -> [SessionRecord]
    
    /// Get sessions for specific profile
    func getSessionsForProfile(profileId: UUID) -> [SessionRecord]
    
    /// Calculate statistics
    func calculateStatistics() -> SessionStatistics
    
    /// Export to JSON
    func exportToJSON() throws -> Data
    
    /// Clear all history
    func clearHistory()
}

struct SessionRecord: Codable {
    let id: UUID
    let profileId: UUID
    let ssid: String
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let totalUploaded: UInt64
    let totalDownloaded: UInt64
    let wasSuccessful: Bool
}

struct SessionStatistics {
    let totalSessions: Int
    let totalDuration: TimeInterval
    let averageDuration: TimeInterval
    let mostUsedSSID: String?
    let totalDataUsed: UInt64
}
```

### TrafficShaper

Intelligent traffic shaping using macOS pfctl.

```swift
actor TrafficShaper {
    /// Available traffic categories
    enum TrafficCategory: CaseIterable {
        case macOSUpdates
        case iCloudSync
        case appStore
        case timeMachine
        case softwareUpdate
        case backgroundDownloads
    }
    
    /// Apply traffic shaping rules
    /// - Returns: True if successful
    func applyShaping() async throws -> Bool
    
    /// Remove all shaping rules
    /// - Returns: True if successful
    func removeShaping() async throws -> Bool
    
    /// Pause shaping temporarily
    /// - Parameter duration: Time to pause
    func pauseShaping(duration: TimeInterval) async
    
    /// Get current shaping status
    func isShapingActive() async -> Bool
}

struct ShapingRule {
    let category: TrafficShaper.TrafficCategory
    let delayMs: Int
    let bandwidthKbps: Int?
    let priority: Int
}
```

### KeyboardShortcuts

Global keyboard shortcut management.

```swift
class KeyboardShortcuts: ObservableObject {
    /// Registered shortcuts
    var shortcuts: [ShortcutAction: KeyboardShortcut] { get }
    
    /// Register a new shortcut
    /// - Parameters:
    ///   - action: Action to trigger
    ///   - shortcut: Key combination
    func registerShortcut(for action: ShortcutAction, shortcut: KeyboardShortcut)
    
    /// Unregister a shortcut
    /// - Parameter action: Action to unregister
    func unregisterShortcut(for action: ShortcutAction)
    
    /// Get shortcut for action
    func shortcut(for action: ShortcutAction) -> KeyboardShortcut?
}

enum ShortcutAction: String, CaseIterable {
    case toggleCloaking
    case emergencyStop
    case openDashboard
    case openProfiles
}

struct KeyboardShortcut: Codable {
    let key: String
    let modifiers: [Modifier]
    
    enum Modifier: String, Codable {
        case command
        case option
        case control
        case shift
    }
}
```

### ProfileImportExport

Import/export profiles with JSON format.

```swift
class ProfileImportExport {
    /// Export profiles to shareable format
    /// - Parameters:
    ///   - profiles: Profiles to export
    ///   - customDNS: Custom DNS configurations
    ///   - shortcuts: Keyboard shortcuts
    /// - Returns: Export package
    func exportProfiles(
        _ profiles: [HotspotProfile],
        customDNS: [CustomDNSConfig],
        shortcuts: [KeyboardShortcut]
    ) async throws -> ExportPackage
    
    /// Import profiles from data
    /// - Parameters:
    ///   - data: JSON data
    ///   - mergeStrategy: How to handle duplicates
    /// - Returns: Import result
    func importProfiles(
        from data: Data,
        mergeStrategy: MergeStrategy
    ) async throws -> ImportResult
}

enum MergeStrategy {
    case skipDuplicates
    case overwrite
    case rename
}

struct ImportResult {
    let imported: Int
    let skipped: Int
    let errors: [ImportError]
}

struct ExportPackage: Codable {
    let version: String
    let exportDate: Date
    let profiles: [HotspotProfile]
    let customDNS: [CustomDNSConfig]
    let shortcuts: [ShortcutAction: KeyboardShortcut]
}
```

---

## Data Models

### HotspotProfile

Configuration for a mobile hotspot.

```swift
struct HotspotProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var ssid: String
    var targetTTL: Int
    var targetMTU: Int
    var autoActivate: Bool
    var enableTrafficShaping: Bool
    var useEncryptedDNS: Bool
    var dnsProvider: DNSProvider
    var customDNSServers: [String]
    var hourlyDataThresholdGB: Double
    var dailyDataThresholdGB: Double
    
    init(
        id: UUID = UUID(),
        ssid: String,
        targetTTL: Int = 65,
        targetMTU: Int = 1400,
        autoActivate: Bool = true,
        enableTrafficShaping: Bool = true,
        useEncryptedDNS: Bool = true,
        dnsProvider: DNSProvider = .cloudflare,
        customDNSServers: [String] = [],
        hourlyDataThresholdGB: Double = 10.0,
        dailyDataThresholdGB: Double = 50.0
    )
}
```

### CloakingSession

Represents an active or completed cloaking session.

```swift
class CloakingSession: ObservableObject, Identifiable {
    let id: UUID
    let profileId: UUID
    let ssid: String
    let interface: String
    let startTime: Date
    let appliedTTL: Int
    let appliedMTU: Int
    
    var endTime: Date?
    var totalUploaded: UInt64
    var totalDownloaded: UInt64
    var isActive: Bool
    
    /// Mark session as complete
    func complete()
    
    /// Duration of session
    var duration: TimeInterval { get }
    
    /// Total data used
    var totalDataUsed: UInt64 { get }
}
```

### SafetyThreshold

Data usage thresholds for alerting.

```swift
struct SafetyThreshold: Codable {
    var hourlyLimitGB: Double
    var dailyLimitGB: Double
    var warningPercentage: Double
    
    static let `default` = SafetyThreshold(
        hourlyLimitGB: 10.0,
        dailyLimitGB: 50.0,
        warningPercentage: 0.75
    )
}
```

---

## Views

### MenuBarView

Main menu bar interface.

```swift
struct MenuBarView: View {
    @ObservedObject var appState: AppState
    
    var body: some View { }
}
```

### DashboardView

Real-time monitoring dashboard.

```swift
struct DashboardView: View {
    @ObservedObject var appState: AppState
    @StateObject private var metricsCollector: MetricsCollector
    
    var body: some View { }
}
```

### ProfileListView

List and manage profiles.

```swift
struct ProfileListView: View {
    @ObservedObject var appState: AppState
    @State private var profiles: [HotspotProfile] = []
    
    var body: some View { }
}
```

---

## XPC Protocol

### XPCServiceProtocol

Protocol for XPC communication.

```swift
@objc protocol XPCServiceProtocol {
    /// Apply network modifications
    func applyModification(
        ttl: Int,
        mtu: Int,
        interface: String,
        reply: @escaping (Bool, Error?) -> Void
    )
    
    /// Revert network modifications
    func revertModification(
        interface: String,
        reply: @escaping (Bool, Error?) -> Void
    )
    
    /// Verify settings are applied
    func verifySettings(
        ttl: Int,
        mtu: Int,
        interface: String,
        reply: @escaping (Bool) -> Void
    )
    
    /// Get helper version
    func getVersion(reply: @escaping (String) -> Void)
    
    /// Ping for connectivity check
    func ping(reply: @escaping () -> Void)
}

/// Protocol for client to receive async updates (if needed)
@objc protocol XPCClientProtocol {
    func receiveEvent(_ event: [String: Any])
}
```

---

## Utilities

### AppState

Central state management.

```swift
@MainActor
class AppState: ObservableObject {
    @Published var status: AppStatus
    @Published var profiles: [HotspotProfile]
    @Published var activeSession: CloakingSession?
    @Published var currentNetwork: WiFiNetwork?
    @Published var error: AppError?
    
    /// Shared instance
    static let shared = AppState()
    
    /// Initialize all services
    func initialize()
    
    /// Handle connection to configured hotspot
    func handleConnection(to profile: HotspotProfile)
    
    /// Handle disconnection
    func handleDisconnection()
    
    /// Activate emergency stop
    func emergencyStop()
}

enum AppStatus: Equatable {
    case idle
    case connecting
    case cloakingActive
    case reverting
    case error(String)
}
```

### Logger

Unified logging utility.

```swift
enum Logger {
    static func debug(_ message: String)
    static func info(_ message: String)
    static func warning(_ message: String)
    static func error(_ message: String, error: Swift.Error?)
    static func fault(_ message: String)
    
    static func network(_ message: String, level: LogLevel)
    static func xpc(_ message: String, level: LogLevel)
    static func ui(_ message: String, level: LogLevel)
    
    /// Secure audit logging
    static func audit(
        action: String,
        actor: String,
        target: String,
        result: AuditResult,
        metadata: [String: String]
    )
}

enum LogLevel: Int, Comparable {
    case debug, info, warning, error, fault
}

enum AuditResult {
    case success
    case failure(reason: String)
    case denied(reason: String)
}
```

### NetworkModifier

Low-level network parameter modification.

```swift
struct NetworkModifier {
    /// Apply TTL modification using sysctl
    static func applyTTL(_ ttl: Int) throws
    
    /// Apply MTU modification using networksetup
    static func applyMTU(_ mtu: Int, interface: String) throws
    
    /// Revert TTL to default (64)
    static func revertTTL() throws
    
    /// Revert MTU to default (1500)
    static func revertMTU(interface: String) throws
    
    /// Get current TTL
    static func currentTTL() throws -> Int
    
    /// Get current MTU for interface
    static func currentMTU(interface: String) throws -> Int
}
```

---

**Document Version**: 1.0  
**Last Updated**: 2026-02-05
