//
//  HotspotProfileTests.swift
//  TetherFlowTests
//
//  Unit tests for HotspotProfile model
//

import XCTest
@testable import TetherFlow

final class HotspotProfileTests: XCTestCase {
    
    // MARK: - Validation Tests
    
    func testValidProfile() {
        let profile = HotspotProfile(
            ssid: "MyHotspot",
            targetTTL: 65,
            targetMTU: 1400
        )
        
        XCTAssertTrue(profile.isValid)
        XCTAssertTrue(profile.validationErrors.isEmpty)
    }
    
    func testEmptySSIDValidation() {
        let profile = HotspotProfile(ssid: "")
        
        XCTAssertFalse(profile.isValid)
        XCTAssertTrue(profile.validationErrors.contains("SSID cannot be empty"))
    }
    
    func testLongSSIDValidation() {
        let profile = HotspotProfile(ssid: String(repeating: "a", count: 33))
        
        XCTAssertFalse(profile.isValid)
        XCTAssertTrue(profile.validationErrors.contains("SSID must be 32 characters or less"))
    }
    
    func testInvalidTTLValidation() {
        let profile1 = HotspotProfile(ssid: "Test", targetTTL: 63)
        let profile2 = HotspotProfile(ssid: "Test", targetTTL: 256)
        
        XCTAssertFalse(profile1.isValid)
        XCTAssertFalse(profile2.isValid)
    }
    
    func testInvalidMTUValidation() {
        let profile1 = HotspotProfile(ssid: "Test", targetMTU: 1279)
        let profile2 = HotspotProfile(ssid: "Test", targetMTU: 1501)
        
        XCTAssertFalse(profile1.isValid)
        XCTAssertFalse(profile2.isValid)
    }
    
    func testDefaultValues() {
        let profile = HotspotProfile(ssid: "TestHotspot")
        
        XCTAssertEqual(profile.targetTTL, 65)
        XCTAssertEqual(profile.targetMTU, 1400)
        XCTAssertTrue(profile.autoActivate)
        XCTAssertTrue(profile.enableTrafficShaping)
        XCTAssertEqual(profile.hourlyDataThreshold, 10.0)
        XCTAssertEqual(profile.dailyDataThreshold, 50.0)
        XCTAssertTrue(profile.useEncryptedDNS)
        XCTAssertEqual(profile.dnsProvider, .cloudflare)
    }
    
    // MARK: - Codable Tests
    
    func testProfileEncoding() throws {
        let profile = HotspotProfile.sample
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(profile)
        
        XCTAssertFalse(data.isEmpty)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HotspotProfile.self, from: data)
        
        XCTAssertEqual(profile.id, decoded.id)
        XCTAssertEqual(profile.ssid, decoded.ssid)
        XCTAssertEqual(profile.targetTTL, decoded.targetTTL)
    }
}
