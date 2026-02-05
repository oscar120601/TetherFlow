# Tasks: macOS Network Cloaking & Optimization Utility

**Input**: Design documents from `/specs/001-network-cloak-utility/`  
**Prerequisites**: plan.md (required), spec.md (required for user stories), data-model.md, contracts/, research.md, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

---

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Project Initialization) ✅ COMPLETE

**Purpose**: Project scaffolding and basic configuration

- [x] T001 Create Xcode project directory structure at `TetherFlow/`
- [x] T002 Initialize main app target `TetherFlow` with SwiftUI template
- [x] T003 Initialize helper tool target `TetherFlowHelper` with Objective-C/C template
- [x] T004 [P] Configure code signing settings in Xcode for both targets
- [x] T005 [P] Set up `LSUIElement = YES` in `TetherFlow/Info.plist` for menu bar app
- [x] T006 [P] Configure `Helper-Launchd.plist` with correct MachServices entry
- [x] T007 Create build scripts: `Scripts/setup-helper.sh` and `Scripts/codesign-check.sh`
- [x] T008 [P] Set up `.gitignore` for Xcode projects (xcuserdata, build/, .DS_Store)
- [x] T009 [P] Initialize test targets: `TetherFlowTests`, `TetherFlowUITests`, `IntegrationTests`

**Checkpoint**: Project builds successfully; targets visible in Xcode

---

## Phase 2: Foundational Infrastructure (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### XPC Communication Foundation

- [ ] T010 Create `TetherFlowHelper/HelperProtocol.h` with complete protocol definition
- [ ] T011 Implement `TetherFlowHelper/main.m` with XPC listener setup
- [ ] T012 Implement `TetherFlowHelper/Helper.m` with protocol method stubs
- [ ] T013 Implement `TetherFlow/Services/XPCClient.swift` with connection management
- [ ] T014 [P] Add code signing validation in helper tool
- [ ] T015 Implement helper installation logic using SMJobBless in `TetherFlow/Services/HelperInstaller.swift`

### Network Modification Foundation (C Layer)

- [ ] T016 Create `TetherFlowHelper/NetworkModifier.h` with function declarations
- [ ] T017 Implement `TetherFlowHelper/NetworkModifier.c` with sysctl TTL wrapper
- [ ] T018 Implement MTU modification using networksetup in `TetherFlowHelper/NetworkModifier.c`
- [ ] T019 Add error handling and logging to C wrappers

### Core Data Models

- [ ] T020 [P] Implement `TetherFlow/Models/HotspotProfile.swift` with Codable conformance
- [ ] T021 [P] Implement `TetherFlow/Models/AppState.swift` with ObservableObject
- [ ] T022 [P] Implement `TetherFlow/Models/NetworkMetrics.swift` for real-time metrics
- [ ] T023 [P] Implement `TetherFlow/Models/SafetyThreshold.swift` with threshold logic
- [ ] T024 Create `TetherFlow/Utils/Logger.swift` for unified logging

### Persistence Layer

- [ ] T025 Implement `TetherFlow/Services/ProfileStore.swift` for UserDefaults persistence
- [ ] T026 Add profile validation and error handling

**Checkpoint**: Foundation ready - XPC connects, helper installs, models save/load

---

## Phase 3: User Story 1 - Initial Setup & Hotspot Recognition (Priority: P1) 🎯 MVP

**Goal**: User configures the app once by defining their unlimited mobile hotspot SSID. The app automatically detects when this hotspot is connected and activates cloaking.

**Independent Test**: Configure a hotspot SSID, connect to it, and verify the menu bar icon turns green indicating "Cloaking Active"

### Tests for User Story 1 (Optional - if TDD requested)

- [ ] T027 [P] [US1] Create unit tests for HotspotProfile validation in `TetherFlowTests/HotspotProfileTests.swift`
- [ ] T028 [P] [US1] Create unit tests for ProfileStore persistence in `TetherFlowTests/ProfileStoreTests.swift`

### Implementation for User Story 1

#### Wi-Fi Monitoring

- [ ] T029 [US1] Implement `TetherFlow/Services/WiFiMonitor.swift` using CWWiFiClient
- [ ] T030 [US1] Add SSID change detection with KVO observers
- [ ] T031 [US1] Implement SSID matching logic against configured profiles

#### UI: Profile Management

- [ ] T032 [P] [US1] Create `TetherFlow/Views/ProfileListView.swift` for managing hotspot profiles
- [ ] T033 [P] [US1] Create `TetherFlow/Views/AddProfileView.swift` for adding new profiles
- [ ] T034 [P] [US1] Create `TetherFlow/Views/EditProfileView.swift` for editing profile settings

#### UI: Menu Bar

- [ ] T035 [US1] Create `TetherFlow/Views/MenuBarView.swift` with status indicator
- [ ] T036 [US1] Implement status icon states: gray (idle), green (cloaking active)
- [ ] T037 [US1] Add profile selection dropdown to menu bar

#### Logic: Profile Management

- [ ] T038 [US1] Implement add profile flow with validation
- [ ] T039 [US1] Implement edit profile flow
- [ ] T040 [US1] Implement delete profile with confirmation

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Protocol Cloaking & Packet Manipulation (Priority: P1) 🎯 MVP

**Goal**: When connected to the configured hotspot, the app automatically modifies network packets to mask tethering signatures.

**Independent Test**: Connect to hotspot, verify packet modifications through network analysis tools, and confirm TTL values match mobile device standards

### Tests for User Story 2 (Optional)

- [ ] T041 [P] [US2] Create unit tests for XPC communication in `IntegrationTests/XPCCommunicationTests.swift`
- [ ] T042 [P] [US2] Create tests for TTL modification in `TetherFlowTests/NetworkModifierTests.swift`

### Implementation for User Story 2

#### XPC Protocol Implementation

- [ ] T043 [US2] Implement `applyCloakingWithTTL:mtu:interface:withReply:` in `Helper.m`
- [ ] T044 [US2] Wire up C sysctl wrapper for TTL modification
- [ ] T045 [US2] Implement MTU modification via networksetup in helper
- [ ] T046 [US2] Implement `resetNetworkSettingsWithInterface:withReply:` for reversion
- [ ] T047 [US2] Implement `getCurrentTTLWithReply:` for verification

#### Network Configuration Service

- [ ] T048 [US2] Implement `TetherFlow/Services/NetworkConfigurator.swift`
- [ ] T049 [US2] Add cloaking activation logic (TTL=65, MTU=1400)
- [ ] T050 [US2] Add cloaking deactivation logic (restore defaults)
- [ ] T051 [US2] Implement verification methods to confirm settings applied

#### Cloaking Engine

- [ ] T052 [US2] Create `TetherFlow/Services/CloakingEngine.swift` to coordinate activation
- [ ] T053 [US2] Implement automatic cloaking trigger when matching SSID connected
- [ ] T054 [US2] Implement status tracking and error handling

#### Encrypted DNS

- [ ] T055 [US2] Implement `TetherFlow/Services/DNSConfigurator.swift` for DoH/DoT
- [ ] T056 [US2] Add Cloudflare and Quad9 DNS provider configurations
- [ ] T057 [US2] Wire DNS configuration into cloaking activation flow

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently (MVP complete!)

---

## Phase 5: User Story 3 - Monitoring Dashboard & Safety Controls (Priority: P2)

**Goal**: User can view real-time network status, data usage simulation, and control safety features through an intuitive dashboard.

**Independent Test**: Open dashboard, verify real-time metrics display, and test the kill-switch functionality

### Implementation for User Story 3

#### Network Metrics Collection

- [ ] T058 [P] [US3] Implement real-time bandwidth monitoring in `TetherFlow/Services/MetricsCollector.swift`
- [ ] T059 [P] [US3] Add data usage tracking (upload/download bytes)
- [ ] T060 [US3] Implement speed calculation with sampling

#### Dashboard UI

- [ ] T061 [P] [US3] Create `TetherFlow/Views/DashboardView.swift` with real-time metrics
- [ ] T062 [P] [US3] Add upload/download speed display with graphs
- [ ] T063 [P] [US3] Create data usage progress bars for hourly/daily thresholds
- [ ] T064 [P] [US3] Add session statistics (duration, total transferred)

#### Safety Thresholds

- [ ] T065 [US3] Implement threshold monitoring in `TetherFlow/Services/SafetyMonitor.swift`
- [ ] T066 [US3] Add hourly data limit checking (default: 10GB)
- [ ] T067 [US3] Add daily data limit checking (default: 50GB)
- [ ] T068 [US3] Implement alert notification system

#### Emergency Kill-Switch

- [ ] T069 [US3] Add kill-switch button to Dashboard and Menu Bar
- [ ] T070 [US3] Implement instant cloaking termination
- [ ] T071 [US3] Add network stack reset on kill-switch activation

**Checkpoint**: Dashboard displays metrics, alerts work, kill-switch functional

---

## Phase 6: User Story 4 - Zero-State Reversion (Priority: P2)

**Goal**: When disconnecting from the hotspot, the app instantly reverts all network configurations to ensure standard network performance on other networks.

**Independent Test**: Disconnect from hotspot and verify all network settings return to system defaults

### Implementation for User Story 4

#### Disconnection Detection

- [ ] T072 [US4] Enhance WiFiMonitor with disconnect detection
- [ ] T073 [US4] Implement network change handler (SSID changed → revert)

#### Reversion Logic

- [ ] T074 [US4] Implement automatic reversion on disconnect
- [ ] T075 [US4] Add reversion verification (confirm TTL/MTU restored)
- [ ] T076 [US4] Handle edge cases: sleep/wake, interface changes

#### State Cleanup

- [ ] T077 [US4] Implement session cleanup on disconnect
- [ ] T078 [US4] Add metrics persistence for completed sessions
- [ ] T079 [US4] Reset UI state on reversion

**Checkpoint**: All user stories should now be independently functional

---

## Phase 7: Advanced Features (Optional Enhancements)

### Traffic Shaping

- [ ] T080 Implement `TetherFlow/Services/TrafficShaper.swift` using pfctl
- [ ] T081 Add background traffic identification (macOS updates, iCloud)
- [ ] T082 Implement intelligent delay/shaping rules
- [ ] T083 Wire traffic shaping into cloaking activation

### Configuration Enhancements

- [ ] T084 [P] Add custom DNS provider support
- [ ] T085 [P] Add keyboard shortcuts for common actions
- [ ] T086 [P] Implement profile import/export

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

### Testing & Quality

- [ ] T087 [P] Add unit tests for all Services (target: 80% coverage)
- [ ] T088 [P] Add UI tests for critical user flows
- [ ] T089 Create integration test for full cloaking lifecycle
- [ ] T090 Add performance tests to verify <0.1% CPU usage

### Documentation

- [ ] T091 [P] Add inline documentation (Swift DocC format)
- [ ] T092 Create user manual in `docs/USER_GUIDE.md`
- [ ] T093 Add architecture diagram to `docs/ARCHITECTURE.md`
- [ ] T094 Update `README.md` with build instructions

### Performance & Security

- [ ] T095 Optimize XPC call frequency (batch operations)
- [ ] T096 Add memory usage optimization
- [ ] T097 Implement secure audit logging in helper
- [ ] T098 Add input sanitization for all user inputs

### Distribution Prep

- [ ] T099 Configure Release build settings
- [ ] T100 Add app icon and branding assets
- [ ] T101 Create notarization scripts
- [ ] T102 Test clean install on fresh macOS system

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1: Setup
    ↓
Phase 2: Foundational (BLOCKS all user stories)
    ↓
Phase 3: User Story 1 (P1) ──┐
    ↓                        │
Phase 4: User Story 2 (P1) ──┤ Can work in parallel
    ↓                        │ after Foundational
Phase 5: User Story 3 (P2) ──┤ is complete
    ↓                        │
Phase 6: User Story 4 (P2) ──┘
    ↓
Phase 7: Advanced Features
    ↓
Phase 8: Polish
```

### User Story Dependencies

| Story | Depends On | Can Start After |
|-------|-----------|-----------------|
| US1 | Phase 2 | Foundational complete |
| US2 | Phase 2, US1* | US1 recommended for context |
| US3 | Phase 2, US2* | US2 recommended |
| US4 | Phase 2, US1, US2 | US2 complete (uses cloaking) |

\* US2 could technically start after Phase 2, but US1 provides useful context

### Within Each User Story

- Models before services
- Services before UI integration
- UI integration before polish

### Parallel Opportunities

```bash
# Phase 2: Launch all model creation in parallel:
Task: "T020 [P] Implement HotspotProfile.swift"
Task: "T021 [P] Implement AppState.swift"
Task: "T022 [P] Implement NetworkMetrics.swift"
Task: "T023 [P] Implement SafetyThreshold.swift"

# Phase 3 (US1): Launch all view creation in parallel:
Task: "T032 [P] [US1] Create ProfileListView.swift"
Task: "T033 [P] [US1] Create AddProfileView.swift"
Task: "T034 [P] [US1] Create EditProfileView.swift"
```

---

## Implementation Strategy

### MVP First (User Stories 1-2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. Complete Phase 4: User Story 2
5. **STOP and VALIDATE**: Test full cloaking lifecycle
6. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo
3. Add User Story 2 → Test independently → Deploy/Demo (MVP!)
4. Add User Story 3 → Test independently → Deploy/Demo
5. Add User Story 4 → Test independently → Deploy/Demo
6. Each story adds value without breaking previous stories

---

## Task Summary

| Phase | Tasks | Focus |
|-------|-------|-------|
| Phase 1: Setup | 9 tasks | Project structure, targets, signing |
| Phase 2: Foundational | 17 tasks | XPC, C wrappers, models, persistence |
| Phase 3: US1 | 14 tasks | Wi-Fi monitoring, profile management |
| Phase 4: US2 | 16 tasks | TTL/MTU modification, cloaking engine |
| Phase 5: US3 | 14 tasks | Dashboard, metrics, kill-switch |
| Phase 6: US4 | 8 tasks | Disconnection detection, reversion |
| Phase 7: Advanced | 7 tasks | Traffic shaping, extras |
| Phase 8: Polish | 16 tasks | Testing, docs, optimization |
| **TOTAL** | **101 tasks** | |

---

## Notes

- `[P]` tasks = different files, no dependencies
- `[Story]` label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing (if TDD approach)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently

**Next Step**: Run `/speckit.implement` to begin executing tasks in order.
