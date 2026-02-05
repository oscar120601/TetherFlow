//
//  SafetyThreshold.swift
//  TetherFlow
//
//  Tracks threshold compliance and alert states for data usage
//

import Foundation

/// Tracks data usage thresholds and alert states for a cloaking session
class SafetyThreshold: ObservableObject, Identifiable {
    let id: UUID
    let profileId: UUID
    let sessionId: UUID
    
    // MARK: - Threshold Configuration
    
    @Published var hourlyLimitGB: Double
    @Published var dailyLimitGB: Double
    
    // MARK: - Current Usage
    
    @Published var hourlyUsageGB: Double = 0.0
    @Published var dailyUsageGB: Double = 0.0
    
    // MARK: - Alert State
    
    @Published var hourlyAlertTriggered: Bool = false
    @Published var dailyAlertTriggered: Bool = false
    
    // MARK: - Reset Tracking
    
    private var lastResetHour: Date
    private var lastResetDay: Date
    private let calendar = Calendar.current
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        profileId: UUID,
        sessionId: UUID,
        hourlyLimitGB: Double = 10.0,
        dailyLimitGB: Double = 50.0
    ) {
        self.id = id
        self.profileId = profileId
        self.sessionId = sessionId
        self.hourlyLimitGB = hourlyLimitGB
        self.dailyLimitGB = dailyLimitGB
        self.lastResetHour = Date()
        self.lastResetDay = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Returns the current risk level based on usage
    var riskLevel: RiskLevel {
        if dailyUsageGB >= dailyLimitGB {
            return .critical
        }
        if hourlyUsageGB >= hourlyLimitGB {
            return .high
        }
        if hourlyUsageGB >= hourlyLimitGB * 0.8 || dailyUsageGB >= dailyLimitGB * 0.8 {
            return .medium
        }
        return .low
    }
    
    /// Whether an hourly alert should be triggered
    var shouldTriggerHourlyAlert: Bool {
        hourlyUsageGB >= hourlyLimitGB && !hourlyAlertTriggered
    }
    
    /// Whether a daily alert should be triggered
    var shouldTriggerDailyAlert: Bool {
        dailyUsageGB >= dailyLimitGB && !dailyAlertTriggered
    }
    
    /// Percentage of hourly limit used (0.0 - 1.0+)
    var hourlyUsagePercentage: Double {
        min(hourlyUsageGB / hourlyLimitGB, 1.0)
    }
    
    /// Percentage of daily limit used (0.0 - 1.0+)
    var dailyUsagePercentage: Double {
        min(dailyUsageGB / dailyLimitGB, 1.0)
    }
    
    /// Formatted hourly usage string
    var formattedHourlyUsage: String {
        String(format: "%.2f GB / %.0f GB", hourlyUsageGB, hourlyLimitGB)
    }
    
    /// Formatted daily usage string
    var formattedDailyUsage: String {
        String(format: "%.2f GB / %.0f GB", dailyUsageGB, dailyLimitGB)
    }
    
    // MARK: - Usage Tracking
    
    /// Records data usage and checks for threshold crossings
    /// - Parameters:
    ///   - bytesUploaded: Bytes uploaded since last update
    ///   - bytesDownloaded: Bytes downloaded since last update
    /// - Returns: Any alerts that should be triggered
    func recordUsage(bytesUploaded: UInt64, bytesDownloaded: UInt64) -> [ThresholdAlert] {
        // Check if we need to reset counters
        checkAndResetCounters()
        
        // Convert bytes to GB
        let gbUploaded = Double(bytesUploaded) / 1_000_000_000
        let gbDownloaded = Double(bytesDownloaded) / 1_000_000_000
        let totalGB = gbUploaded + gbDownloaded
        
        // Update usage
        hourlyUsageGB += totalGB
        dailyUsageGB += totalGB
        
        // Check for alerts
        var alerts: [ThresholdAlert] = []
        
        if shouldTriggerHourlyAlert {
            hourlyAlertTriggered = true
            alerts.append(.hourlyLimitExceeded(usage: hourlyUsageGB, limit: hourlyLimitGB))
            Logger.warning("Hourly data limit exceeded: \(formattedHourlyUsage)")
        }
        
        if shouldTriggerDailyAlert {
            dailyAlertTriggered = true
            alerts.append(.dailyLimitExceeded(usage: dailyUsageGB, limit: dailyLimitGB))
            Logger.warning("Daily data limit exceeded: \(formattedDailyUsage)")
        }
        
        // Log high usage even if not at limit
        if riskLevel == .high && alerts.isEmpty {
            Logger.info("High data usage detected: \(formattedHourlyUsage) hourly, \(formattedDailyUsage) daily")
        }
        
        return alerts
    }
    
    /// Resets the hourly counter
    func resetHourlyCounter() {
        hourlyUsageGB = 0.0
        hourlyAlertTriggered = false
        lastResetHour = Date()
        Logger.info("Hourly usage counter reset")
    }
    
    /// Resets the daily counter
    func resetDailyCounter() {
        dailyUsageGB = 0.0
        dailyAlertTriggered = false
        lastResetDay = Date()
        Logger.info("Daily usage counter reset")
    }
    
    /// Resets all counters and alerts
    func resetAll() {
        resetHourlyCounter()
        resetDailyCounter()
    }
    
    // MARK: - Private Methods
    
    private func checkAndResetCounters() {
        let now = Date()
        
        // Check if hour has changed
        if !calendar.isDate(now, equalTo: lastResetHour, toGranularity: .hour) {
            resetHourlyCounter()
        }
        
        // Check if day has changed
        if !calendar.isDate(now, equalTo: lastResetDay, toGranularity: .day) {
            resetDailyCounter()
        }
    }
}

// MARK: - Supporting Types

/// Risk levels for data usage
enum RiskLevel: String, Codable, CaseIterable {
    case low = "low"           // Green - Under 80%
    case medium = "medium"     // Yellow - 80-100%
    case high = "high"         // Orange - Hourly limit exceeded
    case critical = "critical" // Red - Daily limit exceeded
    
    var displayName: String {
        switch self {
        case .low: return "Low Risk"
        case .medium: return "Medium Risk"
        case .high: return "High Risk"
        case .critical: return "Critical Risk"
        }
    }
    
    var colorName: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

/// Alerts triggered by threshold violations
enum ThresholdAlert: Equatable {
    case hourlyLimitExceeded(usage: Double, limit: Double)
    case dailyLimitExceeded(usage: Double, limit: Double)
    
    var title: String {
        switch self {
        case .hourlyLimitExceeded:
            return "Hourly Data Limit Exceeded"
        case .dailyLimitExceeded:
            return "Daily Data Limit Exceeded"
        }
    }
    
    var message: String {
        switch self {
        case .hourlyLimitExceeded(let usage, let limit):
            return String(format: "You have used %.2f GB out of your hourly limit of %.0f GB. Consider using the kill-switch to prevent overage charges.", usage, limit)
        case .dailyLimitExceeded(let usage, let limit):
            return String(format: "You have used %.2f GB out of your daily limit of %.0f GB. Strongly recommend disconnecting to avoid throttling or charges.", usage, limit)
        }
    }
    
    var isCritical: Bool {
        switch self {
        case .hourlyLimitExceeded:
            return false
        case .dailyLimitExceeded:
            return true
        }
    }
}

// MARK: - Codable Conformance

extension SafetyThreshold: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case profileId
        case sessionId
        case hourlyLimitGB
        case dailyLimitGB
        case hourlyUsageGB
        case dailyUsageGB
        case hourlyAlertTriggered
        case dailyAlertTriggered
        case lastResetHour
        case lastResetDay
    }
}
