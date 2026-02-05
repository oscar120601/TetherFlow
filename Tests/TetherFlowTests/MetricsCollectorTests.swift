//
//  MetricsCollectorTests.swift
//  TetherFlowTests
//
//  Unit tests for MetricsCollector
//

import XCTest
@testable import TetherFlow

final class MetricsCollectorTests: XCTestCase {
    
    var collector: MetricsCollector!
    
    override func setUp() {
        super.setUp()
        collector = MetricsCollector(interface: "en0")
    }
    
    override func tearDown() {
        Task {
            await collector?.stopCollecting()
        }
        collector = nil
        super.tearDown()
    }
    
    // MARK: - Lifecycle Tests
    
    func testStartAndStopCollecting() async {
        await collector.startCollecting()
        // No error should occur
        
        await collector.stopCollecting()
        // No error should occur
    }
    
    func testDoubleStart() async {
        await collector.startCollecting()
        await collector.startCollecting() // Should not cause issues
        
        await collector.stopCollecting()
    }
    
    func testDoubleStop() async {
        await collector.startCollecting()
        await collector.stopCollecting()
        await collector.stopCollecting() // Should not cause issues
    }
    
    // MARK: - Metrics Tests
    
    func testGetCurrentMetrics() async {
        let metrics = await collector.getCurrentMetrics()
        
        XCTAssertGreaterThanOrEqual(metrics.bytesUploaded, 0)
        XCTAssertGreaterThanOrEqual(metrics.bytesDownloaded, 0)
        XCTAssertGreaterThanOrEqual(metrics.uploadSpeed, 0)
        XCTAssertGreaterThanOrEqual(metrics.downloadSpeed, 0)
    }
    
    func testMetricsStream() async throws {
        var receivedMetrics: [MetricsCollector.MetricsSnapshot] = []
        
        let stream = await collector.metricsStream()
        
        await collector.startCollecting()
        
        // Collect a few metrics
        for await metrics in stream {
            receivedMetrics.append(metrics)
            if receivedMetrics.count >= 3 {
                break
            }
        }
        
        XCTAssertGreaterThanOrEqual(receivedMetrics.count, 3)
        
        // Verify timestamps are increasing
        for i in 1..<receivedMetrics.count {
            XCTAssertGreaterThan(receivedMetrics[i].timestamp, receivedMetrics[i-1].timestamp)
        }
    }
    
    func testReset() async {
        await collector.startCollecting()
        
        let metrics1 = await collector.getCurrentMetrics()
        
        await collector.reset()
        
        let metrics2 = await collector.getCurrentMetrics()
        
        // After reset, metrics should start from 0
        XCTAssertEqual(metrics2.bytesUploaded, 0)
        XCTAssertEqual(metrics2.bytesDownloaded, 0)
    }
    
    func testSetInterface() async {
        await collector.setInterface("en1")
        
        // Should not crash or throw
        await collector.startCollecting()
        await collector.stopCollecting()
    }
    
    // MARK: - Speed Calculation Tests
    
    func testAverageSpeeds() async {
        await collector.startCollecting()
        
        // Wait for some data collection
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        let speeds = await collector.getAverageSpeeds(overSeconds: 2)
        
        XCTAssertGreaterThanOrEqual(speeds.upload, 0)
        XCTAssertGreaterThanOrEqual(speeds.download, 0)
        
        await collector.stopCollecting()
    }
    
    func testPeakSpeeds() async {
        await collector.startCollecting()
        
        // Wait for some data collection
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let peaks = await collector.getPeakSpeeds()
        
        XCTAssertGreaterThanOrEqual(peaks.upload, 0)
        XCTAssertGreaterThanOrEqual(peaks.download, 0)
        
        await collector.stopCollecting()
    }
    
    // MARK: - Formatting Tests
    
    func testMetricsFormatting() {
        let metrics = MetricsCollector.MetricsSnapshot(
            timestamp: Date(),
            bytesUploaded: 1_500_000_000, // 1.5 GB
            bytesDownloaded: 2_500_000_000, // 2.5 GB
            uploadSpeed: 1_048_576, // 1 MB/s
            downloadSpeed: 10_485_760 // 10 MB/s
        )
        
        XCTAssertEqual(metrics.formattedUploadSpeed, "1.0 MB/s")
        XCTAssertEqual(metrics.formattedDownloadSpeed, "10.0 MB/s")
        XCTAssertEqual(metrics.formattedTotalTransferred, "4.00 GB")
        XCTAssertEqual(metrics.totalGBTransferred, 4.0, accuracy: 0.01)
    }
    
    func testEmptyMetricsFormatting() {
        let metrics = MetricsCollector.MetricsSnapshot(
            timestamp: Date(),
            bytesUploaded: 0,
            bytesDownloaded: 0,
            uploadSpeed: 0,
            downloadSpeed: 0
        )
        
        XCTAssertEqual(metrics.formattedUploadSpeed, "0.0 B/s")
        XCTAssertEqual(metrics.formattedDownloadSpeed, "0.0 B/s")
        XCTAssertEqual(metrics.formattedTotalTransferred, "0.00 GB")
    }
}
