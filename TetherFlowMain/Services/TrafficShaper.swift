//
//  TrafficShaper.swift
//  TetherFlow
//
//  Intelligent traffic shaping using macOS Packet Filter (pfctl)
//

import Foundation

/// Manages intelligent traffic shaping to delay background traffic
actor TrafficShaper {
    
    // MARK: - Types
    
    enum TrafficType: String, CaseIterable {
        case macOSUpdates = "macos_updates"
        case iCloudSync = "icloud_sync"
        case appStore = "appstore_downloads"
        case timeMachine = "timemachine"
        case softwareUpdate = "software_update"
        case backgroundDownload = "background_download"
        
        var displayName: String {
            switch self {
            case .macOSUpdates: return "macOS Updates"
            case .iCloudSync: return "iCloud Sync"
            case .appStore: return "App Store Downloads"
            case .timeMachine: return "Time Machine"
            case .softwareUpdate: return "Software Update"
            case .backgroundDownload: return "Background Downloads"
            }
        }
        
        var ports: [Int] {
            switch self {
            case .macOSUpdates, .softwareUpdate:
                return [80, 443, 8088, 8888] // Apple CDN
            case .iCloudSync:
                return [443, 5223] // iCloud, push
            case .appStore:
                return [80, 443, 8080]
            case .timeMachine:
                return [548, 445] // AFP, SMB
            case .backgroundDownload:
                return [80, 443]
            }
        }
        
        var hosts: [String] {
            switch self {
            case .macOSUpdates, .softwareUpdate:
                return [
                    "swcdn.apple.com",
                    "swdist.apple.com",
                    "swdownload.apple.com",
                    "updates-http.cdn-apple.com",
                    "updates.cdn-apple.com"
                ]
            case .iCloudSync:
                return [
                    "icloud.com",
                    "icloud-content.com",
                    "me.com"
                ]
            case .appStore:
                return [
                    "itunes.apple.com",
                    "apps.apple.com",
                    "mzstatic.com"
                ]
            case .timeMachine:
                return [] // Local network
            case .backgroundDownload:
                return []
            }
        }
    }
    
    struct ShapingRule {
        let trafficType: TrafficType
        let delayMs: Int
        let bandwidthLimitKbps: Int?
        let isEnabled: Bool
    }
    
    struct TrafficStats {
        let trafficType: TrafficType
        let packetsDelayed: UInt64
        let bytesDelayed: UInt64
        let averageDelayMs: Double
    }
    
    // MARK: - Properties
    
    private var isShapingActive = false
    private var activeRules: [TrafficType: ShapingRule] = [:]
    private var interface: String = "en0"
    
    // Default shaping configuration
    private let defaultRules: [TrafficType: ShapingRule] = [
        .macOSUpdates: ShapingRule(trafficType: .macOSUpdates, delayMs: 500, bandwidthLimitKbps: 500, isEnabled: true),
        .iCloudSync: ShapingRule(trafficType: .iCloudSync, delayMs: 200, bandwidthLimitKbps: 1000, isEnabled: true),
        .appStore: ShapingRule(trafficType: .appStore, delayMs: 300, bandwidthLimitKbps: 2000, isEnabled: true),
        .timeMachine: ShapingRule(trafficType: .timeMachine, delayMs: 100, bandwidthLimitKbps: nil, isEnabled: false),
        .softwareUpdate: ShapingRule(trafficType: .softwareUpdate, delayMs: 500, bandwidthLimitKbps: 500, isEnabled: true),
        .backgroundDownload: ShapingRule(trafficType: .backgroundDownload, delayMs: 100, bandwidthLimitKbps: nil, isEnabled: true)
    ]
    
    // MARK: - Public Interface
    
    /// Enables traffic shaping with default rules
    func enableShaping(interface: String = "en0") async -> Bool {
        guard !isShapingActive else {
            Logger.info("Traffic shaping is already active")
            return true
        }
        
        self.interface = interface
        Logger.info("Enabling traffic shaping on \(interface)")
        
        // Load default rules
        activeRules = defaultRules
        
        // Generate and apply pfctl rules
        let rules = generatePFRules()
        let success = await applyPFRules(rules)
        
        if success {
            isShapingActive = true
            Logger.info("Traffic shaping enabled successfully")
        } else {
            Logger.error("Failed to enable traffic shaping")
            activeRules.removeAll()
        }
        
        return success
    }
    
    /// Disables traffic shaping
    func disableShaping() async {
        guard isShapingActive else { return }
        
        Logger.info("Disabling traffic shaping")
        
        // Clear all pfctl rules
        await clearPFRules()
        
        isShapingActive = false
        activeRules.removeAll()
        
        Logger.info("Traffic shaping disabled")
    }
    
    /// Updates shaping rule for a specific traffic type
    func updateRule(_ rule: ShapingRule) {
        activeRules[rule.trafficType] = rule
        
        if isShapingActive {
            Task {
                // Regenerate and reapply rules
                let rules = generatePFRules()
                _ = await applyPFRules(rules)
            }
        }
    }
    
    /// Gets current shaping configuration
    func getActiveRules() -> [ShapingRule] {
        return Array(activeRules.values)
    }
    
    /// Checks if traffic shaping is currently active
    func isActive() -> Bool {
        return isShapingActive
    }
    
    /// Temporarily pauses shaping for a specific traffic type
    func pauseShaping(for trafficType: TrafficType, duration: TimeInterval) {
        guard var rule = activeRules[trafficType] else { return }
        
        Logger.info("Pausing traffic shaping for \(trafficType.displayName) for \(duration) seconds")
        
        // Disable rule temporarily
        let originalRule = rule
        rule = ShapingRule(
            trafficType: trafficType,
            delayMs: 0,
            bandwidthLimitKbps: nil,
            isEnabled: false
        )
        activeRules[trafficType] = rule
        
        // Reapply rules
        Task {
            let rules = generatePFRules()
            _ = await applyPFRules(rules)
            
            // Restore after duration
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            
            if isShapingActive {
                activeRules[trafficType] = originalRule
                let rules = generatePFRules()
                _ = await applyPFRules(rules)
                Logger.info("Restored traffic shaping for \(trafficType.displayName)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func generatePFRules() -> String {
        var rules = "# TetherFlow Traffic Shaping Rules\n"
        rules += "# Generated at \(Date())\n\n"
        
        // Table definitions for hosts
        rules += "# Define tables for Apple services\n"
        rules += "table <apple_cdn> { swcdn.apple.com, swdist.apple.com, swdownload.apple.com, updates-http.cdn-apple.com, updates.cdn-apple.com }\n"
        rules += "table <icloud> { icloud.com, icloud-content.com, me.com }\n"
        rules += "table <appstore> { itunes.apple.com, apps.apple.com, mzstatic.com }\n\n"
        
        // Anchor for our rules
        rules += "anchor \"tetherflow_shaping\" {\n"
        
        for (_, rule) in activeRules where rule.isEnabled {
            rules += generateRuleForTrafficType(rule)
        }
        
        rules += "}\n"
        
        return rules
    }
    
    private func generateRuleForTrafficType(_ rule: ShapingRule) -> String {
        var ruleText = "  # \(rule.trafficType.displayName)\n"
        
        let delayParameter = rule.delayMs > 0 ? "delay \(rule.delayMs)ms" : ""
        let bandwidthParameter = rule.bandwidthLimitKbps != nil ? "bandwidth \(rule.bandwidthLimitKbps!)Kb" : ""
        
        // Generate rules for ports
        for port in rule.trafficType.ports {
            // Outbound rules
            ruleText += "  pass out on \(interface) proto tcp from any to any port \(port) \(delayParameter) \(bandwidthParameter)\n"
        }
        
        // Generate rules for hosts (if any)
        switch rule.trafficType {
        case .macOSUpdates, .softwareUpdate:
            ruleText += "  pass out on \(interface) proto tcp from any to <apple_cdn> \(delayParameter) \(bandwidthParameter)\n"
        case .iCloudSync:
            ruleText += "  pass out on \(interface) proto tcp from any to <icloud> \(delayParameter) \(bandwidthParameter)\n"
        case .appStore:
            ruleText += "  pass out on \(interface) proto tcp from any to <appstore> \(delayParameter) \(bandwidthParameter)\n"
        default:
            break
        }
        
        return ruleText
    }
    
    private func applyPFRules(_ rules: String) async -> Bool {
        // Write rules to temp file
        let tempFile = "/tmp/tetherflow_pf.rules"
        
        do {
            try rules.write(toFile: tempFile, atomically: true, encoding: .utf8)
        } catch {
            Logger.error("Failed to write PF rules: \(error.localizedDescription)")
            return false
        }
        
        // Apply rules using pfctl
        // Note: This requires root privileges, so it should be done through the helper
        let command = "pfctl -a tetherflow_shaping -f \(tempFile) 2>&1"
        
        let result = await executeCommand(command)
        let success = result.isEmpty || !result.contains("error")
        
        if !success {
            Logger.error("Failed to apply PF rules: \(result)")
        }
        
        // Cleanup temp file
        try? FileManager.default.removeItem(atPath: tempFile)
        
        return success
    }
    
    private func clearPFRules() async {
        let command = "pfctl -a tetherflow_shaping -F all 2>&1"
        let result = await executeCommand(command)
        
        if !result.isEmpty && result.contains("error") {
            Logger.error("Failed to clear PF rules: \(result)")
        }
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
                
                continuation.resume(returning: output)
            } catch {
                Logger.error("Command execution failed: \(error.localizedDescription)")
                continuation.resume(returning: "")
            }
        }
    }
    
    /// Checks if pfctl is available on the system
    func checkPFAvailability() async -> Bool {
        let command = "which pfctl"
        let result = await executeCommand(command)
        return !result.isEmpty && !result.contains("not found")
    }
}

// MARK: - Extensions

extension TrafficShaper.ShapingRule {
    /// User-friendly description of the rule
    var description: String {
        var parts: [String] = []
        if delayMs > 0 {
            parts.append("Delay: \(delayMs)ms")
        }
        if let limit = bandwidthLimitKbps {
            parts.append("Limit: \(limit) Kbps")
        }
        return parts.isEmpty ? "No shaping" : parts.joined(separator: ", ")
    }
}
