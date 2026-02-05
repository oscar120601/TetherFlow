//
//  HotspotProfile.swift
//  TetherFlow
//
//  Configuration model for hotspot cloaking profiles
//

import Foundation

struct HotspotProfile: Codable, Identifiable, Equatable {
    let id: UUID
    let ssid: String
    var targetTTL: Int
    var targetMTU: Int
    var autoActivate: Bool
    var enableTrafficShaping: Bool
    var hourlyDataThreshold: Double
    var dailyDataThreshold: Double
    var useEncryptedDNS: Bool
    var dnsProvider: DNSProvider
    let createdAt: Date
    var lastModified: Date
    
    enum DNSProvider: String, Codable, CaseIterable {
        case cloudflare = "cloudflare"
        case quad9 = "quad9"
    }
    
    init(
        id: UUID = UUID(),
        ssid: String,
        targetTTL: Int = 65,
        targetMTU: Int = 1400,
        autoActivate: Bool = true,
        enableTrafficShaping: Bool = true,
        hourlyDataThreshold: Double = 10.0,
        dailyDataThreshold: Double = 50.0,
        useEncryptedDNS: Bool = true,
        dnsProvider: DNSProvider = .cloudflare,
        createdAt: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.ssid = ssid
        self.targetTTL = targetTTL
        self.targetMTU = targetMTU
        self.autoActivate = autoActivate
        self.enableTrafficShaping = enableTrafficShaping
        self.hourlyDataThreshold = hourlyDataThreshold
        self.dailyDataThreshold = dailyDataThreshold
        self.useEncryptedDNS = useEncryptedDNS
        self.dnsProvider = dnsProvider
        self.createdAt = createdAt
        self.lastModified = lastModified
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        !ssid.isEmpty &&
        ssid.count <= 32 &&
        targetTTL >= 64 && targetTTL <= 255 &&
        targetMTU >= 1280 && targetMTU <= 1500 &&
        hourlyDataThreshold > 0 &&
        dailyDataThreshold > 0
    }
    
    var validationErrors: [String] {
        var errors: [String] = []
        
        if ssid.isEmpty {
            errors.append("SSID cannot be empty")
        }
        if ssid.count > 32 {
            errors.append("SSID must be 32 characters or less")
        }
        if targetTTL < 64 || targetTTL > 255 {
            errors.append("TTL must be between 64 and 255")
        }
        if targetMTU < 1280 || targetMTU > 1500 {
            errors.append("MTU must be between 1280 and 1500")
        }
        if hourlyDataThreshold <= 0 {
            errors.append("Hourly threshold must be greater than 0")
        }
        if dailyDataThreshold <= 0 {
            errors.append("Daily threshold must be greater than 0")
        }
        
        return errors
    }
}

// MARK: - Sample Data

extension HotspotProfile {
    static var sample: HotspotProfile {
        HotspotProfile(
            ssid: "MyUnlimited5G",
            targetTTL: 65,
            targetMTU: 1400,
            autoActivate: true,
            enableTrafficShaping: true,
            hourlyDataThreshold: 10.0,
            dailyDataThreshold: 50.0,
            useEncryptedDNS: true,
            dnsProvider: .cloudflare
        )
    }
}
