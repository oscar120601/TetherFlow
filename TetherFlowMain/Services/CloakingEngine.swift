//
//  CloakingEngine.swift
//  TetherFlow
//
//  Coordinates network cloaking activation and deactivation
//

import Foundation
import Network

/// Coordinates the activation and deactivation of network cloaking
actor CloakingEngine {
    
    // MARK: - Properties
    
    private let networkConfigurator = NetworkConfigurator()
    private let helperInstaller = HelperInstaller()
    
    private var currentSession: CloakingSession?
    private var isProcessing = false
    
    // MARK: - State Tracking
    
    private(set) var lastError: CloakingError?
    private(set) var activationHistory: [CloakingSession] = []
    
    // MARK: - Public Interface
    
    /// Activates cloaking for a specific profile
    /// - Parameters:
    ///   - profile: The hotspot profile to activate cloaking for
    ///   - interface: The network interface to apply settings to
    /// - Returns: The created cloaking session
    /// - Throws: CloakingError if activation fails
    func activate(profile: HotspotProfile, interface: String = "en0") async throws -> CloakingSession {
        // Prevent concurrent activation
        guard !isProcessing else {
            throw CloakingError.alreadyProcessing
        }
        
        // Check if already active
        if let session = currentSession, session.isActive {
            Logger.warning("Cloaking is already active for \(session.ssid)")
            throw CloakingError.alreadyActive(session: session)
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        Logger.info("Starting cloaking activation for \(profile.ssid)")
        
        do {
            // Ensure helper is installed
            let helperInstalled = try await helperInstaller.ensureHelperInstalled()
            guard helperInstalled else {
                throw CloakingError.helperNotAvailable
            }
            
            // Apply cloaking settings
            try await networkConfigurator.applyCloaking(profile: profile)
            
            // Verify settings were applied
            let verified = try await networkConfigurator.verifyCloaking(interface: interface)
            guard verified else {
                throw CloakingError.verificationFailed
            }
            
            // Create session
            let session = CloakingSession(
                profileId: profile.id,
                ssid: profile.ssid,
                interface: interface,
                appliedTTL: profile.targetTTL,
                appliedMTU: profile.targetMTU
            )
            
            currentSession = session
            activationHistory.append(session)
            
            Logger.info("Cloaking activated successfully for \(profile.ssid)")
            
            return session
            
        } catch let error as CloakingError {
            lastError = error
            Logger.error("Cloaking activation failed: \(error.localizedDescription)")
            throw error
        } catch {
            let cloakingError = CloakingError.underlying(error)
            lastError = cloakingError
            Logger.error("Cloaking activation failed: \(error.localizedDescription)")
            throw cloakingError
        }
    }
    
    /// Deactivates cloaking and restores network settings
    /// - Parameter session: The session to deactivate (defaults to current session)
    /// - Throws: CloakingError if deactivation fails
    func deactivate(session: CloakingSession? = nil) async throws {
        guard !isProcessing else {
            throw CloakingError.alreadyProcessing
        }
        
        let targetSession = session ?? currentSession
        guard let targetSession = targetSession else {
            Logger.warning("No active cloaking session to deactivate")
            return
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        Logger.info("Starting cloaking deactivation for \(targetSession.ssid)")
        
        do {
            // Reset network settings
            try await networkConfigurator.resetNetworkSettings(
                interface: targetSession.interface
            )
            
            // Complete the session
            targetSession.complete()
            
            // Clear current session if it matches
            if currentSession?.id == targetSession.id {
                currentSession = nil
            }
            
            Logger.info("Cloaking deactivated successfully")
            
        } catch {
            targetSession.fail()
            let cloakingError = CloakingError.deactivationFailed(error)
            lastError = cloakingError
            Logger.error("Cloaking deactivation failed: \(error.localizedDescription)")
            throw cloakingError
        }
    }
    
    /// Emergency deactivation (kill switch)
    /// Attempts to restore network settings even if normal deactivation fails
    func emergencyDeactivate() async {
        Logger.fault("EMERGENCY DEACTIVATION TRIGGERED")
        
        guard let session = currentSession else {
            Logger.warning("No active session for emergency deactivation")
            return
        }
        
        do {
            // Try normal deactivation first
            try await deactivate(session: session)
        } catch {
            // If that fails, try direct reset
            Logger.error("Normal deactivation failed, attempting direct reset: \(error.localizedDescription)")
            
            do {
                try await networkConfigurator.resetNetworkSettings(interface: session.interface)
                session.complete()
                currentSession = nil
                Logger.info("Emergency deactivation successful")
            } catch {
                session.fail()
                Logger.fault("EMERGENCY DEACTIVATION FAILED: \(error.localizedDescription)")
            }
        }
    }
    
    /// Verifies that cloaking is currently active
    /// - Parameter interface: The network interface to check
    /// - Returns: True if cloaking is verified active
    func verifyActive(interface: String = "en0") async -> Bool {
        do {
            return try await networkConfigurator.verifyCloaking(interface: interface)
        } catch {
            Logger.error("Failed to verify cloaking status: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Gets the current active session
    func getCurrentSession() -> CloakingSession? {
        currentSession
    }
    
    /// Gets the last error that occurred
    func getLastError() -> CloakingError? {
        lastError
    }
    
    /// Clears the last error
    func clearLastError() {
        lastError = nil
    }
    
    /// Gets activation history (limited to recent sessions)
    func getActivationHistory(limit: Int = 10) -> [CloakingSession] {
        Array(activationHistory.suffix(limit))
    }
}

// MARK: - Errors

enum CloakingError: Error, LocalizedError {
    case alreadyProcessing
    case alreadyActive(session: CloakingSession)
    case helperNotAvailable
    case verificationFailed
    case deactivationFailed(Error)
    case underlying(Error)
    
    var errorDescription: String? {
        switch self {
        case .alreadyProcessing:
            return "Cloaking operation already in progress"
        case .alreadyActive(let session):
            return "Cloaking is already active for \(session.ssid)"
        case .helperNotAvailable:
            return "Privileged helper tool is not available"
        case .verificationFailed:
            return "Failed to verify cloaking settings were applied"
        case .deactivationFailed(let error):
            return "Failed to deactivate cloaking: \(error.localizedDescription)"
        case .underlying(let error):
            return "Cloaking error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .alreadyProcessing:
            return "Please wait for the current operation to complete"
        case .alreadyActive:
            return "Deactivate the current session first, or use the kill switch"
        case .helperNotAvailable:
            return "Try reinstalling the helper tool or restart the app"
        case .verificationFailed:
            return "Check network permissions and try again"
        case .deactivationFailed:
            return "Use the kill switch to force deactivation"
        case .underlying:
            return "Check the system log for more details"
        }
    }
}
