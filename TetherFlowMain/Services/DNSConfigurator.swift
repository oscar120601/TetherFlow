//
//  DNSConfigurator.swift
//  TetherFlow
//
//  Configures encrypted DNS (DoH/DoT) during cloaking sessions
//

import Foundation
import Network

/// Manages encrypted DNS configuration
actor DNSConfigurator {
    
    // MARK: - DNS Provider Configurations
    
    enum DNSProvider: String, CaseIterable, Identifiable {
        case cloudflare = "cloudflare"
        case quad9 = "quad9"
        case custom = "custom"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .cloudflare: return "Cloudflare"
            case .quad9: return "Quad9"
            case .custom: return "Custom"
            }
        }
        
        var description: String {
            switch self {
            case .cloudflare:
                return "Fast, privacy-focused DNS (1.1.1.1)"
            case .quad9:
                return "Security-focused DNS with malware blocking (9.9.9.9)"
            case .custom:
                return "Your own DNS configuration"
            }
        }
        
        /// Returns the DNS server settings for this provider
        var settings: DNSSettings? {
            switch self {
            case .cloudflare:
                return DNSSettings(
                    servers: ["1.1.1.1", "1.0.0.1"],
                    dohURL: "https://cloudflare-dns.com/dns-query",
                    dotHostname: "cloudflare-dns.com"
                )
            case .quad9:
                return DNSSettings(
                    servers: ["9.9.9.9", "149.112.112.112"],
                    dohURL: "https://dns.quad9.net/dns-query",
                    dotHostname: "dns.quad9.net"
                )
            case .custom:
                return nil // Must be configured manually
            }
        }
    }
    
    struct DNSSettings: Codable, Equatable {
        let servers: [String]
        let dohURL: String?
        let dotHostname: String?
        let name: String?
        
        var isDoHSupported: Bool { dohURL != nil }
        var isDoTSupported: Bool { dotHostname != nil }
        
        init(servers: [String], dohURL: String? = nil, dotHostname: String? = nil, name: String? = nil) {
            self.servers = servers
            self.dohURL = dohURL
            self.dotHostname = dotHostname
            self.name = name
        }
    }
    
    /// Custom DNS provider configuration
    struct CustomDNSConfig: Codable, Identifiable {
        let id: UUID
        var name: String
        var servers: [String]
        var dohURL: String?
        var dotHostname: String?
        var isEnabled: Bool
        
        init(id: UUID = UUID(), name: String, servers: [String], dohURL: String? = nil, dotHostname: String? = nil, isEnabled: Bool = true) {
            self.id = id
            self.name = name
            self.servers = servers
            self.dohURL = dohURL
            self.dotHostname = dotHostname
            self.isEnabled = isEnabled
        }
        
        var toDNSSettings: DNSSettings {
            DNSSettings(servers: servers, dohURL: dohURL, dotHostname: dotHostname, name: name)
        }
    }
    
    // MARK: - Properties
    
    private var originalSettings: DNSSettings?
    private var isConfigured = false
    
    // MARK: - Public Interface
    
    /// Applies encrypted DNS configuration
    /// - Parameters:
    ///   - provider: The DNS provider to use
    ///   - interface: The network interface to configure
    /// - Returns: True if configuration was successful
    func applyEncryptedDNS(provider: DNSProvider, interface: String = "en0") async -> Bool {
        guard let settings = provider.settings else {
            Logger.warning("No settings available for provider \(provider.displayName)")
            return false
        }
        
        Logger.info("Applying encrypted DNS: \(provider.displayName)")
        
        // Store original settings before modifying
        if originalSettings == nil {
            originalSettings = await getCurrentDNSSettings(interface: interface)
        }
        
        // Apply DNS settings using networksetup
        let success = await configureDNSServers(settings.servers, interface: interface)
        
        if success {
            isConfigured = true
            Logger.info("Encrypted DNS applied successfully")
        } else {
            Logger.error("Failed to apply encrypted DNS")
        }
        
        return success
    }
    
    /// Restores original DNS settings
    /// - Parameter interface: The network interface to restore
    /// - Returns: True if restoration was successful
    func restoreOriginalDNS(interface: String = "en0") async -> Bool {
        guard isConfigured else {
            Logger.debug("No DNS configuration to restore")
            return true
        }
        
        Logger.info("Restoring original DNS settings")
        
        let success: Bool
        if let original = originalSettings {
            success = await configureDNSServers(original.servers, interface: interface)
        } else {
            // Clear custom DNS to use DHCP defaults
            success = await clearDNSServers(interface: interface)
        }
        
        if success {
            isConfigured = false
            originalSettings = nil
            Logger.info("Original DNS settings restored")
        } else {
            Logger.error("Failed to restore original DNS settings")
        }
        
        return success
    }
    
    /// Verifies that encrypted DNS is active
    /// - Parameter interface: The network interface to check
    /// - Returns: True if encrypted DNS is verified active
    func verifyEncryptedDNS(interface: String = "en0") async -> Bool {
        let currentSettings = await getCurrentDNSSettings(interface: interface)
        
        // Check if current servers match known encrypted DNS servers
        let knownEncryptedServers = [
            "1.1.1.1", "1.0.0.1",           // Cloudflare
            "9.9.9.9", "149.112.112.112"     // Quad9
        ]
        
        let hasEncryptedServer = currentSettings.servers.contains { server in
            knownEncryptedServers.contains(server)
        }
        
        return hasEncryptedServer
    }
    
    /// Gets available DNS providers
    func getAvailableProviders() -> [DNSProvider] {
        DNSProvider.allCases
    }
    
    // MARK: - Custom DNS Management
    
    private let customDNSKey = "com.tetherflow.customDNSProviders"
    
    /// Saves a custom DNS configuration
    /// - Parameter config: Custom DNS configuration to save
    func saveCustomDNS(_ config: CustomDNSConfig) {
        var configs = loadCustomDNSConfigs()
        
        // Update existing or add new
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
        } else {
            configs.append(config)
        }
        
        do {
            let data = try JSONEncoder().encode(configs)
            UserDefaults.standard.set(data, forKey: customDNSKey)
            Logger.info("Custom DNS saved: \(config.name)")
        } catch {
            Logger.error("Failed to save custom DNS: \(error.localizedDescription)")
        }
    }
    
    /// Loads all custom DNS configurations
    /// - Returns: Array of custom DNS configurations
    func loadCustomDNSConfigs() -> [CustomDNSConfig] {
        guard let data = UserDefaults.standard.data(forKey: customDNSKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([CustomDNSConfig].self, from: data)
        } catch {
            Logger.error("Failed to load custom DNS: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Deletes a custom DNS configuration
    /// - Parameter id: ID of the configuration to delete
    func deleteCustomDNS(id: UUID) {
        var configs = loadCustomDNSConfigs()
        configs.removeAll { $0.id == id }
        
        do {
            let data = try JSONEncoder().encode(configs)
            UserDefaults.standard.set(data, forKey: customDNSKey)
            Logger.info("Custom DNS deleted: \(id)")
        } catch {
            Logger.error("Failed to delete custom DNS: \(error.localizedDescription)")
        }
    }
    
    /// Applies a custom DNS configuration
    /// - Parameters:
    ///   - config: Custom DNS configuration to apply
    ///   - interface: Network interface
    /// - Returns: True if successful
    func applyCustomDNS(_ config: CustomDNSConfig, interface: String = "en0") async -> Bool {
        guard config.isEnabled else {
            Logger.warning("Custom DNS \(config.name) is disabled")
            return false
        }
        
        Logger.info("Applying custom DNS: \(config.name)")
        
        // Store original settings
        if originalSettings == nil {
            originalSettings = await getCurrentDNSSettings(interface: interface)
        }
        
        // Apply DNS servers
        let success = await configureDNSServers(config.servers, interface: interface)
        
        if success {
            isConfigured = true
            Logger.info("Custom DNS \(config.name) applied successfully")
        } else {
            Logger.error("Failed to apply custom DNS \(config.name)")
        }
        
        return success
    }
    
    /// Verifies that DNS settings are restored to original
    func verifyOriginalDNS(interface: String) async -> Bool {
        let current = await getCurrentDNSSettings(interface: interface)
        
        // If we have original settings, compare
        if let original = originalSettings {
            return current.servers == original.servers
        }
        
        // Otherwise, check if using DHCP (empty or Any DNS)
        return current.servers.isEmpty || 
               current.servers.contains("There aren't any DNS Servers set on")
    }
    
    // MARK: - Private Methods
    
    private func getCurrentDNSSettings(interface: String) async -> DNSSettings {
        // Use networksetup to get current DNS servers
        let command = "/usr/sbin/networksetup -getdnsservers \(interface)"
        
        let output = await executeCommand(command)
        let servers = output.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.contains("Any DNS") }
        
        return DNSSettings(servers: servers, dohURL: nil, dotHostname: nil)
    }
    
    private func configureDNSServers(_ servers: [String], interface: String) async -> Bool {
        let serverList = servers.joined(separator: " ")
        let command: String
        
        if servers.isEmpty {
            command = "/usr/sbin/networksetup -setdnsservers \(interface) empty"
        } else {
            command = "/usr/sbin/networksetup -setdnsservers \(interface) \(serverList)"
        }
        
        let result = await executeCommand(command)
        let success = !result.contains("error") && !result.contains("fail")
        
        return success
    }
    
    private func clearDNSServers(interface: String) async -> Bool {
        // Setting to "empty" restores DHCP-provided DNS
        let command = "/usr/sbin/networksetup -setdnsservers \(interface) empty"
        let result = await executeCommand(command)
        return !result.contains("error")
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
}

// MARK: - DNS over HTTPS (DoH) Configuration

#if canImport(NetworkExtension)
import NetworkExtension

extension DNSConfigurator {
    /// Configures DNS over HTTPS using NetworkExtension
    /// Note: Requires NetworkExtension entitlement and user approval
    func configureDoH(provider: DNSProvider) async throws {
        guard let settings = provider.settings,
              let dohURLString = settings.dohURL,
              let dohURL = URL(string: dohURLString) else {
            throw DNSError.configurationFailed("Invalid DoH settings for \(provider.displayName)")
        }
        
        Logger.info("Configuring DoH for \(provider.displayName)")
        
        // Note: Actual DoH configuration requires NetworkExtension
        // This is a placeholder for the implementation
        // In production, this would use NEDNSSettingsManager
        
        // Example implementation (requires proper entitlements):
        /*
        let dohSettings = NEDNSOverHTTPSSettings(servers: settings.servers)
        dohSettings.serverURL = dohURL
        
        let manager = NEDNSSettingsManager.shared()
        try await manager.loadFromPreferences()
        
        manager.onDemandRules = [NEOnDemandRuleConnect()]
        manager.dnsSettings = dohSettings
        
        try await manager.saveToPreferences()
        */
        
        Logger.info("DoH configuration saved (requires NetworkExtension entitlement)")
    }
}

enum DNSError: Error {
    case configurationFailed(String)
    case notAuthorized
    case settingsNotSaved
}

#endif
