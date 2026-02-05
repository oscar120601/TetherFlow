//
//  XPCClient.swift
//  TetherFlow
//
//  XPC communication client for privileged helper tool
//

import Foundation

actor XPCClient {
    private var connection: NSXPCConnection?
    private var helper: HelperProtocol?
    
    private let helperBundleIdentifier = "com.tetherflow.helper"
    
    // MARK: - Connection Management
    
    func connect() async throws {
        guard connection == nil else { return }
        
        let newConnection = NSXPCConnection(machServiceName: helperBundleIdentifier, options: .privileged)
        
        newConnection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
        
        newConnection.invalidationHandler = { [weak self] in
            Task { @MainActor in
                self?.connection = nil
                self?.helper = nil
            }
        }
        
        newConnection.interruptionHandler = { [weak self] in
            Task { @MainActor in
                self?.connection = nil
                self?.helper = nil
            }
        }
        
        newConnection.resume()
        
        // Verify connection with ping
        let proxy = newConnection.remoteObjectProxy as? HelperProtocol
        
        return try await withCheckedThrowingContinuation { continuation in
            proxy?.ping { isResponsive in
                if isResponsive {
                    self.connection = newConnection
                    self.helper = proxy
                    continuation.resume()
                } else {
                    continuation.resume(throwing: XPCError.connectionFailed)
                }
            }
        }
    }
    
    func disconnect() {
        connection?.invalidate()
        connection = nil
        helper = nil
    }
    
    // MARK: - Helper Protocol Methods
    
    func applyCloaking(ttl: Int, mtu: Int, interface: String) async throws -> Bool {
        guard let helper = helper else {
            throw XPCError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            helper.applyCloaking(withTTL: ttl, mtu: mtu, interface: interface) { success in
                continuation.resume(returning: success)
            }
        }
    }
    
    func resetNetworkSettings(interface: String) async throws -> Bool {
        guard let helper = helper else {
            throw XPCError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            helper.resetNetworkSettings(withInterface: interface) { success in
                continuation.resume(returning: success)
            }
        }
    }
    
    func getCurrentTTL() async throws -> Int {
        guard let helper = helper else {
            throw XPCError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            helper.getCurrentTTL { ttl in
                continuation.resume(returning: ttl)
            }
        }
    }
    
    func applyTrafficShaping(enable: Bool) async throws -> Bool {
        guard let helper = helper else {
            throw XPCError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            helper.applyTrafficShaping(enable) { success in
                continuation.resume(returning: success)
            }
        }
    }
    
    func ping() async throws -> Bool {
        guard let helper = helper else {
            throw XPCError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            helper.ping { isResponsive in
                continuation.resume(returning: isResponsive)
            }
        }
    }
}

// MARK: - Errors

enum XPCError: Error {
    case connectionFailed
    case notConnected
    case requestFailed
}

extension XPCError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to privileged helper"
        case .notConnected:
            return "Not connected to helper"
        case .requestFailed:
            return "XPC request failed"
        }
    }
}

// MARK: - Helper Protocol Definition

@objc protocol HelperProtocol {
    func applyCloaking(withTTL ttl: Int, mtu: Int, interface: String, withReply reply: @escaping (Bool) -> Void)
    func resetNetworkSettings(withInterface interface: String, withReply reply: @escaping (Bool) -> Void)
    func getCurrentTTL(withReply reply: @escaping (Int) -> Void)
    func applyTrafficShaping(_ enable: Bool, withReply reply: @escaping (Bool) -> Void)
    func ping(withReply reply: @escaping (Bool) -> Void)
}
