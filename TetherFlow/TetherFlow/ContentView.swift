//
//  ContentView.swift
//  TetherFlow
//
//  Main content view for the menu bar interface
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with status
            StatusHeaderView(appState: appState)
            
            Divider()
            
            // Dashboard preview
            DashboardPreviewView(appState: appState)
            
            Divider()
            
            // Profile management
            ProfileSectionView(appState: appState)
            
            Divider()
            
            // Footer actions
            FooterActionsView(appState: appState)
        }
        .padding()
    }
}

// MARK: - Status Header

struct StatusHeaderView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundColor(statusColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("TetherFlow")
                    .font(.headline)
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var statusIcon: String {
        switch appState.status {
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
    
    private var statusColor: Color {
        switch appState.status {
        case .idle, .scanning:
            return .secondary
        case .cloakingActive:
            return .green
        case .reverting:
            return .yellow
        case .error:
            return .red
        }
    }
    
    private var statusText: String {
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
            return "Error"
        }
    }
}

// MARK: - Dashboard Preview

struct DashboardPreviewView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Current Connection")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Network")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(appState.currentSSID ?? "Not connected")
                        .font(.body)
                }
                
                Spacer()
                
                if let session = appState.activeSession {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Session Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDuration(session.duration))
                            .font(.body)
                            .monospacedDigit()
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Profile Section

struct ProfileSectionView: View {
    @ObservedObject var appState: AppState
    @State private var showingProfileList = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Hotspot Profiles")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(appState.profiles.count) configured")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button("Manage Profiles...") {
                showingProfileList = true
            }
            .sheet(isPresented: $showingProfileList) {
                ProfileListView(appState: appState)
            }
        }
    }
}

// MARK: - Footer Actions

struct FooterActionsView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        HStack {
            Button("Dashboard...") {
                // Open dashboard window
            }
            
            Spacer()
            
            if appState.status == .cloakingActive {
                Button("Kill Switch") {
                    appState.activateKillSwitch()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
