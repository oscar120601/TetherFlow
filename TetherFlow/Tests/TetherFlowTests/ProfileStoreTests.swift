//
//  ProfileStoreTests.swift
//  TetherFlowTests
//
//  Unit tests for ProfileStore persistence
//

import XCTest
@testable import TetherFlow

final class ProfileStoreTests: XCTestCase {
    
    var store: ProfileStore!
    
    override func setUp() {
        super.setUp()
        store = ProfileStore()
        
        // Clear any existing test data
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "com.tetherflow.profiles")
    }
    
    override func tearDown() {
        // Clean up after tests
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "com.tetherflow.profiles")
        store = nil
        super.tearDown()
    }
    
    // MARK: - CRUD Tests
    
    func testSaveAndLoadProfile() {
        let profile = HotspotProfile(ssid: "TestHotspot")
        
        store.saveProfile(profile)
        let loaded = store.loadProfiles()
        
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.ssid, "TestHotspot")
    }
    
    func testUpdateExistingProfile() {
        let profile = HotspotProfile(ssid: "TestHotspot", targetTTL: 65)
        store.saveProfile(profile)
        
        var updated = profile
        updated.targetTTL = 64
        store.saveProfile(updated)
        
        let loaded = store.loadProfiles()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.targetTTL, 64)
    }
    
    func testDeleteProfile() {
        let profile1 = HotspotProfile(ssid: "Hotspot1")
        let profile2 = HotspotProfile(ssid: "Hotspot2")
        
        store.saveProfile(profile1)
        store.saveProfile(profile2)
        
        XCTAssertEqual(store.loadProfiles().count, 2)
        
        store.deleteProfile(profile1)
        
        let loaded = store.loadProfiles()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.ssid, "Hotspot2")
    }
    
    func testGetProfileByID() {
        let profile = HotspotProfile(ssid: "TestHotspot")
        store.saveProfile(profile)
        
        let found = store.getProfile(byID: profile.id)
        
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.ssid, "TestHotspot")
    }
    
    func testGetProfileBySSID() {
        let profile = HotspotProfile(ssid: "MyWiFi")
        store.saveProfile(profile)
        
        let found = store.getProfile(bySSID: "MyWiFi")
        
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, profile.id)
    }
    
    // MARK: - Validation Tests
    
    func testDuplicateSSIDDetection() {
        let profile1 = HotspotProfile(ssid: "TestHotspot")
        store.saveProfile(profile1)
        
        let profile2 = HotspotProfile(ssid: "TestHotspot")
        
        XCTAssertTrue(store.isDuplicateSSID("TestHotspot"))
        XCTAssertTrue(store.isDuplicateSSID("TestHotspot", excluding: profile2.id))
        XCTAssertFalse(store.isDuplicateSSID("TestHotspot", excluding: profile1.id))
    }
    
    func testNoDuplicatesForDifferentSSIDs() {
        let profile = HotspotProfile(ssid: "TestHotspot")
        store.saveProfile(profile)
        
        XCTAssertFalse(store.isDuplicateSSID("DifferentHotspot"))
    }
}
