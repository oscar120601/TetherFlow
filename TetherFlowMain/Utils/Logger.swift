//
//  Logger.swift
//  TetherFlow
//
//  Unified logging utility for the TetherFlow application
//

import Foundation
import OSLog

/// Unified logging interface for TetherFlow
/// Provides consistent logging across the application with different log levels
enum Logger {
    
    // MARK: - Loggers
    
    private static let subsystem = "com.tetherflow.app"
    
    /// Main app logger
    private static let appLogger = OSLog(subsystem: subsystem, category: "App")
    
    /// Network-related logger
    private static let networkLogger = OSLog(subsystem: subsystem, category: "Network")
    
    /// XPC communication logger
    private static let xpcLogger = OSLog(subsystem: subsystem, category: "XPC")
    
    /// UI-related logger
    private static let uiLogger = OSLog(subsystem: subsystem, category: "UI")
    
    /// Security audit logger
    private static let auditLogger = OSLog(subsystem: subsystem, category: "Audit")
    
    // MARK: - Configuration
    
    /// Minimum log level to output (can be changed at runtime)
    static var minimumLogLevel: LogLevel = .debug
    
    /// Whether to include file and line information in logs
    static var includeSourceLocation: Bool = true
    
    /// Whether to log to console (in addition to OSLog)
    static var logToConsole: Bool = true
    
    /// Whether to enable secure audit logging
    static var enableAuditLogging: Bool = true
    
    // MARK: - Public Logging Methods
    
    /// Logs a debug message
    static func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, logger: appLogger, file: file, function: function, line: line)
    }
    
    /// Logs an informational message
    static func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, logger: appLogger, file: file, function: function, line: line)
    }
    
    /// Logs a warning message
    static func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, logger: appLogger, file: file, function: function, line: line)
    }
    
    /// Logs an error message
    static func error(
        _ message: String,
        error: Swift.Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(fullMessage, level: .error, logger: appLogger, file: file, function: function, line: line)
    }
    
    /// Logs a fault/critical message
    static func fault(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .fault, logger: appLogger, file: file, function: function, line: line)
    }
    
    // MARK: - Category-Specific Loggers
    
    /// Logs network-related messages
    static func network(
        _ message: String,
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: level, logger: networkLogger, file: file, function: function, line: line)
    }
    
    /// Logs XPC communication messages
    static func xpc(
        _ message: String,
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: level, logger: xpcLogger, file: file, function: function, line: line)
    }
    
    /// Logs UI-related messages
    static func ui(
        _ message: String,
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: level, logger: uiLogger, file: file, function: function, line: line)
    }
    
    // MARK: - Secure Audit Logging
    
    /// Logs a security-sensitive audit event
    /// - Parameters:
    ///   - action: The action being performed (e.g., "cloak_activated")
    ///   - actor: Who/what performed the action (e.g., "user", "system", "auto")
    ///   - target: What was affected (e.g., "profile_id", "interface_en0")
    ///   - result: The result of the action
    ///   - metadata: Additional context (sanitized, no PII)
    static func audit(
        action: String,
        actor: String,
        target: String,
        result: AuditResult,
        metadata: [String: String] = [:]
    ) {
        guard enableAuditLogging else { return }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let sanitizedMetadata = sanitizeAuditMetadata(metadata)
        let metadataString = sanitizedMetadata.isEmpty ? "none" : 
            sanitizedMetadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        
        let auditMessage = """
            🔒 AUDIT [\(timestamp)]
            Action: \(action)
            Actor: \(actor)
            Target: \(target)
            Result: \(result.description)
            Metadata: \(metadataString)
            ---
            """
        
        // Log to OSLog audit category
        os_log("%{public}@", log: auditLogger, type: .info, auditMessage)
        
        // Write to secure audit log file
        auditLogToFile(auditMessage)
        
        // Also log to console if enabled
        if logToConsole {
            print(auditMessage)
        }
    }
    
    /// Audit result types for secure logging
    enum AuditResult {
        case success
        case failure(reason: String)
        case denied(reason: String)
        
        var description: String {
            switch self {
            case .success:
                return "SUCCESS"
            case .failure(let reason):
                // Sanitize the reason
                let sanitized = reason
                    .replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "\r", with: "")
                    .prefix(100)
                return "FAILURE: \(sanitized)"
            case .denied(let reason):
                let sanitized = reason
                    .replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "\r", with: "")
                    .prefix(100)
                return "DENIED: \(sanitized)"
            }
        }
    }
    
    /// Sanitizes metadata to ensure no PII or sensitive data is logged
    private static func sanitizeAuditMetadata(_ metadata: [String: String]) -> [String: String] {
        let sensitiveKeys = ["password", "token", "key", "secret", "credential", "auth"]
        
        return metadata.reduce(into: [:]) { result, entry in
            let key = entry.key.lowercased()
            let isSensitive = sensitiveKeys.contains { key.contains($0) }
            
            if isSensitive {
                result[entry.key] = "[REDACTED]"
            } else {
                // Sanitize value - remove newlines and limit length
                let sanitized = entry.value
                    .replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "\r", with: "")
                    .prefix(200)
                result[entry.key] = String(sanitized)
            }
        }
    }
    
    /// Returns the URL for the audit log file
    private static var auditLogFileURL: URL {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return URL(fileURLWithPath: "/tmp/tetherflow_audit.log")
        }
        
        let appDirectory = appSupport.appendingPathComponent("TetherFlow", isDirectory: true)
        let logsDirectory = appDirectory.appendingPathComponent("Logs", isDirectory: true)
        
        // Create directories if needed
        try? fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        
        return logsDirectory.appendingPathComponent("audit.log")
    }
    
    /// Writes audit log entry to file with atomic operations
    private static func auditLogToFile(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }
        
        let fileManager = FileManager.default
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        do {
            // Write to temp file atomically
            try data.write(to: tempURL, options: .atomic)
            
            // Append to main audit log
            let auditURL = auditLogFileURL
            
            if fileManager.fileExists(atPath: auditURL.path) {
                // Read existing content
                if let readHandle = try? FileHandle(forReadingFrom: auditURL),
                   let existingData = try? readHandle.readToEnd() {
                    readHandle.closeFile()
                    
                    // Combine and write back
                    var combinedData = existingData
                    combinedData.append(data)
                    try combinedData.write(to: auditURL, options: .atomic)
                }
            } else {
                // First write
                try data.write(to: auditURL, options: .atomic)
            }
            
            // Clean up temp file
            try? fileManager.removeItem(at: tempURL)
            
        } catch {
            // Fallback to OSLog if file writing fails
            os_log("Failed to write audit log: %{public}@", log: auditLogger, type: .error, error.localizedDescription)
        }
    }
    
    /// Rotates audit log if it exceeds maximum size (5MB)
    static func rotateAuditLogIfNeeded(maxSize: UInt64 = 5 * 1024 * 1024) {
        let auditURL = auditLogFileURL
        
        guard FileManager.default.fileExists(atPath: auditURL.path),
              let attributes = try? FileManager.default.attributesOfItem(atPath: auditURL.path),
              let fileSize = attributes[.size] as? UInt64,
              fileSize > maxSize else {
            return
        }
        
        let rotatedURL = auditURL.deletingPathExtension()
            .appendingPathExtension("log.1")
        
        // Remove old rotated log if exists
        try? FileManager.default.removeItem(at: rotatedURL)
        
        // Rotate current log
        try? FileManager.default.moveItem(at: auditURL, to: rotatedURL)
        
        // Log rotation event
        audit(
            action: "audit_log_rotated",
            actor: "system",
            target: "audit.log",
            result: .success,
            metadata: ["previous_size": String(fileSize)]
        )
    }
    
    // MARK: - Private Implementation
    
    private static func log(
        _ message: String,
        level: LogLevel,
        logger: OSLog,
        file: String,
        function: String,
        line: Int
    ) {
        // Check minimum log level
        guard level.rawValue >= minimumLogLevel.rawValue else { return }
        
        // Build source location string
        let sourceLocation: String
        if includeSourceLocation {
            let filename = (file as NSString).lastPathComponent
            sourceLocation = "[\(filename):\(line)]"
        } else {
            sourceLocation = ""
        }
        
        // Build full message
        let fullMessage = sourceLocation.isEmpty ? message : "\(sourceLocation) \(message)"
        
        // Log to OSLog
        let osLogType = level.osLogType
        os_log("%{public}@", log: logger, type: osLogType, fullMessage)
        
        // Also log to console if enabled
        if logToConsole {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let levelString = level.emoji + " " + level.name.uppercased()
            print("[\(timestamp)] \(levelString) \(fullMessage)")
        }
    }
}

// MARK: - Supporting Types

/// Log levels in order of severity
enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case fault = 4
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var name: String {
        switch self {
        case .debug: return "debug"
        case .info: return "info"
        case .warning: return "warning"
        case .error: return "error"
        case .fault: return "fault"
        }
    }
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .fault: return "🚨"
        }
    }
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .fault: return .fault
        }
    }
}

// MARK: - Swift.Error Extension for Logging

extension Swift.Error {
    /// Returns a detailed log-friendly description of the error
    var logDescription: String {
        let errorType = String(describing: type(of: self))
        return "\(errorType): \(self.localizedDescription)"
    }
}
