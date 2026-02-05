//
//  HelperInstaller.swift
//  TetherFlow
//
//  Privileged helper tool installation using SMJobBless
//

import Foundation
import ServiceManagement

/// Manages the installation and removal of the privileged helper tool
actor HelperInstaller {
    
    // MARK: - Constants
    
    private let helperBundleIdentifier = "com.tetherflow.helper"
    private let mainAppBundleIdentifier = "com.tetherflow.app"
    
    // MARK: - Properties
    
    private var installationContinuation: CheckedContinuation<Bool, Error>?
    
    // MARK: - Public Interface
    
    /// Checks if the helper tool is currently installed and available
    func isHelperInstalled() -> Bool {
        // Check if the helper tool is registered with launchd
        let jobDict = SMJobCopyDictionary(kSMDomainSystemLaunchd, helperBundleIdentifier as CFString)
        return jobDict != nil
    }
    
    /// Installs the privileged helper tool using SMJobBless
    /// - Returns: True if installation was successful
    /// - Throws: HelperInstallerError if installation fails
    func installHelper() async throws -> Bool {
        // Check if already installed
        if isHelperInstalled() {
            Logger.info("Helper tool is already installed")
            return true
        }
        
        Logger.info("Starting helper tool installation...")
        
        // Use SMJobBless to install the helper
        // This will prompt the user for admin credentials
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            self.installationContinuation = continuation
            
            // Get the authorization reference
            var authRef: AuthorizationRef?
            let status = AuthorizationCreate(nil, nil, [.interactionAllowed, .extendRights, .preAuthorize], &authRef)
            
            guard status == errAuthorizationSuccess, let authorization = authRef else {
                continuation.resume(throwing: HelperInstallerError.authorizationFailed)
                return
            }
            
            // Install the helper tool
            var error: Unmanaged<CFError>?
            let success = SMJobBless(
                kSMDomainSystemLaunchd,
                helperBundleIdentifier as CFString,
                authorization,
                &error
            )
            
            // Clean up authorization
            AuthorizationFree(authorization, [.destroyRights])
            
            if let error = error?.takeRetainedValue() {
                let nsError = error as Error
                Logger.error("SMJobBless failed: \(nsError.localizedDescription)")
                continuation.resume(throwing: HelperInstallerError.installationFailed(underlying: nsError))
            } else if success {
                Logger.info("Helper tool installed successfully")
                continuation.resume(returning: true)
            } else {
                Logger.error("SMJobBless returned false without error")
                continuation.resume(throwing: HelperInstallerError.installationFailed(underlying: nil))
            }
        }
        
        self.installationContinuation = nil
        return result
    }
    
    /// Removes the privileged helper tool
    /// - Returns: True if removal was successful
    /// - Throws: HelperInstallerError if removal fails
    func removeHelper() async throws -> Bool {
        Logger.info("Removing helper tool...")
        
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            // Get the authorization reference
            var authRef: AuthorizationRef?
            let status = AuthorizationCreate(nil, nil, [.interactionAllowed, .extendRights], &authRef)
            
            guard status == errAuthorizationSuccess, let authorization = authRef else {
                continuation.resume(throwing: HelperInstallerError.authorizationFailed)
                return
            }
            
            // Remove the helper tool
            var error: Unmanaged<CFError>?
            let success = SMJobRemove(
                kSMDomainSystemLaunchd,
                helperBundleIdentifier as CFString,
                authorization,
                true,  // wait for removal
                &error
            )
            
            // Clean up authorization
            AuthorizationFree(authorization, [.destroyRights])
            
            if let error = error?.takeRetainedValue() {
                let nsError = error as Error
                Logger.error("SMJobRemove failed: \(nsError.localizedDescription)")
                continuation.resume(throwing: HelperInstallerError.removalFailed(underlying: nsError))
            } else if success {
                Logger.info("Helper tool removed successfully")
                continuation.resume(returning: true)
            } else {
                Logger.error("SMJobRemove returned false without error")
                continuation.resume(throwing: HelperInstallerError.removalFailed(underlying: nil))
            }
        }
        
        return result
    }
    
    /// Verifies the helper tool is installed and responsive
    /// - Returns: True if helper is available
    func verifyHelper() async -> Bool {
        guard isHelperInstalled() else {
            return false
        }
        
        // Try to ping the helper via XPC
        do {
            let client = XPCClient()
            return try await client.ping()
        } catch {
            Logger.error("Helper ping failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Ensures the helper is installed, attempting installation if needed
    /// - Returns: True if helper is available (either already installed or newly installed)
    /// - Throws: HelperInstallerError if installation is required but fails
    func ensureHelperInstalled() async throws -> Bool {
        if await verifyHelper() {
            return true
        }
        
        // Try to install
        return try await installHelper()
    }
}

// MARK: - Errors

enum HelperInstallerError: Error, LocalizedError {
    case authorizationFailed
    case installationFailed(underlying: Error?)
    case removalFailed(underlying: Error?)
    case helperNotFound
    
    var errorDescription: String? {
        switch self {
        case .authorizationFailed:
            return "Failed to obtain authorization. Administrator privileges are required."
        case .installationFailed(let underlying):
            if let underlying = underlying {
                return "Failed to install helper tool: \(underlying.localizedDescription)"
            }
            return "Failed to install helper tool. Please check system permissions."
        case .removalFailed(let underlying):
            if let underlying = underlying {
                return "Failed to remove helper tool: \(underlying.localizedDescription)"
            }
            return "Failed to remove helper tool."
        case .helperNotFound:
            return "Helper tool not found in app bundle."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authorizationFailed:
            return "Please ensure you have administrator access and try again."
        case .installationFailed:
            return "Try restarting the app or contact support if the issue persists."
        case .removalFailed:
            return "You may need to manually remove the helper from /Library/PrivilegedHelperTools/"
        case .helperNotFound:
            return "Please reinstall the application."
        }
    }
}
