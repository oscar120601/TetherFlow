//
//  AppState.swift
//  TetherFlow
//
//  Global application state management
//

import Foundation
import Combine

class AppState: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isMonitoringEnabled: Bool = false
    @Published var currentSSID: String?
    @Published var currentInterface: String?
    @Published var activeSession: CloakingSession?
    @Published var status: AppStatus = .idle
    @Published var lastError: AppError?
    @Published var profiles: [HotspotProfile] = []
    
    // MARK: - Services
    
    private var profileStore = ProfileStore()
    private var wifiMonitor: WiFiMonitor?
    private var networkConfigurator = NetworkConfigurator()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        loadProfiles()
        setupWiFiMonitoring()
    }
    
    // MARK: - Profile Management
    
    func loadProfiles() {
        profiles = profileStore.loadProfiles()
    }
    
    func saveProfile(_ profile: HotspotProfile) {
        profileStore.saveProfile(profile)
        loadProfiles()
    }
    
    func deleteProfile(_ profile: HotspotProfile) {
        profileStore.deleteProfile(profile)
        loadProfiles()
    }
    
    // MARK: - Wi-Fi Monitoring
    
    private func setupWiFiMonitoring() {
        wifiMonitor = WiFiMonitor()
        wifiMonitor?.$currentSSID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ssid in
                self?.handleSSIDChange(ssid)
            }
            .store(in: &cancellables)
    }
    
    private func handleSSIDChange(_ ssid: String?) {
        currentSSID = ssid
        
        // Check if we should activate cloaking
        if let ssid = ssid,
           let profile = profiles.first(where: { $0.ssid == ssid }),
           profile.autoActivate {
            activateCloaking(profile: profile)
        } else if activeSession != nil {
            // Disconnected from hotspot - revert
            deactivateCloaking()
        }
    }
    
    // MARK: - Cloaking Control
    
    func activateCloaking(profile: HotspotProfile) {
        guard status != .cloakingActive else { return }
        
        status = .activating
        
        Task {
            do {
                try await networkConfigurator.applyCloaking(profile: profile)
                
                await MainActor.run {
                    let session = CloakingSession(
                        profileId: profile.id,
                        ssid: profile.ssid,
                        interface: currentInterface ?? "en0",
                        appliedTTL: profile.targetTTL,
                        appliedMTU: profile.targetMTU
                    )
                    self.activeSession = session
                    self.status = .cloakingActive
                }
            } catch {
                await MainActor.run {
                    self.status = .error
                    self.lastError = AppError(
                        code: .ttlModificationFailed,
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
    
    func deactivateCloaking() {
        guard let session = activeSession else { return }
        
        status = .reverting
        
        Task {
            do {
                try await networkConfigurator.resetNetworkSettings(interface: session.interface)
                
                await MainActor.run {
                    self.activeSession = nil
                    self.status = .idle
                }
            } catch {
                await MainActor.run {
                    self.status = .error
                    self.lastError = AppError(
                        code: .unknown,
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
    
    func activateKillSwitch() {
        deactivateCloaking()
    }
}

// MARK: - Enums

enum AppStatus: String, Codable {
    case idle = "idle"
    case scanning = "scanning"
    case activating = "activating"
    case cloakingActive = "cloakingActive"
    case reverting = "reverting"
    case error = "error"
}

struct AppError {
    let code: ErrorCode
    let message: String
    let timestamp: Date = Date()
    
    enum ErrorCode: String {
        case invalidSSID = "invalid_ssid"
        case profileNotFound = "profile_not_found"
        case ttlModificationFailed = "ttl_modification_failed"
        case mtuModificationFailed = "mtu_modification_failed"
        case unknown = "unknown"
    }
}
