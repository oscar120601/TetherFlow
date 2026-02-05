//
//  CloakingSession.swift
//  TetherFlow
//
//  Tracks an active cloaking session with real-time metrics
//

import Foundation

class CloakingSession: ObservableObject, Identifiable {
    let id: UUID
    let profileId: UUID
    let ssid: String
    let interface: String
    let startTime: Date
    let appliedTTL: Int
    let appliedMTU: Int
    
    @Published var endTime: Date?
    @Published var status: SessionStatus
    @Published var metrics: NetworkMetrics
    
    private var timer: Timer?
    
    init(
        id: UUID = UUID(),
        profileId: UUID,
        ssid: String,
        interface: String,
        appliedTTL: Int,
        appliedMTU: Int,
        status: SessionStatus = .active
    ) {
        self.id = id
        self.profileId = profileId
        self.ssid = ssid
        self.interface = interface
        self.startTime = Date()
        self.appliedTTL = appliedTTL
        self.appliedMTU = appliedMTU
        self.status = status
        self.metrics = NetworkMetrics()
        
        startMetricsCollection()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Computed Properties
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    var isActive: Bool {
        status == .active
    }
    
    var formattedDuration: String {
        let interval = duration
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // MARK: - Session Control
    
    func complete() {
        status = .completed
        endTime = Date()
        timer?.invalidate()
        timer = nil
    }
    
    func fail() {
        status = .failed
        endTime = Date()
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Metrics Collection
    
    private func startMetricsCollection() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
    }
    
    private func updateMetrics() {
        // In a real implementation, this would collect actual network metrics
        // For now, we'll just simulate the update
        metrics.update()
    }
}

// MARK: - Session Status

enum SessionStatus: String, Codable {
    case activating = "activating"
    case active = "active"
    case deactivating = "deactivating"
    case completed = "completed"
    case failed = "failed"
}

// MARK: - Network Metrics

struct NetworkMetrics {
    var bytesUploaded: UInt64 = 0
    var bytesDownloaded: UInt64 = 0
    var uploadSpeed: Double = 0  // bytes/sec
    var downloadSpeed: Double = 0  // bytes/sec
    var peakUploadSpeed: Double = 0
    var peakDownloadSpeed: Double = 0
    var packetsSent: UInt64 = 0
    var packetsReceived: UInt64 = 0
    var lastUpdate: Date = Date()
    
    var totalBytesTransferred: UInt64 {
        bytesUploaded + bytesDownloaded
    }
    
    var totalGBTransferred: Double {
        Double(totalBytesTransferred) / 1_000_000_000
    }
    
    mutating func update() {
        // Placeholder for actual metrics collection
        // In real implementation, this would query network interfaces
        lastUpdate = Date()
    }
    
    func formattedSpeed(_ speed: Double) -> String {
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
