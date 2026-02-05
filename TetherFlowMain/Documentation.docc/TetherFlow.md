# ``TetherFlow``

TetherFlow is a macOS Menu Bar application for intelligent network cloaking when connected to mobile hotspots.

## Overview

TetherFlow automatically detects configured Wi-Fi hotspots and applies network parameter modifications to make your MacBook's traffic appear as if originating from a mobile device. This includes TTL and MTU adjustments, traffic shaping, and encrypted DNS.

## Features

### Core Features
- **Hotspot Recognition** - Automatic detection of configured Wi-Fi SSIDs
- **Protocol Cloaking** - Multi-layer packet fingerprinting (TTL/MTU)
- **Traffic Shaping** - Intelligent delay of desktop-specific traffic
- **Encrypted DNS** - DoH/DoT for privacy
- **Dashboard** - Real-time network monitoring
- **Zero-State Reversion** - Automatic restoration on disconnect

### Advanced Features
- **Traffic Shaping** - pfctl-based bandwidth management
- **Keyboard Shortcuts** - Global hotkeys for quick control
- **Profile Import/Export** - JSON-based profile sharing
- **Custom DNS** - User-defined DNS servers

## Topics

### App Entry Point
- ``TetherFlowApp``

### Main Views
- ``MenuBarView``
- ``DashboardView``
- ``ProfileListView``
- ``ProfileAddEditView``

### Services

#### Core Services
- ``WiFiMonitor``
- ``ProfileStore``
- ``CloakingEngine``
- ``XPCClient``

#### Configuration
- ``NetworkConfigurator``
- ``DNSConfigurator``
- ``NetworkModifier``

#### Monitoring
- ``MetricsCollector``
- ``SafetyMonitor``

#### Advanced
- ``TrafficShaper``
- ``ReversionVerifier``
- ``SessionStore``
- ``KeyboardShortcuts``
- ``ProfileImportExport``

### Data Models
- ``HotspotProfile``
- ``CloakingSession``
- ``WiFiNetwork``
- ``TrafficMetrics``

### XPC
- ``HelperInstaller``
- ``XPCServer``
- ``XPCServiceProtocol``

### Utilities
- ``AppState``
- ``Logger``
- ``KeychainManager``
- ``NetworkSpeedFormatter``
