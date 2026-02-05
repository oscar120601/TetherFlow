# Research: macOS Network Cloaking & Optimization Utility

**Date**: 2026-02-05  
**Feature**: macOS Network Cloaking & Optimization Utility  
**Purpose**: Document research decisions for technical implementation

---

## R1: Privilege Escalation Mechanism

### Decision
Use **ServiceManagement.framework SMJobBless** for secure helper tool installation and authorization.

### Rationale
- **Apple-approved**: This is the industry-standard, Apple-recommended approach for macOS apps requiring root privileges
- **Security**: Automatically validates code signing; helper must be signed with same Developer ID as main app
- **User trust**: Presents standard macOS authentication dialog; no custom password prompts
- **Distribution**: Compatible with App Notarization and standard distribution methods

### Implementation Details
- Helper tool is embedded in main app bundle
- SMJobBless copies helper to `/Library/PrivilegedHelperTools/` on first run
- Launchd plist configured for on-demand launch (no persistent daemon)
- XPC connection established when privileges needed

### Alternatives Considered

| Approach | Why Rejected |
|----------|--------------|
| Authorization Services | Deprecated by Apple in favor of SMJobBless |
| setuid binaries | Security risk; not App Store compatible; requires manual installation |
| Sudo with AppleScript | Poor UX; security warning dialogs; fragile |

---

## R2: TTL (Time To Live) Modification

### Decision
Use direct **`sysctlbyname()`** C API with `net.inet.ip.ttl` parameter.

### Rationale
- **Performance**: Direct kernel parameter access; no shell overhead
- **Latency**: <1ms modification time vs ~50-100ms for shell commands
- **Reliability**: System call returns clear success/failure; no output parsing
- **Atomic**: Changes take effect immediately for all new connections

### Implementation Details
```c
#include <sys/sysctl.h>

int set_ttl(int ttl) {
    int mib[] = { CTL_NET, PF_INET, IPPROTO_IP, IPCTL_DEFTTL };
    return sysctl(mib, 4, NULL, NULL, &ttl, sizeof(ttl));
}
```

Target values:
- **Initial TTL**: 65 (becomes 64 after one hop, matching mobile devices)
- **Default restore**: 64 (standard macOS default)

### Alternatives Considered

| Approach | Why Rejected |
|----------|--------------|
| `sysctl` command | Shell overhead; output parsing required |
| `networksetup` | Doesn't support TTL modification |
| pfctl rules | Can only filter, not modify packet headers |
| iptables equivalent | macOS doesn't use iptables |

---

## R3: Wi-Fi SSID Monitoring

### Decision
Use **CoreWLAN** `CWWiFiClient` with Key-Value Observing (KVO).

### Rationale
- **Native framework**: Official Apple API for Wi-Fi management
- **Real-time**: Immediate notifications on network change
- **Efficient**: Event-driven vs polling
- **Reliable**: Doesn't depend on private APIs or command-line tools

### Implementation Details
```swift
import CoreWLAN

class WiFiMonitor: NSObject {
    private var wifiClient = CWWiFiClient.shared()
    
    func startMonitoring() {
        wifiClient.delegate = self
        try? wifiClient.startMonitoringEvent(with: .ssidDidChange)
    }
}

extension WiFiMonitor: CWEventDelegate {
    func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        // Handle SSID change
    }
}
```

### Alternatives Considered

| Approach | Why Rejected |
|----------|--------------|
| `system_profiler SPAirPortDataType` | Requires polling; slow (seconds) |
| `/System/Library/PrivateFrameworks` | Private API; fragile; may break in updates |
| `airport` utility | Private tool; path varies; not guaranteed |

---

## R4: MTU (Maximum Transmission Unit) Modification

### Decision
Use **`networksetup`** command via Helper Tool for MTU configuration.

### Rationale
- **Stability**: `networksetup` is the supported macOS tool for network configuration
- **Interface-specific**: Can set different MTU per network interface
- **Safe**: Automatically validates MTU range (1280-9000 for most interfaces)
- **Reversible**: Easy to restore default MTU

### Implementation Details
```bash
# Set MTU
networksetup -setMTU <interface> <mtu_value>

# Get current MTU
networksetup -getMTU <interface>
```

Target values:
- **Cloaking MTU**: 1400 bytes (optimized for mobile networks)
- **Default MTU**: 1500 bytes (standard Ethernet)

### Alternatives Considered

| Approach | Why Rejected |
|----------|--------------|
| `ifconfig` | Deprecated; superseded by `networksetup` |
| `sysctl` net.inet.ip.maxmtu | Affects all interfaces; too broad |
| Direct ioctl | Requires C; more complex; no clear benefit |

---

## R5: Traffic Shaping (Background Traffic Management)

### Decision
Use **`pfctl`** (macOS Packet Filter) for intelligent traffic delay/shaping.

### Rationale
- **Built-in**: Part of macOS since 10.7; no external dependencies
- **Flexible**: Can delay, shape, or block specific traffic types
- **Rule-based**: Can target specific processes, ports, or hosts
- **Reversible**: Rules can be added/removed dynamically

### Implementation Details
```bash
# Load anchor configuration
pfctl -a tetherflow -f /dev/stdin <<EOF
# Delay macOS update traffic
pass out proto tcp from any to 17.0.0.0/8 port 443 delay 500ms

# Delay iCloud sync
pass out proto tcp from any to 17.248.0.0/13 port 443 delay 1s
EOF

# Enable
echo "anchor tetherflow" | pfctl -f -
pfctl -e
```

### Traffic Categories to Shape
1. **macOS Software Updates**: Apple CDN (17.0.0.0/8)
2. **iCloud Sync**: iCloud services (17.248.0.0/13)
3. **App Store**: App downloads and updates
4. **Background analytics**: Diagnostic uploads

### Alternatives Considered

| Approach | Why Rejected |
|----------|--------------|
| Complete blocking | Violates UX principle; breaks background functionality |
| NetworkExtension | Overkill; requires user approval for each change; heavy |
| Little Snitch API | Third-party dependency; commercial; complex |

---

## R6: Encrypted DNS (DoH/DoT)

### Decision
Use **Network.framework** with native DoH/DoT configuration.

### Rationale
- **Native**: First-class macOS networking API
- **Automatic**: Handles DNS over HTTPS/TLS without manual configuration
- **Secure**: Built-in certificate validation
- **Efficient**: Integrated with system DNS cache

### Implementation Details
```swift
import Network

let privacyContext = NWPrivacyContext()
// Network.framework automatically uses DoH/DoT when available
// based on system settings
```

### Provider Selection
Default providers (user-configurable):
- **Cloudflare**: 1.1.1.1 (DoH: https://cloudflare-dns.com/dns-query)
- **Quad9**: 9.9.9.9 (security-focused)

### Alternatives Considered

| Approach | Why Rejected |
|----------|--------------|
| Manual DNS servers | Plain DNS still visible to ISP |
| DNS-over-HTTPS libraries | Unnecessary dependency; Network.framework sufficient |
| VPN-based DNS | Overkill; adds latency; complex |

---

## R7: XPC Communication Protocol

### Decision
Use **NSXPCConnection** with Objective-C protocol.

### Rationale
- **Apple-standard**: Designed specifically for app/helper communication
- **Type-safe**: Protocol-based with compile-time checking
- **Async**: Built-in support for async replies
- **Secure**: Automatic entitlement checking

### Protocol Definition
```objc
// HelperProtocol.h
@import Foundation;

@protocol HelperProtocol
- (void)applyCloakingWithTTL:(int)ttl 
                         mtu:(int)mtu 
                   interface:(NSString *)interface 
                   withReply:(void (^)(BOOL success))reply;

- (void)resetNetworkSettingsWithInterface:(NSString *)interface 
                                withReply:(void (^)(BOOL success))reply;

- (void)getCurrentTTLWithReply:(void (^)(int ttl))reply;
@end
```

### Security Considerations
- Connection validates helper code signature
- Helper validates connecting app bundle ID
- All parameters validated before execution

---

## R8: UI Framework

### Decision
Use **SwiftUI** with `MenuBarExtra` for macOS 13+.

### Rationale
- **Modern**: Native declarative UI framework
- **Lightweight**: Minimal resource usage
- **Integrated**: Works seamlessly with MenuBarExtra
- **Maintainable**: Less code than AppKit equivalent

### Implementation Pattern
```swift
import SwiftUI

@main
struct TetherFlowApp: App {
    var body: some Scene {
        MenuBarExtra("TetherFlow", systemImage: "antenna.radiowaves.left.and.right") {
            ContentView()
        }
    }
}
```

### Icon States
- **Gray**: No hotspot connected
- **Green**: Cloaking active
- **Yellow**: Warning (high data usage)
- **Red**: Error state

### Alternatives Considerations

| Approach | Why Rejected |
|----------|--------------|
| AppKit/NSStatusBar | More verbose; legacy; SwiftUI preferred |
| Catalyst | Not appropriate for menu bar apps |

---

## R9: Data Persistence

### Decision
Use **UserDefaults** for HotspotProfile storage.

### Rationale
- **Simple**: Key-value storage ideal for configuration
- **Secure**: Automatically stored in user's keychain container
- **Synced**: iCloud Keychain sync support
- **Appropriate**: Data size is small (<1KB per profile)

### Storage Structure
```swift
struct HotspotProfile: Codable {
    let id: UUID
    let ssid: String
    var targetTTL: Int      // Default: 65
    var targetMTU: Int      // Default: 1400
    var autoActivate: Bool  // Default: true
    var blockBackgroundTraffic: Bool  // Default: true
    var hourlyThreshold: Double  // Default: 10 (GB)
    var dailyThreshold: Double   // Default: 50 (GB)
}
```

### Alternatives Considered

| Approach | Why Rejected |
|----------|--------------|
| Core Data | Overkill for simple configuration |
| SQLite | Unnecessary complexity |
| JSON files | Less secure; manual sync handling |

---

## R10: Performance Optimization (M4 Pro)

### Decision
Implement aggressive performance optimizations for Apple Silicon.

### Rationale
- **Target hardware**: M4 Pro has specific characteristics (unified memory, efficiency cores)
- **Battery life**: Must minimize power consumption
- **Background operation**: Should not impact foreground tasks
- **Constitution requirement**: CPU < 0.1%, Memory < 100MB

### Optimization Strategies

1. **Lazy initialization**: Helper tool only launched when needed
2. **Event-driven**: No polling loops; all monitoring via callbacks
3. **Efficient XPC**: Batch operations; minimize cross-process calls
4. **Memory**: No caching of large datasets; streaming metrics
5. **Swift Concurrency**: Use async/await for all I/O operations

### Alternatives Considered

| Approach | Why Rejected |
|----------|--------------|
| Background polling | Violates performance requirements |
| Persistent helper daemon | Wastes resources; on-demand preferred |

---

## Summary

| Component | Technology | Justification |
|-----------|-----------|---------------|
| Privilege Escalation | SMJobBless | Apple standard, secure |
| TTL Modification | sysctlbyname() | Direct kernel, fast |
| MTU Modification | networksetup | Safe, supported |
| Wi-Fi Monitoring | CoreWLAN | Native, real-time |
| Traffic Shaping | pfctl | Built-in, flexible |
| Encrypted DNS | Network.framework | Native DoH/DoT |
| XPC | NSXPCConnection | Type-safe, secure |
| UI | SwiftUI + MenuBarExtra | Modern, lightweight |
| Storage | UserDefaults | Simple, secure |
| Performance | Event-driven, lazy init | Meets <0.1% CPU target |
