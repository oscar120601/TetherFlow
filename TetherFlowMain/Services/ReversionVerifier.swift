//
//  ReversionVerifier.swift
//  TetherFlow
//
//  Verifies that network settings have been properly restored after disconnection
//

import Foundation

/// Verifies network settings reversion after cloaking deactivation
actor ReversionVerifier {
    
    // MARK: - Types
    
    struct ReversionResult {
        let success: Bool
        let ttlRestored: Bool
        let mtuRestored: Bool
        let dnsRestored: Bool
        let errors: [ReversionError]
        let retryAttempts: Int
        
        var isFullyRestored: Bool {
            ttlRestored && mtuRestored && dnsRestored
        }
    }
    
    struct ReversionError: Identifiable {
        let id = UUID()
        let component: NetworkComponent
        let expectedValue: String
        let actualValue: String
        let message: String
    }
    
    enum NetworkComponent: String {
        case ttl = "TTL"
        case mtu = "MTU"
        case dns = "DNS"
    }
    
    // MARK: - Properties
    
    private let networkConfigurator = NetworkConfigurator()
    private let dnsConfigurator = DNSConfigurator()
    
    // Expected default values
    private let defaultTTL = 64
    private let defaultMTU = 1500
    
    // MARK: - Public Interface
    
    /// Verifies that all network settings have been restored to defaults
    /// - Parameters:
    ///   - interface: The network interface to verify
    ///   - maxRetries: Maximum number of retry attempts
    /// - Returns: Reversion result with detailed status
    func verifyReversion(interface: String = "en0", maxRetries: Int = 3) async -> ReversionResult {
        Logger.info("Starting reversion verification for \(interface)")
        
        var errors: [ReversionError] = []
        var attempts = 0
        
        var ttlRestored = false
        var mtuRestored = false
        var dnsRestored = false
        
        // Try verification with retries
        while attempts < maxRetries {
            attempts += 1
            
            // Check TTL
            do {
                let currentTTL = try await networkConfigurator.getCurrentTTL()
                ttlRestored = (currentTTL == defaultTTL)
                
                if !ttlRestored {
                    let error = ReversionError(
                        component: .ttl,
                        expectedValue: "\(defaultTTL)",
                        actualValue: "\(currentTTL)",
                        message: "TTL not restored. Expected \(defaultTTL), got \(currentTTL)"
                    )
                    if !errors.contains(where: { $0.component == .ttl }) {
                        errors.append(error)
                    }
                    Logger.warning("TTL verification failed: \(currentTTL) != \(defaultTTL)")
                }
            } catch {
                Logger.error("Failed to verify TTL: \(error.localizedDescription)")
            }
            
            // Check MTU
            let currentMTU = await getCurrentMTU(for: interface)
            mtuRestored = (currentMTU == defaultMTU)
            
            if !mtuRestored {
                let error = ReversionError(
                    component: .mtu,
                    expectedValue: "\(defaultMTU)",
                    actualValue: "\(currentMTU)",
                    message: "MTU not restored. Expected \(defaultMTU), got \(currentMTU)"
                )
                if !errors.contains(where: { $0.component == .mtu }) {
                    errors.append(error)
                }
                Logger.warning("MTU verification failed: \(currentMTU) != \(defaultMTU)")
            }
            
            // Check DNS
            dnsRestored = await dnsConfigurator.verifyOriginalDNS(interface: interface)
            
            if !dnsRestored {
                let error = ReversionError(
                    component: .dns,
                    expectedValue: "DHCP/Default",
                    actualValue: "Custom",
                    message: "DNS settings not restored to default"
                )
                if !errors.contains(where: { $0.component == .dns }) {
                    errors.append(error)
                }
                Logger.warning("DNS verification failed")
            }
            
            // Check if all restored
            if ttlRestored && mtuRestored && dnsRestored {
                Logger.info("Reversion verified successfully after \(attempts) attempt(s)")
                return ReversionResult(
                    success: true,
                    ttlRestored: true,
                    mtuRestored: true,
                    dnsRestored: true,
                    errors: [],
                    retryAttempts: attempts
                )
            }
            
            // If not restored and we have retries left, wait and retry
            if attempts < maxRetries {
                Logger.info("Reverification needed, waiting 500ms before retry \(attempts + 1)/\(maxRetries)")
                try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
            }
        }
        
        // Max retries reached, return failure
        Logger.error("Reversion verification failed after \(maxRetries) attempts")
        return ReversionResult(
            success: false,
            ttlRestored: ttlRestored,
            mtuRestored: mtuRestored,
            dnsRestored: dnsRestored,
            errors: errors,
            retryAttempts: attempts
        )
    }
    
    /// Attempts to force restore network settings if verification failed
    /// - Parameter interface: The network interface
    /// - Returns: Whether force restore succeeded
    func forceRestore(interface: String = "en0") async -> Bool {
        Logger.fault("Attempting force restore of network settings")
        
        do {
            // Force reset network settings
            try await networkConfigurator.resetNetworkSettings(interface: interface)
            
            // Restore DNS
            _ = await dnsConfigurator.restoreOriginalDNS(interface: interface)
            
            // Wait a moment for changes to apply
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Verify again
            let result = await verifyReversion(interface: interface, maxRetries: 1)
            
            if result.success {
                Logger.info("Force restore succeeded")
            } else {
                Logger.fault("Force restore failed: \(result.errors.map { $0.message }.joined(separator: ", "))")
            }
            
            return result.success
            
        } catch {
            Logger.fault("Force restore error: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func getCurrentMTU(for interface: String) async -> Int {
        let command = "/usr/sbin/networksetup -getMTU \(interface)"
        
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
                
                // Parse output: "Active MTU: 1500 (Current Setting: 1500)"
                if let range = output.range(of: "Active MTU: "),
                   let endRange = output[range.upperBound...].range(of: " ") {
                    let mtuString = String(output[range.upperBound..<endRange.lowerBound])
                    if let mtu = Int(mtuString) {
                        continuation.resume(returning: mtu)
                        return
                    }
                }
                
                continuation.resume(returning: 0)
            } catch {
                Logger.error("Failed to get MTU: \(error.localizedDescription)")
                continuation.resume(returning: 0)
            }
        }
    }
}

// MARK: - Extensions

extension ReversionVerifier.ReversionResult {
    /// User-friendly summary of reversion status
    var summary: String {
        if success {
            return "All network settings successfully restored"
        } else {
            var parts: [String] = []
            if !ttlRestored { parts.append("TTL") }
            if !mtuRestored { parts.append("MTU") }
            if !dnsRestored { parts.append("DNS") }
            return "Failed to restore: \(parts.joined(separator: ", "))"
        }
    }
    
    /// Detailed error message for logging
    var detailedErrorMessage: String {
        errors.map { "[\($0.component)] \($0.message)" }.joined(separator: "; ")
    }
}
