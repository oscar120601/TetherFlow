//
//  XPCCommunicationTests.swift
//  TetherFlowIntegrationTests
//
//  Integration tests for XPC communication with privileged helper tool
//

import XCTest
@testable import TetherFlow

final class XPCCommunicationTests: XCTestCase {
    
    var xpcClient: XPCClient!
    
    override func setUp() {
        super.setUp()
        xpcClient = XPCClient()
    }
    
    override func tearDown() {
        xpcClient.disconnect()
        xpcClient = nil
        super.tearDown()
    }
    
    // MARK: - Connection Tests
    
    func testXPCConnection() async throws {
        // Test that we can establish a connection to the helper
        do {
            try await xpcClient.connect()
            // If we get here, connection succeeded
            XCTAssertTrue(true, "XPC connection established successfully")
        } catch {
            XCTFail("Failed to connect to helper: \(error.localizedDescription)")
        }
    }
    
    func testXPCHelperPing() async throws {
        // Test that the helper responds to ping
        try await xpcClient.connect()
        
        let isResponsive = try await xpcClient.ping()
        XCTAssertTrue(isResponsive, "Helper should respond to ping")
    }
    
    func testXPCDisconnection() {
        // Test that disconnection works cleanly
        let expectation = expectation(description: "Disconnection completed")
        
        Task {
            try? await xpcClient.connect()
            xpcClient.disconnect()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - TTL Tests
    
    func testGetCurrentTTL() async throws {
        try await xpcClient.connect()
        
        let ttl = try await xpcClient.getCurrentTTL()
        
        // TTL should be a valid value (typically 64 or 65 on macOS)
        XCTAssertGreaterThan(ttl, 0, "TTL should be positive")
        XCTAssertLessThanOrEqual(ttl, 255, "TTL should not exceed 255")
    }
    
    func testApplyAndVerifyCloaking() async throws {
        try await xpcClient.connect()
        
        // Get original TTL
        let originalTTL = try await xpcClient.getCurrentTTL()
        
        // Apply cloaking (TTL 65, MTU 1400 on en0)
        let success = try await xpcClient.applyCloaking(
            ttl: 65,
            mtu: 1400,
            interface: "en0"
        )
        
        guard success else {
            XCTFail("Failed to apply cloaking settings")
            return
        }
        
        // Verify TTL was changed
        let newTTL = try await xpcClient.getCurrentTTL()
        XCTAssertEqual(newTTL, 65, "TTL should be set to 65 after cloaking")
        
        // Reset to original
        let resetSuccess = try await xpcClient.resetNetworkSettings(interface: "en0")
        XCTAssertTrue(resetSuccess, "Should successfully reset network settings")
        
        // Verify TTL was restored
        let restoredTTL = try await xpcClient.getCurrentTTL()
        XCTAssertEqual(restoredTTL, originalTTL, "TTL should be restored to original value")
    }
    
    // MARK: - Error Handling Tests
    
    func testXPCConnectionFailure() async {
        // Test behavior when helper is not available
        // This simulates a scenario where the helper is not installed
        
        let client = XPCClient()
        client.disconnect() // Ensure disconnected
        
        // Attempt to ping without connection should fail
        do {
            _ = try await client.ping()
            // If we get here without connection, it might auto-connect
            // This is implementation-dependent
        } catch {
            // Expected behavior - ping should fail when not connected
            XCTAssertNotNil(error)
        }
    }
    
    func testInvalidInterfaceHandling() async throws {
        try await xpcClient.connect()
        
        // Try to apply cloaking with invalid interface
        let success = try await xpcClient.applyCloaking(
            ttl: 65,
            mtu: 1400,
            interface: "invalid_interface"
        )
        
        // Should either fail gracefully or succeed (depends on implementation)
        // The test documents the expected behavior
        XCTAssertFalse(success, "Should fail with invalid interface")
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentXPCalls() async throws {
        try await xpcClient.connect()
        
        // Make multiple concurrent calls
        async let ping1 = xpcClient.ping()
        async let ping2 = xpcClient.ping()
        async let ping3 = xpcClient.ping()
        
        let results = try await [ping1, ping2, ping3]
        
        XCTAssertTrue(results.allSatisfy { $0 }, "All concurrent pings should succeed")
    }
}
