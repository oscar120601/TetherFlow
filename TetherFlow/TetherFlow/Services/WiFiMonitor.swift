//
//  WiFiMonitor.swift
//  TetherFlow
//
//  Wi-Fi SSID monitoring using CoreWLAN
//

import Foundation
import CoreWLAN
import Combine

class WiFiMonitor: ObservableObject {
    @Published var currentSSID: String?
    @Published var currentInterface: String?
    @Published var isMonitoring: Bool = false
    
    private var wifiClient = CWWiFiClient.shared()
    private var monitorTimer: Timer?
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Monitoring Control
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        // Set up delegate for Wi-Fi events
        wifiClient.delegate = self
        
        do {
            try wifiClient.startMonitoringEvent(with: .ssidDidChange)
            try wifiClient.startMonitoringEvent(with: .linkDidChange)
            isMonitoring = true
            
            // Get initial state
            updateCurrentNetwork()
            
            // Set up periodic check as fallback
            monitorTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
                self?.updateCurrentNetwork()
            }
            
        } catch {
            print("Failed to start Wi-Fi monitoring: \(error)")
        }
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        wifiClient.stopMonitoringAllEvents()
        monitorTimer?.invalidate()
        monitorTimer = nil
        isMonitoring = false
    }
    
    // MARK: - Network Information
    
    private func updateCurrentNetwork() {
        guard let interfaces = wifiClient.interfaces(), !interfaces.isEmpty else {
            currentSSID = nil
            currentInterface = nil
            return
        }
        
        // Use the first Wi-Fi interface (typically en0)
        guard let interface = interfaces.first else { return }
        
        currentInterface = interface.interfaceName
        
        do {
            if let ssidData = try interface.ssidData(),
               let ssid = String(data: ssidData, encoding: .utf8) {
                // Only update if changed
                if currentSSID != ssid {
                    currentSSID = ssid
                }
            } else {
                currentSSID = nil
            }
        } catch {
            print("Failed to get SSID: \(error)")
            currentSSID = nil
        }
    }
    
    // MARK: - Helper Methods
    
    func isConnected() -> Bool {
        return currentSSID != nil
    }
    
    func isConnectedTo(ssid: String) -> Bool {
        return currentSSID == ssid
    }
}

// MARK: - CWEventDelegate

extension WiFiMonitor: CWEventDelegate {
    func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        DispatchQueue.main.async { [weak self] in
            self?.updateCurrentNetwork()
        }
    }
    
    func linkDidChangeForWiFiInterface(withName interfaceName: String) {
        DispatchQueue.main.async { [weak self] in
            self?.updateCurrentNetwork()
        }
    }
}
