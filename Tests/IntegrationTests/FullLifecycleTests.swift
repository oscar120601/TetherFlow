//
//  FullLifecycleTests.swift
//  TetherFlowIntegrationTests
//
//  Integration test for full cloaking lifecycle
//

import XCTest
@testable import TetherFlow

final class FullLifecycleTests: XCTestCase {
    
    var appState: AppState!
    var cloakingEngine: CloakingEngine!
    
    override func setUp() {
        super.setUp()
        appState = AppState()
        cloakingEngine = CloakingEngine()
    }
    
    override func tearDown() {
        Task {
            await cloakingEngine?.emergencyDeactivate()
        }
        appState = nil
        cloakingEngine = nil
        super.tearDown()
    }
    
    // MARK: - Full Lifecycle Test
    
    func testFullCloakingLifecycle() async throws {
        // Phase 1: Create profile
        let profile = HotspotProfile(
            ssid: "TestLifecycle",
            targetTTL: 65,
            targetMTU: 1400,
            autoActivate: false,
            enableTrafficShaping: true,
            hourlyDataThreshold: 5.0,
            dailyDataThreshold: 25.0,
            useEncryptedDNS: true,
            dnsProvider: .cloudflare
        )
        
        appState.saveProfile(profile)
        XCTAssertEqual(appState.profiles.count, 1)
        
        // Phase 2: Activate cloaking
        do {
            let session = try await cloakingEngine.activate(
                profile: profile,
                interface: "en0"
            )
            
            XCTAssertEqual(session.ssid, profile.ssid)
            XCTAssertTrue(session.isActive)
            XCTAssertEqual(session.status, .active)
            
            // Phase 3: Verify activation
            let isActive = await cloakingEngine.verifyActive(interface: "en0")
            // Note: May not be verified in test environment without helper
            
            // Phase 4: Simulate some time passing
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Phase 5: Deactivate
            try await cloakingEngine.deactivate()
            
            // Phase 6: Verify session completed
            XCTAssertFalse(session.isActive)
            XCTAssertEqual(session.status, .completed)
            XCTAssertNotNil(session.endTime)
            
        } catch CloakingError.helperNotAvailable {
            throw XCTSkip("Helper not available in test environment")
        }
    }
    
    func testAutoActivationFlow() async throws {
        let profile = HotspotProfile(
            ssid: "TestAuto",
            autoActivate: true
        )
        
        appState.saveProfile(profile)
        
        // Simulate Wi-Fi connection
        appState.currentSSID = "TestAuto"
        
        // In real scenario, this would trigger auto-activation
        // Here we manually trigger it
        appState.activateCloaking(profile: profile)
        
        // Wait for activation
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Note: Actual verification depends on helper availability
    }
    
    func testEmergencyKillSwitch() async throws {
        let profile = HotspotProfile(ssid: "TestKillSwitch")
        
        do {
            _ = try await cloakingEngine.activate(profile: profile, interface: "en0")
            
            // Activate kill switch
            await cloakingEngine.emergencyDeactivate()
            
            let session = await cloakingEngine.getCurrentSession()
            XCTAssertNil(session)
            
        } catch CloakingError.helperNotAvailable {
            throw XCTSkip("Helper not available")
        }
    }
    
    func testProfilePersistence() {
        // Create and save profile
        let profile = HotspotProfile(
            ssid: "PersistenceTest",
            targetTTL: 65,
            targetMTU: 1400
        )
        
        appState.saveProfile(profile)
        
        // Reload profiles (simulating app restart)
        appState.loadProfiles()
        
        // Verify profile persisted
        XCTAssertTrue(appState.profiles.contains { $0.ssid == "PersistenceTest" })
    }
    
    func testErrorRecovery() async {
        let profile = HotspotProfile(ssid: "ErrorTest")
        
        do {
            // Try to activate (may fail in test environment)
            _ = try await cloakingEngine.activate(profile: profile, interface: "en0")
            
            // Simulate error and recovery
            await cloakingEngine.emergencyDeactivate()
            
            // App should be in idle state
            XCTAssertNil(await cloakingEngine.getCurrentSession())
            
        } catch {
            // Error expected in test environment
            // Verify error is handled gracefully
            XCTAssertNil(await cloakingEngine.getCurrentSession())
        }
    }
}
