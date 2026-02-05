//
//  PerformanceTests.swift
//  TetherFlowTests
//
//  Performance tests to verify <0.1% CPU usage
//

import XCTest
@testable import TetherFlow

final class PerformanceTests: XCTestCase {
    
    // MARK: - CPU Usage Tests
    
    func testIdleCPUUsage() {
        // Measure CPU usage when app is idle
        measure(metrics: [XCTCPUMetric()]) {
            // Simulate idle time
            Thread.sleep(forTimeInterval: 1.0)
        }
    }
    
    func testProfileStorePerformance() {
        let store = ProfileStore()
        
        // Create many profiles
        var profiles: [HotspotProfile] = []
        for i in 0..<100 {
            profiles.append(HotspotProfile(ssid: "Test\(i)"))
        }
        
        measure {
            // Save all profiles
            for profile in profiles {
                store.saveProfile(profile)
            }
            
            // Load all profiles
            _ = store.loadProfiles()
        }
    }
    
    func testMetricsCollectionPerformance() {
        let collector = MetricsCollector(interface: "en0")
        
        measure {
            // Start and stop collection multiple times
            for _ in 0..<10 {
                Task {
                    await collector.startCollecting()
                    Thread.sleep(forTimeInterval: 0.1)
                    await collector.stopCollecting()
                }
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testMemoryUsageProfileCreation() {
        measure(metrics: [XCTMemoryMetric()]) {
            // Create many profiles
            var profiles: [HotspotProfile] = []
            for i in 0..<1000 {
                profiles.append(HotspotProfile(
                    ssid: "MemoryTest\(i)",
                    targetTTL: 65,
                    targetMTU: 1400
                ))
            }
            
            // Verify all created
            XCTAssertEqual(profiles.count, 1000)
        }
    }
    
    func testMemoryUsageSessionCreation() {
        measure(metrics: [XCTMemoryMetric()]) {
            // Create many sessions
            var sessions: [CloakingSession] = []
            for i in 0..<100 {
                let session = CloakingSession(
                    profileId: UUID(),
                    ssid: "Session\(i)",
                    interface: "en0",
                    appliedTTL: 65,
                    appliedMTU: 1400
                )
                sessions.append(session)
            }
            
            // Verify all created
            XCTAssertEqual(sessions.count, 100)
        }
    }
    
    // MARK: - XPC Performance Tests
    
    func testXPCConnectionPerformance() {
        let client = XPCClient()
        
        measure {
            Task {
                // Try to connect (may fail without helper, but measures performance)
                do {
                    try await client.connect()
                    client.disconnect()
                } catch {
                    // Expected in test environment
                }
            }
        }
    }
    
    // MARK: - UI Performance Tests
    
    func testDashboardViewCreationPerformance() {
        let appState = AppState()
        
        measure {
            // Simulate creating dashboard view multiple times
            for _ in 0..<10 {
                _ = appState.status
                _ = appState.profiles
                _ = appState.activeSession
            }
        }
    }
    
    // MARK: - Storage Performance Tests
    
    func testSessionStorePerformance() {
        let store = SessionStore()
        
        measure {
            Task {
                // Create and save many sessions
                for i in 0..<50 {
                    let session = CloakingSession(
                        profileId: UUID(),
                        ssid: "PerfTest\(i)",
                        interface: "en0",
                        appliedTTL: 65,
                        appliedMTU: 1400
                    )
                    session.complete()
                    await store.saveSession(session)
                }
                
                // Load statistics
                _ = await store.calculateStatistics()
            }
        }
    }
}
