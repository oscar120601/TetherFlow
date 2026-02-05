//
//  EditProfileView.swift
//  TetherFlow
//
//  Edit existing hotspot profile UI
//

import SwiftUI

struct EditProfileView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let profile: HotspotProfile
    
    @State private var targetTTL: Int
    @State private var targetMTU: Int
    @State private var autoActivate: Bool
    @State private var enableTrafficShaping: Bool
    @State private var useEncryptedDNS: Bool
    @State private var hourlyDataThreshold: Double
    @State private var dailyDataThreshold: Double
    
    @State private var showingDeleteConfirmation = false
    
    init(appState: AppState, profile: HotspotProfile) {
        self.appState = appState
        self.profile = profile
        
        _targetTTL = State(initialValue: profile.targetTTL)
        _targetMTU = State(initialValue: profile.targetMTU)
        _autoActivate = State(initialValue: profile.autoActivate)
        _enableTrafficShaping = State(initialValue: profile.enableTrafficShaping)
        _useEncryptedDNS = State(initialValue: profile.useEncryptedDNS)
        _hourlyDataThreshold = State(initialValue: profile.hourlyDataThreshold)
        _dailyDataThreshold = State(initialValue: profile.dailyDataThreshold)
    }
    
    private var isValid: Bool {
        targetTTL >= 64 && targetTTL <= 255 &&
        targetMTU >= 1280 && targetMTU <= 1500 &&
        hourlyDataThreshold > 0 &&
        dailyDataThreshold > 0
    }
    
    private var hasChanges: Bool {
        targetTTL != profile.targetTTL ||
        targetMTU != profile.targetMTU ||
        autoActivate != profile.autoActivate ||
        enableTrafficShaping != profile.enableTrafficShaping ||
        useEncryptedDNS != profile.useEncryptedDNS ||
        hourlyDataThreshold != profile.hourlyDataThreshold ||
        dailyDataThreshold != profile.dailyDataThreshold
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Hotspot Information") {
                    HStack {
                        Text("SSID")
                        Spacer()
                        Text(profile.ssid)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(profile.createdAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Network Cloaking") {
                    HStack {
                        Text("TTL")
                        Spacer()
                        TextField("65", value: $targetTTL, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    
                    HStack {
                        Text("MTU")
                        Spacer()
                        TextField("1400", value: $targetMTU, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    
                    Toggle("Auto-activate", isOn: $autoActivate)
                    Toggle("Traffic Shaping", isOn: $enableTrafficShaping)
                    Toggle("Encrypted DNS", isOn: $useEncryptedDNS)
                }
                
                Section("Safety Thresholds") {
                    HStack {
                        Text("Hourly Limit")
                        Spacer()
                        TextField("10", value: $hourlyDataThreshold, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("GB")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Daily Limit")
                        Spacer()
                        TextField("50", value: $dailyDataThreshold, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("GB")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("Delete Profile", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                }
            }
            .navigationTitle("Edit Hotspot")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(!isValid || !hasChanges)
                }
            }
            .alert("Delete Profile?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteProfile()
                }
            } message: {
                Text("Are you sure you want to delete the profile for '\(profile.ssid)'? This action cannot be undone.")
            }
        }
        .frame(width: 400, height: 520)
    }
    
    private func saveProfile() {
        var updatedProfile = profile
        updatedProfile.targetTTL = targetTTL
        updatedProfile.targetMTU = targetMTU
        updatedProfile.autoActivate = autoActivate
        updatedProfile.enableTrafficShaping = enableTrafficShaping
        updatedProfile.useEncryptedDNS = useEncryptedDNS
        updatedProfile.hourlyDataThreshold = hourlyDataThreshold
        updatedProfile.dailyDataThreshold = dailyDataThreshold
        updatedProfile.lastModified = Date()
        
        if updatedProfile.isValid {
            appState.saveProfile(updatedProfile)
            dismiss()
        }
    }
    
    private func deleteProfile() {
        appState.deleteProfile(profile)
        dismiss()
    }
}

// MARK: - Preview

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView(appState: AppState(), profile: HotspotProfile.sample)
    }
}
