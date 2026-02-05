//
//  MetricsCollector.swift
//  TetherFlow
//
//  Real-time network bandwidth monitoring and metrics collection
//

import Foundation
import Network

/// Collects real-time network metrics for bandwidth monitoring
actor MetricsCollector {
    
    // MARK: - Types
    
    struct MetricsSnapshot {
        let timestamp: Date
        let bytesUploaded: UInt64
        let bytesDownloaded: UInt64
        let uploadSpeed: Double      // bytes/sec
        let downloadSpeed: Double    // bytes/sec
        
        var totalBytesTransferred: UInt64 {
            bytesUploaded + bytesDownloaded
        }
        
        var totalGBTransferred: Double {
            Double(totalBytesTransferred) / 1_000_000_000
        }
    }
    
    struct SpeedSample {
        let timestamp: Date
        let uploadSpeed: Double
        let downloadSpeed: Double
    }
    
    // MARK: - Properties
    
    private var interface: String
    private var timer: Timer?
    private var isCollecting = false
    
    // Current metrics
    private var currentBytesUploaded: UInt64 = 0
    private var currentBytesDownloaded: UInt64 = 0
    
    // Previous snapshot for speed calculation
    private var previousSnapshot: MetricsSnapshot?
    
    // Speed history for averaging
    private var speedHistory: [SpeedSample] = []
    private let maxHistorySize = 60  // Keep last 60 seconds
    
    // Published values (using continuation for async updates)
    private var metricsContinuation: AsyncStream<MetricsSnapshot>.Continuation?
    
    // MARK: - Initialization
    
    init(interface: String = "en0") {
        self.interface = interface
    }
    
    // MARK: - Public Interface
    
    /// Starts collecting metrics
    func startCollecting() {
        guard !isCollecting else { return }
        
        isCollecting = true
        Logger.info("Starting metrics collection for interface \(interface)")
        
        // Get initial baseline
        Task {
            await readInterfaceStats()
        }
        
        // Setup timer for periodic collection
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task {
                await self?.collectMetrics()
            }
        }
    }
    
    /// Stops collecting metrics
    func stopCollecting() {
        guard isCollecting else { return }
        
        isCollecting = false
        timer?.invalidate()
        timer = nil
        
        Logger.info("Stopped metrics collection")
    }
    
    /// Gets the current metrics snapshot
    func getCurrentMetrics() async -> MetricsSnapshot {
        await readInterfaceStats()
        return createSnapshot()
    }
    
    /// Returns an async stream of metrics updates
    func metricsStream() -> AsyncStream<MetricsSnapshot> {
        AsyncStream { continuation in
            self.metricsContinuation = continuation
        }
    }
    
    /// Gets average speeds over the specified time window
    func getAverageSpeeds(overSeconds seconds: Int = 5) -> (upload: Double, download: Double) {
        let cutoff = Date().addingTimeInterval(-Double(seconds))
        let recentSamples = speedHistory.filter { $0.timestamp >= cutoff }
        
        guard !recentSamples.isEmpty else {
            return (0, 0)
        }
        
        let avgUpload = recentSamples.map { $0.uploadSpeed }.reduce(0, +) / Double(recentSamples.count)
        let avgDownload = recentSamples.map { $0.downloadSpeed }.reduce(0, +) / Double(recentSamples.count)
        
        return (avgUpload, avgDownload)
    }
    
    /// Gets peak speeds from history
    func getPeakSpeeds() -> (upload: Double, download: Double) {
        let peakUpload = speedHistory.map { $0.uploadSpeed }.max() ?? 0
        let peakDownload = speedHistory.map { $0.downloadSpeed }.max() ?? 0
        return (peakUpload, peakDownload)
    }
    
    /// Resets all metrics
    func reset() {
        currentBytesUploaded = 0
        currentBytesDownloaded = 0
        previousSnapshot = nil
        speedHistory.removeAll()
        Logger.info("Metrics reset")
    }
    
    /// Changes the monitored interface
    func setInterface(_ newInterface: String) {
        guard newInterface != interface else { return }
        
        Logger.info("Switching metrics collection to interface \(newInterface)")
        
        let wasCollecting = isCollecting
        if wasCollecting {
            stopCollecting()
        }
        
        interface = newInterface
        reset()
        
        if wasCollecting {
            startCollecting()
        }
    }
    
    // MARK: - Private Methods
    
    private func collectMetrics() async {
        await readInterfaceStats()
        let snapshot = createSnapshot()
        
        // Add to speed history
        let sample = SpeedSample(
            timestamp: snapshot.timestamp,
            uploadSpeed: snapshot.uploadSpeed,
            downloadSpeed: snapshot.downloadSpeed
        )
        speedHistory.append(sample)
        
        // Trim history
        if speedHistory.count > maxHistorySize {
            speedHistory.removeFirst(speedHistory.count - maxHistorySize)
        }
        
        // Update previous snapshot
        previousSnapshot = snapshot
        
        // Notify stream
        metricsContinuation?.yield(snapshot)
        
        // Log significant changes
        if snapshot.uploadSpeed > 1_000_000 || snapshot.downloadSpeed > 1_000_000 {
            Logger.network(
                "High traffic detected - Upload: \(formatSpeed(snapshot.uploadSpeed)), Download: \(formatSpeed(snapshot.downloadSpeed))",
                level: .debug
            )
        }
    }
    
    private func readInterfaceStats() async {
        // Use netstat to get interface statistics
        let command = "netstat -ibI \(interface) | awk 'NR==2 {print $7, $10}'"
        
        let output = await executeCommand(command)
        let components = output.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        guard components.count >= 2,
              let rx = UInt64(components[0]),
              let tx = UInt64(components[1]) else {
            Logger.warning("Failed to parse interface stats for \(interface)")
            return
        }
        
        // rx = received (download), tx = transmitted (upload)
        currentBytesDownloaded = rx
        currentBytesUploaded = tx
    }
    
    private func createSnapshot() -> MetricsSnapshot {
        let now = Date()
        
        var uploadSpeed: Double = 0
        var downloadSpeed: Double = 0
        
        if let previous = previousSnapshot {
            let timeInterval = now.timeIntervalSince(previous.timestamp)
            
            if timeInterval > 0 {
                // Calculate speed in bytes/sec
                let bytesUp = Double(currentBytesUploaded) - Double(previous.bytesUploaded)
                let bytesDown = Double(currentBytesDownloaded) - Double(previous.bytesDownloaded)
                
                uploadSpeed = max(0, bytesUp / timeInterval)
                downloadSpeed = max(0, bytesDown / timeInterval)
            }
        }
        
        return MetricsSnapshot(
            timestamp: now,
            bytesUploaded: currentBytesUploaded,
            bytesDownloaded: currentBytesDownloaded,
            uploadSpeed: uploadSpeed,
            downloadSpeed: downloadSpeed
        )
    }
    
    private func executeCommand(_ command: String) async -> String {
        return await withCheckedContinuation { continuation in
            let process = Process()
            let pipe = Pipe()
            
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", command]
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                continuation.resume(returning: output.trimmingCharacters(in: .whitespacesAndNewlines))
            } catch {
                Logger.error("Failed to execute command: \(error.localizedDescription)")
                continuation.resume(returning: "")
            }
        }
    }
    
    private func formatSpeed(_ speed: Double) -> String {
        let units = ["B/s", "KB/s", "MB/s", "GB/s"]
        var speed = speed
        var unitIndex = 0
        
        while speed > 1024 && unitIndex < units.count - 1 {
            speed /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.1f %@", speed, units[unitIndex])
    }
}

// MARK: - Extensions

extension MetricsCollector.MetricsSnapshot {
    /// Formatted upload speed string
    var formattedUploadSpeed: String {
        formatSpeed(uploadSpeed)
    }
    
    /// Formatted download speed string
    var formattedDownloadSpeed: String {
        formatSpeed(downloadSpeed)
    }
    
    /// Formatted total transferred string
    var formattedTotalTransferred: String {
        String(format: "%.2f GB", totalGBTransferred)
    }
    
    private func formatSpeed(_ speed: Double) -> String {
        let units = ["B/s", "KB/s", "MB/s", "GB/s"]
        var speed = speed
        var unitIndex = 0
        
        while speed > 1024 && unitIndex < units.count - 1 {
            speed /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.1f %@", speed, units[unitIndex])
    }
}
