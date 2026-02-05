//
//  SessionStore.swift
//  TetherFlow
//
//  Persists cloaking session history for analytics and debugging
//

import Foundation

/// Persists and retrieves cloaking session history
actor SessionStore {
    
    // MARK: - Types
    
    struct SessionRecord: Codable, Identifiable {
        let id: UUID
        let profileId: UUID
        let ssid: String
        let interface: String
        let startTime: Date
        let endTime: Date
        let duration: TimeInterval
        let appliedTTL: Int
        let appliedMTU: Int
        let totalBytesUploaded: UInt64
        let totalBytesDownloaded: UInt64
        let peakUploadSpeed: Double
        let peakDownloadSpeed: Double
        let status: String
        
        init(from session: CloakingSession) {
            self.id = session.id
            self.profileId = session.profileId
            self.ssid = session.ssid
            self.interface = session.interface
            self.startTime = session.startTime
            self.endTime = session.endTime ?? Date()
            self.duration = session.duration
            self.appliedTTL = session.appliedTTL
            self.appliedMTU = session.appliedMTU
            self.totalBytesUploaded = session.metrics.bytesUploaded
            self.totalBytesDownloaded = session.metrics.bytesDownloaded
            self.peakUploadSpeed = session.metrics.peakUploadSpeed
            self.peakDownloadSpeed = session.metrics.peakDownloadSpeed
            self.status = session.status.rawValue
        }
        
        var formattedDuration: String {
            let hours = Int(duration) / 3600
            let minutes = Int(duration) / 60 % 60
            let seconds = Int(duration) % 60
            
            if hours > 0 {
                return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%02d:%02d", minutes, seconds)
            }
        }
        
        var totalDataTransferred: Double {
            Double(totalBytesUploaded + totalBytesDownloaded) / 1_000_000_000
        }
    }
    
    struct SessionStatistics {
        let totalSessions: Int
        let totalDuration: TimeInterval
        let totalDataTransferred: Double
        let averageSessionDuration: TimeInterval
        let averageDataPerSession: Double
        let mostUsedSSID: String?
    }
    
    // MARK: - Properties
    
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "com.tetherflow.sessionHistory"
    private let maxStoredSessions = 100
    
    // MARK: - Public Interface
    
    /// Saves a completed session to history
    func saveSession(_ session: CloakingSession) {
        let record = SessionRecord(from: session)
        
        // Load existing sessions
        var sessions = loadSessionRecords()
        
        // Add new session
        sessions.append(record)
        
        // Keep only the most recent sessions
        if sessions.count > maxStoredSessions {
            sessions = sessions.suffix(maxStoredSessions).sorted { $0.startTime > $1.startTime }
        }
        
        // Save back to UserDefaults
        do {
            let data = try JSONEncoder().encode(sessions)
            userDefaults.set(data, forKey: sessionsKey)
            Logger.info("Session saved to history: \(record.ssid), \(record.formattedDuration), \(String(format: "%.2f", record.totalDataTransferred)) GB")
        } catch {
            Logger.error("Failed to save session: \(error.localizedDescription)")
        }
    }
    
    /// Loads all session history
    func loadSessions() -> [SessionRecord] {
        return loadSessionRecords()
    }
    
    /// Loads recent sessions (last N)
    func loadRecentSessions(limit: Int = 10) -> [SessionRecord] {
        let sessions = loadSessionRecords()
        return Array(sessions.prefix(limit))
    }
    
    /// Loads sessions for a specific profile
    func loadSessions(forProfileId profileId: UUID) -> [SessionRecord] {
        let sessions = loadSessionRecords()
        return sessions.filter { $0.profileId == profileId }
    }
    
    /// Loads sessions for a specific SSID
    func loadSessions(forSSID ssid: String) -> [SessionRecord] {
        let sessions = loadSessionRecords()
        return sessions.filter { $0.ssid == ssid }
    }
    
    /// Loads sessions within a date range
    func loadSessions(from startDate: Date, to endDate: Date) -> [SessionRecord] {
        let sessions = loadSessionRecords()
        return sessions.filter { $0.startTime >= startDate && $0.startTime <= endDate }
    }
    
    /// Calculates statistics for all sessions
    func calculateStatistics() -> SessionStatistics {
        let sessions = loadSessionRecords()
        
        guard !sessions.isEmpty else {
            return SessionStatistics(
                totalSessions: 0,
                totalDuration: 0,
                totalDataTransferred: 0,
                averageSessionDuration: 0,
                averageDataPerSession: 0,
                mostUsedSSID: nil
            )
        }
        
        let totalDuration = sessions.reduce(0) { $0 + $1.duration }
        let totalData = sessions.reduce(0) { $0 + $1.totalDataTransferred }
        
        // Find most used SSID
        let ssidCounts = Dictionary(grouping: sessions, by: { $0.ssid })
            .mapValues { $0.count }
        let mostUsedSSID = ssidCounts.max { $0.value < $1.value }?.key
        
        return SessionStatistics(
            totalSessions: sessions.count,
            totalDuration: totalDuration,
            totalDataTransferred: totalData,
            averageSessionDuration: totalDuration / Double(sessions.count),
            averageDataPerSession: totalData / Double(sessions.count),
            mostUsedSSID: mostUsedSSID
        )
    }
    
    /// Clears all session history
    func clearHistory() {
        userDefaults.removeObject(forKey: sessionsKey)
        Logger.info("Session history cleared")
    }
    
    /// Exports session history as JSON
    func exportToJSON() -> String? {
        let sessions = loadSessionRecords()
        
        do {
            let data = try JSONEncoder().encode(sessions)
            return String(data: data, encoding: .utf8)
        } catch {
            Logger.error("Failed to export sessions: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func loadSessionRecords() -> [SessionRecord] {
        guard let data = userDefaults.data(forKey: sessionsKey) else {
            return []
        }
        
        do {
            let sessions = try JSONDecoder().decode([SessionRecord].self, from: data)
            return sessions.sorted { $0.startTime > $1.startTime }
        } catch {
            Logger.error("Failed to load sessions: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Extensions

extension SessionStore.SessionStatistics {
    /// Formatted total duration
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = Int(totalDuration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Formatted average duration
    var formattedAverageDuration: String {
        let minutes = Int(averageSessionDuration) / 60
        let seconds = Int(averageSessionDuration) % 60
        return "\(minutes)m \(seconds)s"
    }
}
