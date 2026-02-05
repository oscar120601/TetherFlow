//
//  DashboardView.swift
//  TetherFlow
//
//  Comprehensive monitoring dashboard with real-time metrics
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var metricsCollector: MetricsCollector?
    @State private var currentMetrics: MetricsCollector.MetricsSnapshot?
    @State private var metricsTask: Task<Void, Never>?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Status Card
                    StatusCard(appState: appState)
                    
                    // Speed Charts
                    SpeedChartsSection(
                        metrics: currentMetrics,
                        session: appState.activeSession
                    )
                    
                    // Data Usage Progress
                    DataUsageSection(
                        metrics: currentMetrics,
                        session: appState.activeSession
                    )
                    
                    // Session Statistics
                    if let session = appState.activeSession {
                        SessionStatisticsSection(session: session)
                    }
                    
                    // Safety Thresholds
                    SafetyThresholdsSection(
                        appState: appState,
                        metrics: currentMetrics
                    )
                    
                    // Kill Switch
                    KillSwitchSection(appState: appState)
                }
                .padding()
            }
            .frame(minWidth: 500, minHeight: 600)
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        refreshMetrics()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(appState.activeSession == nil)
                }
            }
        }
        .onAppear {
            startMetricsCollection()
        }
        .onDisappear {
            stopMetricsCollection()
        }
    }
    
    private func startMetricsCollection() {
        guard appState.activeSession != nil else { return }
        
        let collector = MetricsCollector(interface: appState.currentInterface ?? "en0")
        metricsCollector = collector
        
        metricsTask = Task {
            collector.startCollecting()
            
            for await metrics in await collector.metricsStream() {
                await MainActor.run {
                    self.currentMetrics = metrics
                }
            }
        }
    }
    
    private func stopMetricsCollection() {
        metricsTask?.cancel()
        metricsTask = nil
        
        Task {
            await metricsCollector?.stopCollecting()
            metricsCollector = nil
        }
    }
    
    private func refreshMetrics() {
        Task {
            if let metrics = await metricsCollector?.getCurrentMetrics() {
                await MainActor.run {
                    self.currentMetrics = metrics
                }
            }
        }
    }
}

// MARK: - Status Card

struct StatusCard: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatusIconView(status: appState.status)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(statusText)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor)
                }
                
                Spacer()
                
                if appState.status == .cloakingActive {
                    CloakingBadge()
                }
            }
            
            Divider()
            
            HStack {
                InfoItem(
                    icon: "wifi",
                    title: "Network",
                    value: appState.currentSSID ?? "Not connected"
                )
                
                Spacer()
                
                if let interface = appState.currentInterface {
                    InfoItem(
                        icon: "network",
                        title: "Interface",
                        value: interface
                    )
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var statusText: String {
        switch appState.status {
        case .idle: return "Ready"
        case .scanning: return "Scanning..."
        case .cloakingActive: return "Cloaking Active"
        case .reverting: return "Reverting..."
        case .error: return "Error"
        }
    }
    
    private var statusColor: Color {
        switch appState.status {
        case .idle, .scanning: return .primary
        case .cloakingActive: return .green
        case .reverting: return .orange
        case .error: return .red
        }
    }
}

// MARK: - Speed Charts Section

struct SpeedChartsSection: View {
    let metrics: MetricsCollector.MetricsSnapshot?
    let session: CloakingSession?
    
    @State private var uploadHistory: [Double] = []
    @State private var downloadHistory: [Double] = []
    private let maxDataPoints = 30
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Network Speed", systemImage: "speedometer")
                    .font(.headline)
                
                Spacer()
                
                if let metrics = metrics {
                    HStack(spacing: 16) {
                        SpeedLabel(
                            icon: "arrow.up",
                            color: .blue,
                            speed: metrics.uploadSpeed
                        )
                        
                        SpeedLabel(
                            icon: "arrow.down",
                            color: .green,
                            speed: metrics.downloadSpeed
                        )
                    }
                }
            }
            
            if !uploadHistory.isEmpty && !downloadHistory.isEmpty {
                SpeedChart(
                    uploadData: uploadHistory,
                    downloadData: downloadHistory
                )
                .frame(height: 150)
            } else {
                EmptyChartView()
                    .frame(height: 150)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .onChange(of: metrics) { newMetrics in
            if let metrics = newMetrics {
                updateHistory(upload: metrics.uploadSpeed, download: metrics.downloadSpeed)
            }
        }
    }
    
    private func updateHistory(upload: Double, download: Double) {
        uploadHistory.append(upload)
        downloadHistory.append(download)
        
        if uploadHistory.count > maxDataPoints {
            uploadHistory.removeFirst()
            downloadHistory.removeFirst()
        }
    }
}

struct SpeedChart: View {
    let uploadData: [Double]
    let downloadData: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid lines
                VStack(spacing: 0) {
                    ForEach(0..<5) { i in
                        HStack {
                            Divider()
                                .opacity(0.3)
                        }
                        if i < 4 {
                            Spacer()
                        }
                    }
                }
                
                // Chart lines
                HStack(spacing: 2) {
                    ForEach(0..<uploadData.count, id: \.self) { index in
                        VStack {
                            Spacer()
                            
                            // Download bar (green)
                            Rectangle()
                                .fill(Color.green.opacity(0.6))
                                .frame(width: 4, height: normalizedHeight(downloadData[index], in: geometry))
                            
                            // Upload bar (blue)
                            Rectangle()
                                .fill(Color.blue.opacity(0.8))
                                .frame(width: 4, height: normalizedHeight(uploadData[index], in: geometry))
                        }
                    }
                }
            }
        }
    }
    
    private func normalizedHeight(_ value: Double, in geometry: GeometryProxy) -> CGFloat {
        let maxValue = max(uploadData.max() ?? 1, downloadData.max() ?? 1)
        let normalized = maxValue > 0 ? value / maxValue : 0
        return CGFloat(normalized) * geometry.size.height * 0.9
    }
}

struct EmptyChartView: View {
    var body: some View {
        VStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No data available")
                .foregroundColor(.secondary)
        }
    }
}

struct SpeedLabel: View {
    let icon: String
    let color: Color
    let speed: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            Text(formatSpeed(speed))
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
    }
    
    private func formatSpeed(_ speed: Double) -> String {
        let units = ["B/s", "KB/s", "MB/s", "GB/s"]
        var speed = speed
        var unitIndex = 0
        
        while speed > 1024 && unitIndex < units.count - 1 {
            speed /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.1f %@", speed, units[unitIndex])
    }
}

// MARK: - Data Usage Section

struct DataUsageSection: View {
    let metrics: MetricsCollector.MetricsSnapshot?
    let session: CloakingSession?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Data Usage", systemImage: "chart.bar.fill")
                .font(.headline)
            
            if let metrics = metrics {
                VStack(spacing: 12) {
                    DataUsageBar(
                        label: "Session Total",
                        icon: "arrow.up.arrow.down",
                        used: metrics.totalGBTransferred,
                        total: nil,
                        color: .blue
                    )
                    
                    if let session = session {
                        Divider()
                        
                        HStack {
                            DataStatItem(
                                icon: "arrow.up",
                                label: "Uploaded",
                                value: formatBytes(metrics.bytesUploaded)
                            )
                            
                            Spacer()
                            
                            DataStatItem(
                                icon: "arrow.down",
                                label: "Downloaded",
                                value: formatBytes(metrics.bytesDownloaded)
                            )
                        }
                    }
                }
            } else {
                Text("Connect to start tracking data usage")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var bytes = Double(bytes)
        var unitIndex = 0
        
        while bytes > 1024 && unitIndex < units.count - 1 {
            bytes /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.2f %@", bytes, units[unitIndex])
    }
}

struct DataUsageBar: View {
    let label: String
    let icon: String
    let used: Double
    let total: Double?
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.subheadline)
                
                Spacer()
                
                Text(String(format: "%.2f GB", used))
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: progressWidth(in: geometry), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
    
    private func progressWidth(in geometry: GeometryProxy) -> CGFloat {
        guard let total = total, total > 0 else {
            return min(CGFloat(used / 10.0) * geometry.size.width, geometry.size.width)
        }
        return min(CGFloat(used / total) * geometry.size.width, geometry.size.width)
    }
}

struct DataStatItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(.callout, design: .monospaced))
                .fontWeight(.medium)
        }
    }
}

// MARK: - Session Statistics Section

struct SessionStatisticsSection: View {
    let session: CloakingSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Session Statistics", systemImage: "clock.fill")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatItem(
                    icon: "clock",
                    label: "Duration",
                    value: session.formattedDuration
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    icon: "number",
                    label: "TTL",
                    value: "\(session.appliedTTL)"
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    icon: "arrow.up.arrow.down",
                    label: "MTU",
                    value: "\(session.appliedMTU)"
                )
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Safety Thresholds Section

struct SafetyThresholdsSection: View {
    @ObservedObject var appState: AppState
    let metrics: MetricsCollector.MetricsSnapshot?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Safety Thresholds", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                
                Spacer()
                
                if let profile = activeProfile {
                    RiskLevelBadge(riskLevel: calculateRiskLevel(profile: profile))
                }
            }
            
            if let profile = activeProfile {
                VStack(spacing: 12) {
                    ThresholdProgressBar(
                        label: "Hourly Limit",
                        used: hourlyUsage(for: profile),
                        limit: profile.hourlyDataThreshold,
                        color: .orange
                    )
                    
                    ThresholdProgressBar(
                        label: "Daily Limit",
                        used: dailyUsage(for: profile),
                        limit: profile.dailyDataThreshold,
                        color: .red
                    )
                }
            } else {
                Text("Connect to a hotspot to monitor safety thresholds")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var activeProfile: HotspotProfile? {
        guard let session = appState.activeSession else { return nil }
        return appState.profiles.first { $0.id == session.profileId }
    }
    
    private func hourlyUsage(for profile: HotspotProfile) -> Double {
        // In real implementation, this would come from SafetyThreshold
        let sessionGB = metrics?.totalGBTransferred ?? 0
        return min(sessionGB, profile.hourlyDataThreshold)
    }
    
    private func dailyUsage(for profile: HotspotProfile) -> Double {
        // In real implementation, this would track daily usage
        let sessionGB = metrics?.totalGBTransferred ?? 0
        return min(sessionGB, profile.dailyDataThreshold)
    }
    
    private func calculateRiskLevel(profile: HotspotProfile) -> RiskLevel {
        let hourly = hourlyUsage(for: profile)
        let daily = dailyUsage(for: profile)
        
        if daily >= profile.dailyDataThreshold {
            return .critical
        } else if hourly >= profile.hourlyDataThreshold {
            return .high
        } else if hourly >= profile.hourlyDataThreshold * 0.8 {
            return .medium
        }
        return .low
    }
}

struct ThresholdProgressBar: View {
    let label: String
    let used: Double
    let limit: Double
    let color: Color
    
    var percentage: Double {
        min(used / limit, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                
                Spacer()
                
                Text(String(format: "%.1f / %.0f GB (%.0f%%)", used, limit, percentage * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: CGFloat(percentage) * geometry.size.width, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

struct RiskLevelBadge: View {
    let riskLevel: RiskLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(riskLevel.color)
                .frame(width: 8, height: 8)
            Text(riskLevel.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(riskLevel.color.opacity(0.1))
        .cornerRadius(4)
    }
}

// MARK: - Kill Switch Section

struct KillSwitchSection: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Emergency Controls", systemImage: "exclamationmark.octagon.fill")
                .font(.headline)
            
            if appState.status == .cloakingActive {
                Button {
                    appState.activateKillSwitch()
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("KILL SWITCH")
                                .font(.headline)
                            Text("Instantly stop all cloaking and restore network settings")
                                .font(.caption)
                        }
                        Spacer()
                        Image(systemName: "bolt.fill")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(
                        LinearGradient(
                            colors: [.red, .red.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("System is in normal state")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Helper Views

struct InfoItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Preview

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        DashboardView(appState: appState)
    }
}
