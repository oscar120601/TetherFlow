//
//  AppState.swift
//  TetherFlow
//
//  Global application state management with CloakingEngine integration
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
    @Published var isHelperInstalled: Bool = false
    
    // MARK: - Services
    
    private var profileStore = ProfileStore()
    private var wifiMonitor: WiFiMonitor?
    private var networkConfigurator = NetworkConfigurator()
    private var cloakingEngine = CloakingEngine()
    private var helperInstaller = HelperInstaller()
    private var reversionVerifier = ReversionVerifier()
    private var metricsCollector: MetricsCollector?
    private var sessionStore = SessionStore()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - State Tracking
    
    @Published var lastReversionResult: ReversionVerifier.ReversionResult?
    
    // MARK: - Initialization
    
    init() {
        loadProfiles()
        setupWiFiMonitoring()
        checkHelperInstallation()
    }
    
    // MARK: - Profile Management
    
    func loadProfiles() {
        profiles = profileStore.loadProfiles()
        Logger.info("Loaded \(profiles.count) profiles")
    }
    
    func saveProfile(_ profile: HotspotProfile) {
        let isValid = profile.isValid
        guard isValid else {
            lastError = AppError(
                code: .invalidConfiguration,
                message: profile.validationErrors.joined(separator: ", ")
            )
            return
        }
        
        profileStore.saveProfile(profile)
        loadProfiles()
        Logger.info("Saved profile for \(profile.ssid)")
    }
    
    func deleteProfile(_ profile: HotspotProfile) {
        profileStore.deleteProfile(profile)
        loadProfiles()
        Logger.info("Deleted profile for \(profile.ssid)")
    }
    
    // MARK: - Helper Installation
    
    func checkHelperInstallation() {
        Task {
            let installed = await helperInstaller.isHelperInstalled()
            await MainActor.run {
                self.isHelperInstalled = installed
            }
        }
    }
    
    func installHelper() async throws -> Bool {
        Logger.info("Attempting to install helper...")
        let success = try await helperInstaller.installHelper()
        await MainActor.run {
            self.isHelperInstalled = success
        }
        return success
    }
    
    // MARK: - Wi-Fi Monitoring
    
    private func setupWiFiMonitoring() {
        wifiMonitor = WiFiMonitor()
        
        // Set up disconnection callback
        wifiMonitor?.onDisconnection = { [weak self] in
            Task { @MainActor in
                self?.handleDisconnection()
            }
        }
        
        // Set up connection callback
        wifiMonitor?.onConnection = { [weak self] ssid, interface in
            Task { @MainActor in
                self?.handleConnection(ssid: ssid, interface: interface)
            }
        }
        
        // Monitor network events
        wifiMonitor?.onNetworkEvent = { [weak self] event in
            Task { @MainActor in
                self?.handleNetworkEvent(event)
            }
        }
        
        wifiMonitor?.$currentSSID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ssid in
                self?.currentSSID = ssid
            }
            .store(in: &cancellables)
        
        wifiMonitor?.$currentInterface
            .receive(on: DispatchQueue.main)
            .sink { [weak self] interface in
                self?.currentInterface = interface
            }
            .store(in: &cancellables)
        
        isMonitoringEnabled = wifiMonitor?.isMonitoring ?? false
    }
    
    private func handleDisconnection() {
        Logger.info("Wi-Fi disconnection detected")
        
        guard activeSession != nil else {
            Logger.debug("No active session to deactivate")
            return
        }
        
        // Deactivate cloaking with verification
        deactivateCloakingWithVerification()
    }
    
    private func handleConnection(ssid: String, interface: String) {
        Logger.info("Wi-Fi connection detected: \(ssid) on \(interface)")
        
        // Check if we should auto-activate
        if let profile = profiles.first(where: { $0.ssid == ssid }),
           profile.autoActivate {
            Logger.info("Auto-activating cloaking for \(ssid)")
            activateCloaking(profile: profile)
        }
    }
    
    private func handleNetworkEvent(_ event: WiFiMonitor.NetworkEvent) {
        switch event {
        case .ssidChanged(let from, let to):
            Logger.info("SSID changed from '\(from ?? "nil")' to '\(to ?? "nil")'")
            
            // If SSID changed from a known profile to something else, deactivate
            if let fromSSID = from,
               profiles.contains(where: { $0.ssid == fromSSID }),
               activeSession != nil {
                Logger.info("Switched away from configured hotspot, deactivating")
                deactivateCloakingWithVerification()
            }
            
        case .interfaceChanged(let from, let to):
            Logger.info("Interface changed from '\(from ?? "nil")' to '\(to ?? "nil")'")
            
            // Update metrics collector if active
            if let newInterface = to {
                Task {
                    await metricsCollector?.setInterface(newInterface)
                }
            }
            
        case .connectionStateChanged(let from, let to):
            Logger.info("Connection state changed from \(from) to \(to)")
            
        case .linkQualityChanged(let quality):
            Logger.debug("Link quality changed to \(quality)")
            
        case .powerStateChanged(let isPoweredOn):
            Logger.info("Wi-Fi power state changed to \(isPoweredOn ? "on" : "off")")
            
            if !isPoweredOn && activeSession != nil {
                Logger.info("Wi-Fi powered off, deactivating cloaking")
                deactivateCloakingWithVerification()
            }
        }
    }
    
    // MARK: - Cloaking Control
    
    func activateCloaking(profile: HotspotProfile) {
        guard status != .cloakingActive else {
            Logger.warning("Cloaking is already active")
            return
        }
        
        guard isHelperInstalled else {
            lastError = AppError(
                code: .helperNotAvailable,
                message: "Helper tool is not installed. Please install it first."
            )
            status = .error
            return
        }
        
        status = .activating
        Logger.info("Activating cloaking for \(profile.ssid)")
        
        Task {
            do {
                let session = try await cloakingEngine.activate(
                    profile: profile,
                    interface: currentInterface ?? "en0"
                )
                
                // Start metrics collection
                let collector = MetricsCollector(interface: session.interface)
                self.metricsCollector = collector
                await collector.startCollecting()
                
                await MainActor.run {
                    self.activeSession = session
                    self.status = .cloakingActive
                    self.lastError = nil
                    Logger.info("Cloaking activated successfully")
                }
            } catch let error as CloakingError {
                await MainActor.run {
                    self.handleCloakingError(error)
                }
            } catch {
                await MainActor.run {
                    self.status = .error
                    self.lastError = AppError(
                        code: .unknown,
                        message: error.localizedDescription
                    )
                    Logger.error("Unexpected error during activation: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func deactivateCloaking() {
        deactivateCloakingWithVerification(verify: false)
    }
    
    func deactivateCloakingWithVerification(verify: Bool = true) {
        guard let session = activeSession else {
            Logger.warning("No active session to deactivate")
            return
        }
        
        status = .reverting
        Logger.info("Deactivating cloaking...")
        
        // Stop metrics collection
        Task {
            await metricsCollector?.stopCollecting()
            metricsCollector = nil
        }
        
        Task {
            do {
                try await cloakingEngine.deactivate()
                
                // Save session data before clearing
                await persistSession(session)
                
                var reversionSuccess = true
                
                // Verify reversion if requested
                if verify {
                    let result = await reversionVerifier.verifyReversion(
                        interface: session.interface,
                        maxRetries: 3
                    )
                    
                    await MainActor.run {
                        self.lastReversionResult = result
                    }
                    
                    if !result.success {
                        Logger.warning("Reversion verification failed: \(result.detailedErrorMessage)")
                        
                        // Attempt force restore
                        let forceRestored = await reversionVerifier.forceRestore(interface: session.interface)
                        reversionSuccess = forceRestored
                        
                        if !forceRestored {
                            Logger.fault("Force restore also failed!")
                        }
                    } else {
                        Logger.info("Reversion verified successfully")
                    }
                }
                
                await MainActor.run {
                    self.activeSession = nil
                    self.status = reversionSuccess ? .idle : .error
                    self.lastError = reversionSuccess ? nil : AppError(
                        code: .reversionFailed,
                        message: "Failed to restore network settings"
                    )
                    
                    if reversionSuccess {
                        Logger.info("Cloaking deactivated successfully")
                    }
                }
            } catch let error as CloakingError {
                await MainActor.run {
                    self.handleCloakingError(error)
                }
            } catch {
                await MainActor.run {
                    self.status = .error
                    self.lastError = AppError(
                        code: .unknown,
                        message: error.localizedDescription
                    )
                    Logger.error("Unexpected error during deactivation: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func persistSession(_ session: CloakingSession) async {
        // Complete the session first
        session.complete()
        
        // Save to session store
        await sessionStore.saveSession(session)
        
        Logger.info("Session persisted: \(session.ssid), duration: \(session.formattedDuration), data: \(session.metrics.totalGBTransferred) GB")
    }
    
    func activateKillSwitch() {
        Logger.fault("KILL SWITCH ACTIVATED by user")
        
        Task {
            await cloakingEngine.emergencyDeactivate()
            
            await MainActor.run {
                self.activeSession = nil
                self.status = .idle
                Logger.info("Kill switch completed")
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func handleCloakingError(_ error: CloakingError) {
        self.status = .error
        
        let errorCode: AppError.ErrorCode
        let message: String
        
        switch error {
        case .alreadyProcessing:
            errorCode = .alreadyProcessing
            message = "Cloaking operation already in progress"
        case .alreadyActive:
            errorCode = .alreadyActive
            message = "Cloaking is already active"
        case .helperNotAvailable:
            errorCode = .helperNotAvailable
            message = "Helper tool not available. Please install it."
            isHelperInstalled = false
        case .verificationFailed:
            errorCode = .verificationFailed
            message = "Failed to verify cloaking settings"
        case .deactivationFailed(let underlyingError):
            errorCode = .deactivationFailed
            message = "Deactivation failed: \(underlyingError.localizedDescription)"
        case .underlying(let underlyingError):
            errorCode = .unknown
            message = underlyingError.localizedDescription
        }
        
        self.lastError = AppError(code: errorCode, message: message)
        Logger.error("Cloaking error [\(errorCode)]: \(message)")
    }
    
    func clearError() {
        lastError = nil
        if status == .error {
            status = activeSession?.isActive == true ? .cloakingActive : .idle
        }
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
        case helperNotAvailable = "helper_not_available"
        case verificationFailed = "verification_failed"
        case alreadyProcessing = "already_processing"
        case alreadyActive = "already_active"
        case deactivationFailed = "deactivation_failed"
        case invalidConfiguration = "invalid_configuration"
        case reversionFailed = "reversion_failed"
        case unknown = "unknown"
    }
}
