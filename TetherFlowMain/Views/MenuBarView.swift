//
//  MenuBarView.swift
//  TetherFlow
//
//  Menu bar extra UI with status indicator and quick actions
//

import SwiftUI

/// Main menu bar view for TetherFlow
struct MenuBarView: View {
    @StateObject private var appState = AppState()
    @State private var showingProfileList = false
    @State private var showingDashboard = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Status header with icon and current state
            StatusHeaderSection(appState: appState)
            
            Divider()
            
            // Quick connection info
            ConnectionInfoSection(appState: appState)
            
            Divider()
            
            // Quick actions
            QuickActionsSection(
                appState: appState,
                showingProfileList: $showingProfileList,
                showingDashboard: $showingDashboard
            )
            
            Divider()
            
            // Profile selector
            ProfileSelectorSection(appState: appState)
            
            Divider()
            
            // Footer with kill switch and quit
            FooterSection(appState: appState)
        }
        .frame(width: 320)
        .sheet(isPresented: $showingProfileList) {
            ProfileListView(appState: appState)
        }
        .sheet(isPresented: $showingDashboard) {
            DashboardView(appState: appState)
        }
    }
}

// MARK: - Status Header Section

struct StatusHeaderSection: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 12) {
            // Animated status icon
            StatusIconView(status: appState.status)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("TetherFlow")
                    .font(.system(size: 15, weight: .semibold))
                
                Text(statusDescription)
                    .font(.system(size: 11))
                    .foregroundColor(statusColor)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.windowBackgroundColor))
    }
    
    private var statusDescription: String {
        switch appState.status {
        case .idle:
            return "Ready"
        case .scanning:
            return "Scanning..."
        case .cloakingActive:
            return "Cloaking Active"
        case .reverting:
            return "Reverting..."
        case .error:
            return "Error - Check Settings"
        }
    }
    
    private var statusColor: Color {
        switch appState.status {
        case .idle, .scanning:
            return .secondary
        case .cloakingActive:
            return .green
        case .reverting:
            return .orange
        case .error:
            return .red
        }
    }
}

// MARK: - Status Icon View

struct StatusIconView: View {
    let status: AppStatus
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(statusBackgroundColor)
                .frame(width: 32, height: 32)
            
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .rotationEffect(status == .scanning ? Angle(degrees: isAnimating ? 360 : 0) : .zero)
                .animation(
                    status == .scanning ? 
                        Animation.linear(duration: 2).repeatForever(autoreverses: false) : 
                        .default,
                    value: isAnimating
                )
        }
        .onAppear {
            if status == .scanning {
                isAnimating = true
            }
        }
        .onChange(of: status) { newStatus in
            isAnimating = (newStatus == .scanning)
        }
    }
    
    private var iconName: String {
        switch status {
        case .idle:
            return "antenna.radiowaves.left.and.right"
        case .scanning:
            return "antenna.radiowaves.left.and.right"
        case .cloakingActive:
            return "checkmark.shield.fill"
        case .reverting:
            return "arrow.uturn.backward"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var iconColor: Color {
        switch status {
        case .idle, .scanning:
            return .primary
        case .cloakingActive:
            return .white
        case .reverting:
            return .white
        case .error:
            return .white
        }
    }
    
    private var statusBackgroundColor: Color {
        switch status {
        case .idle, .scanning:
            return Color(.controlBackgroundColor)
        case .cloakingActive:
            return .green
        case .reverting:
            return .orange
        case .error:
            return .red
        }
    }
}

// MARK: - Connection Info Section

struct ConnectionInfoSection: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Current Network")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                Image(systemName: appState.currentSSID != nil ? "wifi" : "wifi.slash")
                    .foregroundColor(.secondary)
                
                Text(appState.currentSSID ?? "Not connected")
                    .font(.system(size: 13))
                    .lineLimit(1)
                
                Spacer()
                
                if appState.status == .cloakingActive {
                    CloakingBadge()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct CloakingBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "shield.fill")
                .font(.system(size: 8))
            Text("CLOAKED")
                .font(.system(size: 8, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.green)
        .cornerRadius(4)
    }
}

// MARK: - Quick Actions Section

struct QuickActionsSection: View {
    @ObservedObject var appState: AppState
    @Binding var showingProfileList: Bool
    @Binding var showingDashboard: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                showingDashboard = true
            } label: {
                HStack {
                    Image(systemName: "gauge.with.dots.needle.67percent")
                    Text("Open Dashboard")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(MenuBarButtonStyle())
            
            Button {
                showingProfileList = true
            } label: {
                HStack {
                    Image(systemName: "list.bullet")
                    Text("Manage Profiles")
                    Spacer()
                    Text("\(appState.profiles.count)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(MenuBarButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Profile Selector Section

struct ProfileSelectorSection: View {
    @ObservedObject var appState: AppState
    @State private var selectedProfileId: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Quick Select")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            if appState.profiles.isEmpty {
                Text("No profiles configured")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 2) {
                    ForEach(appState.profiles.prefix(3)) { profile in
                        ProfileMenuItem(
                            profile: profile,
                            isActive: appState.currentSSID == profile.ssid && appState.status == .cloakingActive,
                            action: {
                                // If connected to this network, ensure cloaking is active
                                if appState.currentSSID == profile.ssid {
                                    if appState.status != .cloakingActive {
                                        appState.activateCloaking(profile: profile)
                                    }
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct ProfileMenuItem: View {
    let profile: HotspotProfile
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isActive ? .green : .secondary)
                    .font(.system(size: 12))
                
                Text(profile.ssid)
                    .font(.system(size: 12))
                    .lineLimit(1)
                
                Spacer()
                
                if profile.autoActivate {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.orange)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isActive ? Color.green.opacity(0.1) : Color.clear)
        .cornerRadius(4)
        .disabled(!isActive && profile.ssid != profile.ssid) // Enable only if connected
    }
}

// MARK: - Footer Section

struct FooterSection: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        HStack {
            if appState.status == .cloakingActive {
                Button {
                    appState.activateKillSwitch()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.octagon.fill")
                        Text("Kill Switch")
                    }
                    .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(KillSwitchButtonStyle())
            }
            
            Spacer()
            
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit")
                    .font(.system(size: 12))
            }
            .buttonStyle(PlainButtonStyle())
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - Button Styles

struct MenuBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13))
            .foregroundColor(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(configuration.isPressed ? Color(.selectedControlColor) : Color.clear)
            .cornerRadius(4)
    }
}

struct KillSwitchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.red)
            .cornerRadius(4)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Dashboard View Placeholder

struct DashboardView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Dashboard")
                    .font(.title)
                    .padding()
                
                if let session = appState.activeSession {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(label: "SSID", value: session.ssid)
                        InfoRow(label: "Interface", value: session.interface)
                        InfoRow(label: "Duration", value: session.formattedDuration)
                        InfoRow(label: "TTL", value: "\(session.appliedTTL)")
                        InfoRow(label: "MTU", value: "\(session.appliedMTU)")
                    }
                    .padding()
                } else {
                    Text("No active session")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .frame(width: 400, height: 300)
            .navigationTitle("TetherFlow Dashboard")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarView()
    }
}
