# Feature Specification: macOS Network Cloaking & Optimization Utility

**Feature Branch**: `001-network-cloak-utility`  
**Created**: 2026-02-05  
**Status**: Draft  
**Input**: User description: Create a specialized macOS Network Cloaking & Optimization Utility. The application automatically "hijacks" the network protocol layer when a user connects to a specific mobile hotspot. Its primary objective is to ensure all MacBook network traffic appears identical to local on-device mobile traffic from the ISP's perspective, enabling true unlimited tethering.

## Problem Statement

Users with "unlimited" mobile plans face tethering caps (15GB-30GB) that throttle speeds to unusable levels after exceeded. ISPs detect tethering via Deep Packet Inspection (DPI) by identifying specific packet headers (TTL decrements) and desktop-specific traffic patterns. Manual CLI workarounds are tedious and require technical expertise.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Initial Setup & Hotspot Recognition (Priority: P1)

User configures the application once by defining their unlimited mobile hotspot SSID. The app automatically detects when this hotspot is connected and activates cloaking.

**Why this priority**: This is the core workflow - without proper setup and detection, the entire utility is useless. It establishes the "set and forget" foundation.

**Independent Test**: Can be fully tested by configuring a hotspot SSID, connecting to it, and verifying the menu bar icon turns green indicating "Cloaking Active"

**Acceptance Scenarios**:

1. **Given** the app is installed, **When** user configures their mobile hotspot SSID (e.g., "MyUnlimited5G"), **Then** the configuration is saved persistently
2. **Given** a configured hotspot, **When** MacBook connects to that specific SSID, **Then** the cloaking engine automatically activates within 3 seconds
3. **Given** cloaking is active, **When** user looks at the menu bar, **Then** the app icon displays green status indicator
4. **Given** the app is configured, **When** MacBook connects to a different Wi-Fi (e.g., office network), **Then** cloaking remains inactive and icon shows gray/neutral state

---

### User Story 2 - Protocol Cloaking & Packet Manipulation (Priority: P1)

When connected to the configured hotspot, the app automatically modifies network packets to mask tethering signatures.

**Why this priority**: Core functionality that prevents ISP detection. Without TTL and MTU manipulation, the utility cannot achieve its primary goal.

**Independent Test**: Can be tested by connecting to hotspot, verifying packet modifications through network analysis tools, and confirming TTL values match mobile device standards

**Acceptance Scenarios**:

1. **Given** cloaking is active, **When** any network packet is sent, **Then** TTL is set to 65 (arriving at ISP as 64, matching mobile device standards)
2. **Given** cloaking is active, **When** data is transmitted, **Then** MTU is adjusted to match mobile hotspot standards (1280-1500 bytes range)
3. **Given** cloaking is active, **When** desktop-specific background requests occur (macOS updates, iCloud sync), **Then** they are blocked or intelligently delayed to prevent detection patterns
4. **Given** cloaking is active, **When** DNS queries are made, **Then** they use encrypted DNS (DoH/DoT) by default to prevent ISP analysis

---

### User Story 3 - Monitoring Dashboard & Safety Controls (Priority: P2)

User can view real-time network status, data usage simulation, and control safety features through an intuitive dashboard.

**Why this priority**: Provides transparency and safety controls. While not strictly required for basic functionality, it builds user trust and prevents detection.

**Independent Test**: Can be tested by opening the dashboard, verifying real-time metrics display, and testing the kill-switch functionality

**Acceptance Scenarios**:

1. **Given** the dashboard is open, **When** network traffic flows, **Then** real-time upload/download speeds are displayed with mobile-typical usage profile comparison
2. **Given** data throughput exceeds predefined thresholds (10GB/hour or 50GB/day), **When** the threshold is crossed, **Then** an alert is shown warning of potential ISP fraud-detection risk
3. **Given** cloaking is active, **When** user clicks the emergency kill-switch, **Then** all cloaked tunnels drop immediately and network stack resets to default within 2 seconds
4. **Given** the dashboard is open, **When** user reviews session history, **Then** they can see data usage statistics and cloaking session duration

---

### User Story 4 - Zero-State Reversion (Priority: P2)

When disconnecting from the hotspot, the app instantly reverts all network configurations to ensure standard network performance on other networks.

**Why this priority**: Critical for user experience on non-hotspot networks. Without proper cleanup, modified network settings could interfere with normal network operation.

**Independent Test**: Can be tested by disconnecting from hotspot and verifying all network settings return to system defaults

**Acceptance Scenarios**:

1. **Given** cloaking is active on hotspot, **When** user disconnects from the Wi-Fi or connects to a different network, **Then** all TTL, MTU, and DNS modifications revert within 2 seconds
2. **Given** network settings were modified, **When** reversion completes, **Then** standard network performance is restored without requiring app restart
3. **Given** the app is running, **When** system wakes from sleep on a non-hotspot network, **Then** cloaking remains inactive and no residual configurations persist

---

### Edge Cases

- What happens when the hotspot SSID is changed or renamed?
- How does the system handle multiple network interfaces (Wi-Fi + Ethernet + VPN)?
- What happens if the app crashes while cloaking is active?
- How does the system behave when connected to a hotspot with captive portal authentication?
- What happens when mobile hotspot signal is weak or intermittent?
- How does the app handle macOS system updates that may affect network stack?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to configure one or more "unlimited mobile hotspot" SSIDs
- **FR-002**: System MUST automatically detect when MacBook connects to a configured hotspot SSID
- **FR-003**: System MUST automatically activate cloaking engine within 3 seconds of hotspot detection
- **FR-004**: System MUST set outgoing packet TTL to 65 to match mobile device fingerprint (arriving at ISP as 64)
- **FR-005**: System MUST adjust MTU values to match mobile hotspot standards (1280-1500 bytes)
- **FR-006**: System MUST intelligently delay and shape desktop-specific background traffic (macOS updates, large iCloud syncs) during hotspot sessions to mimic mobile device patterns
- **FR-007**: System MUST default to encrypted DNS queries (DoH/DoT) during cloaking sessions
- **FR-008**: System MUST display real-time network speed metrics in a dashboard
- **FR-009**: System MUST alert users when data throughput exceeds configurable risk thresholds (default: 10GB/hour, 50GB/day)
- **FR-010**: System MUST provide an emergency kill-switch to instantly disable cloaking and reset network stack
- **FR-011**: System MUST automatically revert all network configurations to defaults when disconnecting from hotspot
- **FR-012**: System MUST show visual status indicator (menu bar icon) showing cloaking state (active/inactive)
- **FR-013**: System MUST operate with near-zero CPU footprint to avoid interfering with user workflows

### Key Entities

- **HotspotProfile**: Represents a configured mobile hotspot with SSID, cloaking preferences, and safety thresholds
- **CloakingSession**: Tracks an active cloaking session including start time, data usage, and current network modifications
- **TrafficRule**: Defines rules for blocking/delaying specific traffic types during cloaking
- **SafetyThreshold**: Configurable limits for data throughput that trigger risk alerts
- **NetworkConfiguration**: Stores original network settings for reversion purposes

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can configure hotspot recognition in under 2 minutes on first setup
- **SC-002**: Cloaking activation occurs within 3 seconds of hotspot connection
- **SC-003**: 100% of outgoing packets have TTL=65 when cloaking is active
- **SC-004**: Desktop-specific background traffic is reduced by at least 90% during cloaking sessions
- **SC-005**: Emergency kill-switch resets network stack within 2 seconds of activation
- **SC-006**: Network configuration reversion completes within 2 seconds of hotspot disconnect
- **SC-007**: App CPU usage remains under 1% during normal operation on M4 Pro-class hardware
- **SC-008**: App memory footprint remains under 100MB during continuous operation
- **SC-009**: Dashboard displays accurate network speed metrics (±5% variance from system measurements)
- **SC-010**: 95% of users successfully complete initial setup without requiring documentation

## Assumptions

- Users have administrative privileges on their macOS system to modify network settings
- Target macOS versions are macOS 13 (Ventura) and later
- Users have basic understanding of their mobile hotspot SSID
- ISPs primarily detect tethering via TTL analysis and traffic pattern recognition
- The utility targets "unlimited" mobile plans with soft tethering caps, not hard data limits
- Network performance optimization is secondary to cloaking effectiveness

## Clarified Decisions

### Risk Threshold Values
**Selected**: Moderate approach - 10GB/hour, 50GB/day

Rationale: This balanced approach provides sufficient warning for typical heavy usage while avoiding excessive false positives for power users. Thresholds are user-configurable with these as sensible defaults.

### Traffic Blocking Strategy
**Selected**: Intelligent delay with traffic shaping

Rationale: This approach provides strong protection against ISP detection while preserving background application functionality. Traffic is intelligently delayed and shaped to mimic mobile device patterns rather than completely blocked.
