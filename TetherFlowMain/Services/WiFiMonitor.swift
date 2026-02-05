//
//  WiFiMonitor.swift
//  TetherFlow
//
//  Wi-Fi SSID monitoring using CoreWLAN with enhanced disconnection detection
//

import Foundation
import CoreWLAN
import Combine

/// Enhanced Wi-Fi monitoring with disconnection detection
class WiFiMonitor: ObservableObject {
    
    // MARK: - Types
    
    enum ConnectionState: Equatable {
        case connected(ssid: String, interface: String)
        case disconnected
        case transitioning
        
        var isConnected: Bool {
            if case .connected = self { return true }
            return false
        }
        
        var ssid: String? {
            if case .connected(let ssid, _) = self { return ssid }
            return nil
        }
    }
    
    enum NetworkEvent {
        case ssidChanged(from: String?, to: String?)
        case interfaceChanged(from: String?, to: String?)
        case connectionStateChanged(from: ConnectionState, to: ConnectionState)
        case linkQualityChanged(quality: LinkQuality)
        case powerStateChanged(isPoweredOn: Bool)
    }
    
    enum LinkQuality {
        case excellent  // RSSI > -50
        case good       // RSSI -50 to -60
        case fair       // RSSI -60 to -70
        case poor       // RSSI < -70
        case unknown
    }
    
    // MARK: - Published Properties
    
    @Published var currentSSID: String?
    @Published var currentInterface: String?
    @Published var isMonitoring: Bool = false
    @Published var connectionState: ConnectionState = .disconnected
    @Published var linkQuality: LinkQuality = .unknown
    @Published var isPoweredOn: Bool = true
    
    // MARK: - Callbacks
    
    var onNetworkEvent: ((NetworkEvent) -> Void)?
    var onDisconnection: (() -> Void)?
    var onConnection: ((String, String) -> Void)?
    
    // MARK: - Private Properties
    
    private var wifiClient = CWWiFiClient.shared()
    private var monitorTimer: Timer?
    private var powerMonitor: Any?
    
    // Track previous state for change detection
    private var previousSSID: String?
    private var previousInterface: String?
    private var previousState: ConnectionState = .disconnected
    
    init() {
        setupPowerMonitoring()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
        removePowerMonitoring()
    }
    
    // MARK: - Monitoring Control
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        wifiClient.delegate = self
        
        do {
            // Monitor all relevant Wi-Fi events
            try wifiClient.startMonitoringEvent(with: .ssidDidChange)
            try wifiClient.startMonitoringEvent(with: .linkDidChange)
            try wifiClient.startMonitoringEvent(with: .modeDidChange)
            try wifiClient.startMonitoringEvent(with: .powerDidChange)
            
            isMonitoring = true
            Logger.info("Wi-Fi monitoring started")
            
            // Get initial state
            updateCurrentNetwork()
            
            // Set up periodic check as fallback (more frequent for quick disconnection detection)
            monitorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                self?.updateCurrentNetwork()
            }
            
        } catch {
            Logger.error("Failed to start Wi-Fi monitoring: \(error.localizedDescription)")
        }
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        wifiClient.stopMonitoringAllEvents()
        monitorTimer?.invalidate()
        monitorTimer = nil
        isMonitoring = false
        
        Logger.info("Wi-Fi monitoring stopped")
    }
    
    // MARK: - Power Monitoring
    
    private func setupPowerMonitoring() {
        // Monitor system sleep/wake notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSleepNotification),
            name: NSNotification.Name("NSWorkspaceWillSleepNotification"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWakeNotification),
            name: NSNotification.Name("NSWorkspaceDidWakeNotification"),
            object: nil
        )
    }
    
    private func removePowerMonitoring() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleSleepNotification() {
        Logger.info("System going to sleep")
        
        // Notify about impending disconnection
        if let ssid = currentSSID {
            Logger.info("Connection to \(ssid) will be suspended during sleep")
        }
        
        // Don't immediately mark as disconnected - wait for wake
    }
    
    @objc private func handleWakeNotification() {
        Logger.info("System woke from sleep")
        
        // Check connection state after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.updateCurrentNetwork()
            
            // If we were connected before sleep but not after, trigger disconnection
            if self?.previousState.isConnected == true && self?.connectionState.isConnected == false {
                Logger.info("Connection lost during sleep")
                self?.onDisconnection?()
            }
        }
    }
    
    // MARK: - Network Information
    
    private func updateCurrentNetwork() {
        guard let interfaces = wifiClient.interfaces(), !interfaces.isEmpty else {
            handleNoInterface()
            return
        }
        
        // Find the active Wi-Fi interface
        let activeInterface = interfaces.first { interface in
            guard let power = try? interface.powerOn() else { return false }
            return power
        } ?? interfaces.first
        
        guard let interface = activeInterface else {
            handleNoInterface()
            return
        }
        
        let interfaceName = interface.interfaceName ?? "unknown"
        
        // Check power state
        do {
            let powerOn = try interface.powerOn()
            if isPoweredOn != powerOn {
                isPoweredOn = powerOn
                onNetworkEvent?(.powerStateChanged(isPoweredOn: powerOn))
            }
            
            if !powerOn {
                handleDisconnection(interface: interfaceName)
                return
            }
        } catch {
            Logger.error("Failed to check power state: \(error.localizedDescription)")
        }
        
        // Get SSID
        do {
            if let ssidData = try interface.ssidData(),
               let ssid = String(data: ssidData, encoding: .utf8) {
                
                // Detect changes
                let newState = ConnectionState.connected(ssid: ssid, interface: interfaceName)
                
                if previousSSID != ssid {
                    Logger.info("SSID changed from '\(previousSSID ?? "nil")' to '\(ssid)'")
                    onNetworkEvent?(.ssidChanged(from: previousSSID, to: ssid))
                }
                
                if previousInterface != interfaceName {
                    Logger.info("Interface changed from '\(previousInterface ?? "nil")' to '\(interfaceName)'")
                    onNetworkEvent?(.interfaceChanged(from: previousInterface, to: interfaceName))
                }
                
                if previousState != newState {
                    onNetworkEvent?(.connectionStateChanged(from: previousState, to: newState))
                    
                    // Trigger callbacks
                    if !previousState.isConnected && newState.isConnected {
                        onConnection?(ssid, interfaceName)
                    }
                }
                
                // Update link quality
                updateLinkQuality(for: interface)
                
                // Update state
                previousSSID = ssid
                previousInterface = interfaceName
                previousState = newState
                
                currentSSID = ssid
                currentInterface = interfaceName
                connectionState = newState
                
            } else {
                handleDisconnection(interface: interfaceName)
            }
        } catch {
            Logger.error("Failed to get SSID: \(error.localizedDescription)")
            handleDisconnection(interface: interfaceName)
        }
    }
    
    private func handleNoInterface() {
        if connectionState != .disconnected {
            Logger.info("No Wi-Fi interface available")
            
            let oldState = connectionState
            connectionState = .disconnected
            
            if oldState.isConnected {
                onNetworkEvent?(.connectionStateChanged(from: oldState, to: .disconnected))
                onDisconnection?()
            }
            
            previousState = .disconnected
            previousSSID = nil
            previousInterface = nil
        }
        
        currentSSID = nil
        currentInterface = nil
        linkQuality = .unknown
    }
    
    private func handleDisconnection(interface: String) {
        guard connectionState.isConnected else { return }
        
        Logger.info("Disconnected from '\(previousSSID ?? "unknown")' on \(interface)")
        
        let oldState = connectionState
        connectionState = .disconnected
        currentSSID = nil
        linkQuality = .unknown
        
        onNetworkEvent?(.connectionStateChanged(from: oldState, to: .disconnected))
        onDisconnection?()
        
        previousState = .disconnected
        previousSSID = nil
    }
    
    private func updateLinkQuality(for interface: CWInterface) {
        do {
            if let rssi = try interface.rssiValue() {
                let newQuality: LinkQuality
                switch rssi {
                case -50...0:
                    newQuality = .excellent
                case -60..<(-50):
                    newQuality = .good
                case -70..<(-60):
                    newQuality = .fair
                default:
                    newQuality = .poor
                }
                
                if linkQuality != newQuality {
                    linkQuality = newQuality
                    onNetworkEvent?(.linkQualityChanged(quality: newQuality))
                }
            }
        } catch {
            linkQuality = .unknown
        }
    }
    
    // MARK: - Public Methods
    
    func isConnected() -> Bool {
        return connectionState.isConnected
    }
    
    func isConnectedTo(ssid: String) -> Bool {
        return currentSSID == ssid
    }
    
    func getConnectionInfo() -> (ssid: String?, interface: String?, quality: LinkQuality) {
        return (currentSSID, currentInterface, linkQuality)
    }
    
    /// Forces an immediate network state check
    func forceUpdate() {
        updateCurrentNetwork()
    }
}

// MARK: - CWEventDelegate

extension WiFiMonitor: CWEventDelegate {
    func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        Logger.debug("SSID did change for interface \(interfaceName)")
        DispatchQueue.main.async { [weak self] in
            self?.updateCurrentNetwork()
        }
    }
    
    func linkDidChangeForWiFiInterface(withName interfaceName: String) {
        Logger.debug("Link did change for interface \(interfaceName)")
        DispatchQueue.main.async { [weak self] in
            self?.updateCurrentNetwork()
        }
    }
    
    func modeDidChangeForWiFiInterface(withName interfaceName: String) {
        Logger.debug("Mode did change for interface \(interfaceName)")
        DispatchQueue.main.async { [weak self] in
            self?.updateCurrentNetwork()
        }
    }
    
    func powerDidChangeForWiFiInterface(withName interfaceName: String) {
        Logger.debug("Power did change for interface \(interfaceName)")
        DispatchQueue.main.async { [weak self] in
            self?.updateCurrentNetwork()
        }
    }
}
