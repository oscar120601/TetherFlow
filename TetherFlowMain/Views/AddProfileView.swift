//
//  AddProfileView.swift
//  TetherFlow
//
//  Add new hotspot profile UI
//

import SwiftUI

struct AddProfileView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var ssid = ""
    @State private var targetTTL = 65
    @State private var targetMTU = 1400
    @State private var autoActivate = true
    @State private var enableTrafficShaping = true
    @State private var useEncryptedDNS = true
    @State private var hourlyDataThreshold = 10.0
    @State private var dailyDataThreshold = 50.0
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var isValid: Bool {
        !ssid.isEmpty &&
        ssid.count <= 32 &&
        targetTTL >= 64 && targetTTL <= 255 &&
        targetMTU >= 1280 && targetMTU <= 1500 &&
        !isDuplicateSSID
    }
    
    private var isDuplicateSSID: Bool {
        appState.profiles.contains { $0.ssid == ssid }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Hotspot Information") {
                    TextField("Hotspot Name (SSID)", text: $ssid)
                        .autocorrectionDisabled()
                    
                    if isDuplicateSSID {
                        Text("A profile with this SSID already exists")
                            .font(.caption)
                            .foregroundColor(.red)
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
                } footer: {
                    Text("TTL of 65 ensures packets arrive at ISP as 64 (mobile device standard).")
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
                } footer: {
                    Text("Alerts appear when data usage exceeds these thresholds.")
                }
            }
            .navigationTitle("Add Hotspot")
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
                    .disabled(!isValid)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
        .frame(width: 400, height: 500)
    }
    
    private func saveProfile() {
        let profile = HotspotProfile(
            ssid: ssid.trimmingCharacters(in: .whitespacesAndNewlines),
            targetTTL: targetTTL,
            targetMTU: targetMTU,
            autoActivate: autoActivate,
            enableTrafficShaping: enableTrafficShaping,
            hourlyDataThreshold: hourlyDataThreshold,
            dailyDataThreshold: dailyDataThreshold,
            useEncryptedDNS: useEncryptedDNS
        )
        
        if profile.isValid {
            appState.saveProfile(profile)
            dismiss()
        } else {
            errorMessage = profile.validationErrors.joined(separator: "\n")
            showingError = true
        }
    }
}

// MARK: - Preview

struct AddProfileView_Previews: PreviewProvider {
    static var previews: some View {
        AddProfileView(appState: AppState())
    }
}
