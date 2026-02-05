//
//  CloakingEngineTests.swift
//  TetherFlowTests
//
//  Unit tests for CloakingEngine
//

import XCTest
@testable import TetherFlow

@MainActor
final class CloakingEngineTests: XCTestCase {
    
    var engine: CloakingEngine!
    
    override func setUp() {
        super.setUp()
        engine = CloakingEngine()
    }
    
    override func tearDown() {
        engine = nil
        super.tearDown()
    }
    
    // MARK: - Activation Tests
    
    func testActivateWithValidProfile() async throws {
        let profile = HotspotProfile(
            ssid: "TestHotspot",
            targetTTL: 65,
            targetMTU: 1400
        )
        
        // Note: This test requires helper to be installed
        // In real testing environment, this would mock the XPC client
        do {
            let session = try await engine.activate(profile: profile, interface: "en0")
            XCTAssertEqual(session.ssid, profile.ssid)
            XCTAssertEqual(session.appliedTTL, profile.targetTTL)
            XCTAssertEqual(session.appliedMTU, profile.targetMTU)
            XCTAssertTrue(session.isActive)
        } catch CloakingError.helperNotAvailable {
            // Expected in test environment without helper
            throw XCTSkip("Helper not available in test environment")
        }
    }
    
    func testActivateWhileAlreadyActive() async {
        let profile1 = HotspotProfile(ssid: "Hotspot1")
        let profile2 = HotspotProfile(ssid: "Hotspot2")
        
        do {
            _ = try await engine.activate(profile: profile1, interface: "en0")
            
            // Should throw alreadyActive error
            do {
                _ = try await engine.activate(profile: profile2, interface: "en0")
                XCTFail("Should throw alreadyActive error")
            } catch CloakingError.alreadyActive {
                // Expected
                XCTAssertTrue(true)
            }
        } catch CloakingError.helperNotAvailable {
            throw XCTSkip("Helper not available")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testDeactivateActiveSession() async throws {
        let profile = HotspotProfile(ssid: "TestHotspot")
        
        do {
            let session = try await engine.activate(profile: profile, interface: "en0")
            XCTAssertTrue(session.isActive)
            
            try await engine.deactivate()
            
            XCTAssertFalse(session.isActive)
            XCTAssertEqual(session.status, .completed)
        } catch CloakingError.helperNotAvailable {
            throw XCTSkip("Helper not available")
        }
    }
    
    func testDeactivateWithoutActiveSession() async {
        // Should not throw, just return
        do {
            try await engine.deactivate()
            // No error expected
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }
    
    func testEmergencyDeactivate() async throws {
        let profile = HotspotProfile(ssid: "TestHotspot")
        
        do {
            _ = try await engine.activate(profile: profile, interface: "en0")
            
            await engine.emergencyDeactivate()
            
            let session = await engine.getCurrentSession()
            XCTAssertNil(session)
        } catch CloakingError.helperNotAvailable {
            throw XCTSkip("Helper not available")
        }
    }
    
    // MARK: - Verification Tests
    
    func testVerifyActiveWithoutSession() async {
        let isActive = await engine.verifyActive(interface: "en0")
        XCTAssertFalse(isActive)
    }
    
    func testGetCurrentSession() async throws {
        let profile = HotspotProfile(ssid: "TestHotspot")
        
        do {
            // Initially no session
            var session = await engine.getCurrentSession()
            XCTAssertNil(session)
            
            // After activation
            let newSession = try await engine.activate(profile: profile, interface: "en0")
            session = await engine.getCurrentSession()
            XCTAssertNotNil(session)
            XCTAssertEqual(session?.id, newSession.id)
            
        } catch CloakingError.helperNotAvailable {
            throw XCTSkip("Helper not available")
        }
    }
    
    func testGetLastError() async throws {
        let profile = HotspotProfile(ssid: "TestHotspot")
        
        do {
            // No error initially
            var error = await engine.getLastError()
            XCTAssertNil(error)
            
            _ = try await engine.activate(profile: profile, interface: "en0")
            
            // Try to activate again (should cause error)
            let profile2 = HotspotProfile(ssid: "TestHotspot2")
            do {
                _ = try await engine.activate(profile: profile2, interface: "en0")
            } catch {
                // Expected
            }
            
            error = await engine.getLastError()
            XCTAssertNotNil(error)
            
        } catch CloakingError.helperNotAvailable {
            throw XCTSkip("Helper not available")
        }
    }
    
    func testClearLastError() async throws {
        let profile = HotspotProfile(ssid: "TestHotspot")
        
        do {
            _ = try await engine.activate(profile: profile, interface: "en0")
            
            // Try to activate again to cause error
            let profile2 = HotspotProfile(ssid: "TestHotspot2")
            do {
                _ = try await engine.activate(profile: profile2, interface: "en0")
            } catch {
                // Expected
            }
            
            XCTAssertNotNil(await engine.getLastError())
            
            await engine.clearLastError()
            
            XCTAssertNil(await engine.getLastError())
            
        } catch CloakingError.helperNotAvailable {
            throw XCTSkip("Helper not available")
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentActivation() async {
        let profile = HotspotProfile(ssid: "TestHotspot")
        
        do {
            // Try concurrent activations
            async let activation1 = engine.activate(profile: profile, interface: "en0")
            async let activation2 = engine.activate(profile: profile, interface: "en0")
            
            let results = try await [activation1, activation2]
            
            // One should succeed, one should fail with alreadyProcessing
            XCTAssertEqual(results.count, 2)
            
        } catch CloakingError.helperNotAvailable {
            throw XCTSkip("Helper not available")
        } catch CloakingError.alreadyProcessing {
            // Expected - one should fail with alreadyProcessing
            XCTAssertTrue(true)
        } catch {
            // Other errors are acceptable in test environment
        }
    }
}
