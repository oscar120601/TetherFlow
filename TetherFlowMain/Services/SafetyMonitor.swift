//
//  SafetyMonitor.swift
//  TetherFlow
//
//  Monitors data usage thresholds and triggers alerts
//

import Foundation
import UserNotifications

/// Monitors safety thresholds and manages alert notifications
actor SafetyMonitor {
    
    // MARK: - Types
    
    enum AlertType: String, CaseIterable {
        case hourlyWarning = "hourly_warning"
        case hourlyLimit = "hourly_limit"
        case dailyWarning = "daily_warning"
        case dailyLimit = "daily_limit"
        
        var title: String {
            switch self {
            case .hourlyWarning: return "Hourly Data Warning"
            case .hourlyLimit: return "Hourly Limit Exceeded"
            case .dailyWarning: return "Daily Data Warning"
            case .dailyLimit: return "Daily Limit Exceeded"
            }
        }
        
        var body: String {
            switch self {
            case .hourlyWarning:
                return "You've used 80% of your hourly data limit. Consider slowing down."
            case .hourlyLimit:
                return "You've exceeded your hourly data limit. The kill switch is recommended."
            case .dailyWarning:
                return "You've used 80% of your daily data limit. Monitor your usage closely."
            case .dailyLimit:
                return "You've exceeded your daily data limit. Consider disconnecting."
            }
        }
        
        var priority: UNNotificationPriority {
            switch self {
            case .hourlyWarning, .dailyWarning:
                return .default
            case .hourlyLimit, .dailyLimit:
                return .high
            }
        }
    }
    
    struct ThresholdStatus {
        let hourlyUsageGB: Double
        let hourlyLimitGB: Double
        let dailyUsageGB: Double
        let dailyLimitGB: Double
        let hourlyPercentage: Double
        let dailyPercentage: Double
        let riskLevel: RiskLevel
        let shouldTriggerAlerts: [AlertType]
    }
    
    // MARK: - Properties
    
    private var profile: HotspotProfile?
    private var sessionStartTime: Date?
    
    // Usage tracking
    private var hourlyStartTime: Date
    private var dailyStartTime: Date
    private var hourlyUsageGB: Double = 0
    private var dailyUsageGB: Double = 0
    
    // Alert state (to prevent duplicate alerts)
    private var triggeredAlerts: Set<AlertType> = []
    
    // Callbacks
    var onAlert: ((AlertType) -> Void)?
    var onRiskLevelChange: ((RiskLevel) -> Void)?
    
    // MARK: - Initialization
    
    init() {
        let now = Date()
        self.hourlyStartTime = now
        self.dailyStartTime = now
        
        setupNotifications()
    }
    
    // MARK: - Public Interface
    
    /// Starts monitoring for a new session
    func startMonitoring(profile: HotspotProfile) {
        self.profile = profile
        self.sessionStartTime = Date()
        
        // Reset counters
        let now = Date()
        hourlyStartTime = now
        dailyStartTime = now
        hourlyUsageGB = 0
        dailyUsageGB = 0
        triggeredAlerts.removeAll()
        
        Logger.info("Safety monitoring started for \(profile.ssid)")
        Logger.info("Thresholds - Hourly: \(profile.hourlyDataThreshold) GB, Daily: \(profile.dailyDataThreshold) GB")
    }
    
    /// Stops monitoring
    func stopMonitoring() {
        profile = nil
        sessionStartTime = nil
        triggeredAlerts.removeAll()
        
        Logger.info("Safety monitoring stopped")
    }
    
    /// Records data usage and checks thresholds
    /// - Parameters:
    ///   - bytesUploaded: Bytes uploaded since last update
    ///   - bytesDownloaded: Bytes downloaded since last update
    /// - Returns: Threshold status and any alerts to trigger
    func recordUsage(bytesUploaded: UInt64, bytesDownloaded: UInt64) -> ThresholdStatus {
        checkAndResetCounters()
        
        // Convert to GB
        let gbUploaded = Double(bytesUploaded) / 1_000_000_000
        let gbDownloaded = Double(bytesDownloaded) / 1_000_000_000
        let totalGB = gbUploaded + gbDownloaded
        
        // Update usage
        hourlyUsageGB += totalGB
        dailyUsageGB += totalGB
        
        // Calculate status
        let status = calculateStatus()
        
        // Trigger alerts
        for alert in status.shouldTriggerAlerts {
            triggerAlert(alert)
        }
        
        return status
    }
    
    /// Gets current threshold status without recording usage
    func getCurrentStatus() -> ThresholdStatus {
        checkAndResetCounters()
        return calculateStatus()
    }
    
    /// Manually resets hourly counter
    func resetHourlyCounter() {
        hourlyUsageGB = 0
        hourlyStartTime = Date()
        triggeredAlerts.removeAll { alert in
            alert == .hourlyWarning || alert == .hourlyLimit
        }
        
        Logger.info("Hourly counter reset")
    }
    
    /// Manually resets daily counter
    func resetDailyCounter() {
        dailyUsageGB = 0
        dailyStartTime = Date()
        triggeredAlerts.removeAll { alert in
            alert == .dailyWarning || alert == .dailyLimit
        }
        
        Logger.info("Daily counter reset")
    }
    
    /// Gets current usage statistics
    func getUsageStats() -> (hourly: Double, daily: Double, session: Double?) {
        checkAndResetCounters()
        
        let sessionUsage: Double?
        if let startTime = sessionStartTime {
            sessionUsage = hourlyUsageGB  // Approximation for session
        } else {
            sessionUsage = nil
        }
        
        return (hourlyUsageGB, dailyUsageGB, sessionUsage)
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                Logger.info("Notification permission granted")
            } else if let error = error {
                Logger.error("Failed to request notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    private func checkAndResetCounters() {
        let now = Date()
        let calendar = Calendar.current
        
        // Check if hour has changed
        if !calendar.isDate(now, equalTo: hourlyStartTime, toGranularity: .hour) {
            hourlyUsageGB = 0
            hourlyStartTime = now
            triggeredAlerts.remove(.hourlyWarning)
            triggeredAlerts.remove(.hourlyLimit)
            Logger.info("Hourly counter auto-reset")
        }
        
        // Check if day has changed
        if !calendar.isDate(now, equalTo: dailyStartTime, toGranularity: .day) {
            dailyUsageGB = 0
            dailyStartTime = now
            triggeredAlerts.remove(.dailyWarning)
            triggeredAlerts.remove(.dailyLimit)
            Logger.info("Daily counter auto-reset")
        }
    }
    
    private func calculateStatus() -> ThresholdStatus {
        guard let profile = profile else {
            return ThresholdStatus(
                hourlyUsageGB: 0,
                hourlyLimitGB: 0,
                dailyUsageGB: 0,
                dailyLimitGB: 0,
                hourlyPercentage: 0,
                dailyPercentage: 0,
                riskLevel: .low,
                shouldTriggerAlerts: []
            )
        }
        
        let hourlyPercentage = hourlyUsageGB / profile.hourlyDataThreshold
        let dailyPercentage = dailyUsageGB / profile.dailyDataThreshold
        
        // Determine risk level
        let riskLevel: RiskLevel
        if dailyPercentage >= 1.0 {
            riskLevel = .critical
        } else if hourlyPercentage >= 1.0 {
            riskLevel = .high
        } else if hourlyPercentage >= 0.8 || dailyPercentage >= 0.8 {
            riskLevel = .medium
        } else {
            riskLevel = .low
        }
        
        // Determine alerts to trigger
        var alerts: [AlertType] = []
        
        // Hourly alerts
        if hourlyPercentage >= 0.8 && hourlyPercentage < 1.0 && !triggeredAlerts.contains(.hourlyWarning) {
            alerts.append(.hourlyWarning)
        }
        if hourlyPercentage >= 1.0 && !triggeredAlerts.contains(.hourlyLimit) {
            alerts.append(.hourlyLimit)
        }
        
        // Daily alerts
        if dailyPercentage >= 0.8 && dailyPercentage < 1.0 && !triggeredAlerts.contains(.dailyWarning) {
            alerts.append(.dailyWarning)
        }
        if dailyPercentage >= 1.0 && !triggeredAlerts.contains(.dailyLimit) {
            alerts.append(.dailyLimit)
        }
        
        return ThresholdStatus(
            hourlyUsageGB: hourlyUsageGB,
            hourlyLimitGB: profile.hourlyDataThreshold,
            dailyUsageGB: dailyUsageGB,
            dailyLimitGB: profile.dailyDataThreshold,
            hourlyPercentage: hourlyPercentage,
            dailyPercentage: dailyPercentage,
            riskLevel: riskLevel,
            shouldTriggerAlerts: alerts
        )
    }
    
    private func triggerAlert(_ alert: AlertType) {
        // Mark as triggered
        triggeredAlerts.insert(alert)
        
        // Log
        Logger.warning("Safety alert triggered: \(alert.rawValue)")
        
        // Callback
        Task { @MainActor in
            self.onAlert?(alert)
        }
        
        // Show notification
        showNotification(for: alert)
        
        // Notify risk level change
        let status = calculateStatus()
        Task { @MainActor in
            self.onRiskLevelChange?(status.riskLevel)
        }
    }
    
    private func showNotification(for alert: AlertType) {
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.body
        content.sound = .default
        
        // Set interruption level for critical alerts
        if alert == .hourlyLimit || alert == .dailyLimit {
            if #available(macOS 12.0, *) {
                content.interruptionLevel = .timeSensitive
            }
        }
        
        let request = UNNotificationRequest(
            identifier: "\(alert.rawValue)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.error("Failed to show notification: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Extensions

extension SafetyMonitor.ThresholdStatus {
    /// Formatted hourly usage string
    var formattedHourlyUsage: String {
        String(format: "%.2f GB / %.0f GB", hourlyUsageGB, hourlyLimitGB)
    }
    
    /// Formatted daily usage string
    var formattedDailyUsage: String {
        String(format: "%.2f GB / %.0f GB", dailyUsageGB, dailyLimitGB)
    }
    
    /// Whether any limit has been exceeded
    var hasExceededLimit: Bool {
        hourlyPercentage >= 1.0 || dailyPercentage >= 1.0
    }
    
    /// Whether approaching any limit (80% or more)
    var isApproachingLimit: Bool {
        (hourlyPercentage >= 0.8 && hourlyPercentage < 1.0) ||
        (dailyPercentage >= 0.8 && dailyPercentage < 1.0)
    }
}
