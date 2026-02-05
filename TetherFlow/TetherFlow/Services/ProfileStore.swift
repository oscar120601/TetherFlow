//
//  ProfileStore.swift
//  TetherFlow
//
//  Persistence layer for hotspot profiles using UserDefaults
//

import Foundation

class ProfileStore {
    private let userDefaults = UserDefaults.standard
    private let profilesKey = "com.tetherflow.profiles"
    
    // MARK: - CRUD Operations
    
    func loadProfiles() -> [HotspotProfile] {
        guard let data = userDefaults.data(forKey: profilesKey),
              let profiles = try? JSONDecoder().decode([HotspotProfile].self, from: data) else {
            return []
        }
        return profiles
    }
    
    func saveProfile(_ profile: HotspotProfile) {
        var profiles = loadProfiles()
        
        // Check if profile already exists
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
        
        saveProfiles(profiles)
    }
    
    func deleteProfile(_ profile: HotspotProfile) {
        var profiles = loadProfiles()
        profiles.removeAll { $0.id == profile.id }
        saveProfiles(profiles)
    }
    
    func getProfile(byID id: UUID) -> HotspotProfile? {
        loadProfiles().first { $0.id == id }
    }
    
    func getProfile(bySSID ssid: String) -> HotspotProfile? {
        loadProfiles().first { $0.ssid == ssid }
    }
    
    // MARK: - Validation
    
    func isDuplicateSSID(_ ssid: String, excluding profileID: UUID? = nil) -> Bool {
        let profiles = loadProfiles()
        return profiles.contains { profile in
            profile.ssid == ssid && profile.id != profileID
        }
    }
    
    // MARK: - Private Helpers
    
    private func saveProfiles(_ profiles: [HotspotProfile]) {
        if let data = try? JSONEncoder().encode(profiles) {
            userDefaults.set(data, forKey: profilesKey)
        }
    }
}
