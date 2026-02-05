//
//  NetworkConfigurator.swift
//  TetherFlow
//
//  High-level network configuration coordinator
//

import Foundation

actor NetworkConfigurator {
    private var xpcClient = XPCClient()
    
    // MARK: - Cloaking Operations
    
    func applyCloaking(profile: HotspotProfile) async throws {
        // Connect to helper if not already connected
        try await xpcClient.connect()
        
        // Get the current network interface
        let interface = await getActiveInterface()
        
        // Apply cloaking settings via XPC to privileged helper
        let success = try await xpcClient.applyCloaking(
            ttl: profile.targetTTL,
            mtu: profile.targetMTU,
            interface: interface
        )
        
        guard success else {
            throw NetworkConfiguratorError.cloakingFailed
        }
        
        // Apply traffic shaping if enabled
        if profile.enableTrafficShaping {
            _ = try? await xpcClient.applyTrafficShaping(enable: true)
        }
    }
    
    func resetNetworkSettings(interface: String) async throws {
        try await xpcClient.connect()
        
        let success = try await xpcClient.resetNetworkSettings(interface: interface)
        
        // Disable traffic shaping
        _ = try? await xpcClient.applyTrafficShaping(enable: false)
        
        guard success else {
            throw NetworkConfiguratorError.resetFailed
        }
    }
    
    func verifyCloaking(interface: String) async throws -> Bool {
        try await xpcClient.connect()
        
        let currentTTL = try await xpcClient.getCurrentTTL()
        return currentTTL == 65  // Expected cloaked TTL
    }
    
    // MARK: - Helper Methods
    
    private func getActiveInterface() async -> String {
        // Default to en0 (primary Wi-Fi interface on Mac)
        // In a full implementation, this would detect the active interface
        return "en0"
    }
}

// MARK: - Errors

enum NetworkConfiguratorError: Error {
    case cloakingFailed
    case resetFailed
    case helperNotAvailable
    case invalidInterface
}

extension NetworkConfiguratorError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .cloakingFailed:
            return "Failed to apply network cloaking settings"
        case .resetFailed:
            return "Failed to reset network settings"
        case .helperNotAvailable:
            return "Privileged helper tool is not available"
        case .invalidInterface:
            return "Invalid network interface"
        }
    }
}
