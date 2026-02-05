//
//  ProfileListView.swift
//  TetherFlow
//
//  Hotspot profile management UI
//

import SwiftUI

struct ProfileListView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddProfile = false
    @State private var editingProfile: HotspotProfile?
    @State private var profileToDelete: HotspotProfile?
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if appState.profiles.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(appState.profiles) { profile in
                            ProfileRowView(profile: profile)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingProfile = profile
                                }
                                .contextMenu {
                                    Button("Edit") {
                                        editingProfile = profile
                                    }
                                    Button("Delete", role: .destructive) {
                                        profileToDelete = profile
                                    }
                                }
                        }
                        .onDelete(perform: deleteProfiles)
                    }
                } header: {
                    Text("Configured Hotspots")
                } footer: {
                    Text("Add your mobile hotspot SSIDs. TetherFlow will automatically detect and cloak when connected.")
                }
            }
            .navigationTitle("Hotspot Profiles")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddProfile = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProfile) {
                AddProfileView(appState: appState)
            }
            .sheet(item: $editingProfile) { profile in
                EditProfileView(appState: appState, profile: profile)
            }
            .alert("Delete Profile?", isPresented: .constant(profileToDelete != nil), presenting: profileToDelete) { profile in
                Button("Cancel", role: .cancel) {
                    profileToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    appState.deleteProfile(profile)
                    profileToDelete = nil
                }
            } message: { profile in
                Text("Are you sure you want to delete the profile for '\(profile.ssid)'?")
            }
        }
        .frame(width: 480, height: 400)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Hotspot Profiles")
                .font(.headline)
            
            Text("Add your first mobile hotspot to get started with network cloaking.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Hotspot") {
                showingAddProfile = true
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .padding()
    }
    
    private func deleteProfiles(at offsets: IndexSet) {
        for index in offsets {
            let profile = appState.profiles[index]
            appState.deleteProfile(profile)
        }
    }
}

// MARK: - Profile Row

struct ProfileRowView: View {
    let profile: HotspotProfile
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.ssid)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Label("TTL: \(profile.targetTTL)", systemImage: "number")
                        .font(.caption)
                    
                    Label("MTU: \(profile.targetMTU)", systemImage: "arrow.up.arrow.down")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if profile.autoActivate {
                    Label("Auto", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                if profile.enableTrafficShaping {
                    Label("Shape", systemImage: "waveform")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct ProfileListView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        
        // Add sample profiles for preview
        appState.profiles = [
            HotspotProfile.sample,
            HotspotProfile(ssid: "OfficeWiFi", autoActivate: false)
        ]
        
        return ProfileListView(appState: appState)
    }
}
