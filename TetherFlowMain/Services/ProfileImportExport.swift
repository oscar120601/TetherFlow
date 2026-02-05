//
//  ProfileImportExport.swift
//  TetherFlow
//
//  Import and export hotspot profiles for backup and sharing
//

import Foundation

/// Manages import and export of hotspot profiles
actor ProfileImportExport {
    
    // MARK: - Types
    
    enum ImportExportError: Error {
        case invalidFileFormat
        case invalidJSON
        case incompatibleVersion
        case readError(String)
        case writeError(String)
        case duplicateProfiles([String])
    }
    
    struct ExportPackage: Codable {
        let version: String
        let exportDate: Date
        let deviceName: String
        let profiles: [ExportedProfile]
        let customDNS: [DNSConfigurator.CustomDNSConfig]
        let keyboardShortcuts: [String: KeyboardShortcutsManager.KeyCombo]
        
        init(profiles: [HotspotProfile], customDNS: [DNSConfigurator.CustomDNSConfig] = [], shortcuts: [KeyboardShortcutsManager.ShortcutAction: KeyboardShortcutsManager.KeyCombo] = [:]) {
            self.version = "1.0"
            self.exportDate = Date()
            self.deviceName = Host.current().localizedName ?? "Unknown"
            self.profiles = profiles.map { ExportedProfile(from: $0) }
            self.customDNS = customDNS
            self.keyboardShortcuts = Dictionary(uniqueKeysWithValues: shortcuts.map { ($0.key.rawValue, $0.value) })
        }
    }
    
    struct ExportedProfile: Codable {
        let id: UUID
        let ssid: String
        let targetTTL: Int
        let targetMTU: Int
        let autoActivate: Bool
        let enableTrafficShaping: Bool
        let hourlyDataThreshold: Double
        let dailyDataThreshold: Double
        let useEncryptedDNS: Bool
        let dnsProvider: String
        let createdAt: Date
        let lastModified: Date
        let notes: String?
        
        init(from profile: HotspotProfile) {
            self.id = profile.id
            self.ssid = profile.ssid
            self.targetTTL = profile.targetTTL
            self.targetMTU = profile.targetMTU
            self.autoActivate = profile.autoActivate
            self.enableTrafficShaping = profile.enableTrafficShaping
            self.hourlyDataThreshold = profile.hourlyDataThreshold
            self.dailyDataThreshold = profile.dailyDataThreshold
            self.useEncryptedDNS = profile.useEncryptedDNS
            self.dnsProvider = profile.dnsProvider.rawValue
            self.createdAt = profile.createdAt
            self.lastModified = profile.lastModified
            self.notes = nil
        }
        
        func toHotspotProfile() -> HotspotProfile {
            HotspotProfile(
                id: id,
                ssid: ssid,
                targetTTL: targetTTL,
                targetMTU: targetMTU,
                autoActivate: autoActivate,
                enableTrafficShaping: enableTrafficShaping,
                hourlyDataThreshold: hourlyDataThreshold,
                dailyDataThreshold: dailyDataThreshold,
                useEncryptedDNS: useEncryptedDNS,
                dnsProvider: HotspotProfile.DNSProvider(rawValue: dnsProvider) ?? .cloudflare,
                createdAt: createdAt,
                lastModified: lastModified
            )
        }
    }
    
    struct ImportResult {
        let successCount: Int
        let skippedCount: Int
        let failedCount: Int
        let importedProfiles: [HotspotProfile]
        let skippedSSIDs: [String]
        let errors: [String]
    }
    
    // MARK: - Export
    
    /// Exports profiles to a JSON file
    /// - Parameters:
    ///   - profiles: Profiles to export
    ///   - customDNS: Custom DNS configurations to include
    ///   - shortcuts: Keyboard shortcuts to include
    ///   - url: Destination file URL
    func exportProfiles(
        profiles: [HotspotProfile],
        customDNS: [DNSConfigurator.CustomDNSConfig] = [],
        shortcuts: [KeyboardShortcutsManager.ShortcutAction: KeyboardShortcutsManager.KeyCombo] = [:],
        to url: URL
    ) async throws {
        let package = ExportPackage(profiles: profiles, customDNS: customDNS, shortcuts: shortcuts)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(package)
        
        do {
            try data.write(to: url)
            Logger.info("Exported \(profiles.count) profiles to \(url.path)")
        } catch {
            Logger.error("Failed to write export file: \(error.localizedDescription)")
            throw ImportExportError.writeError(error.localizedDescription)
        }
    }
    
    /// Creates a JSON string from profiles
    func exportToJSON(profiles: [HotspotProfile]) throws -> String {
        let package = ExportPackage(profiles: profiles)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(package)
        
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw ImportExportError.writeError("Failed to encode JSON string")
        }
        
        return jsonString
    }
    
    /// Shares profiles via system share sheet
    func shareProfiles(profiles: [HotspotProfile], from view: NSView?) async {
        do {
            let tempDir = FileManager.default.temporaryDirectory
            let tempFile = tempDir.appendingPathComponent("TetherFlow_Profiles_\(Date().timeIntervalSince1970).json")
            
            try await exportProfiles(profiles: profiles, to: tempFile)
            
            // Show share sheet
            await MainActor.run {
                let picker = NSSharingServicePicker(items: [tempFile])
                if let view = view {
                    picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
                }
            }
        } catch {
            Logger.error("Failed to share profiles: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Import
    
    /// Imports profiles from a JSON file
    /// - Parameters:
    ///   - url: Source file URL
    ///   - existingProfiles: Currently configured profiles (for duplicate detection)
    ///   - skipDuplicates: Whether to skip profiles with duplicate SSIDs
    /// - Returns: Import result with details
    func importProfiles(from url: URL, existingProfiles: [HotspotProfile], skipDuplicates: Bool = true) async throws -> ImportResult {
        let data: Data
        
        do {
            data = try Data(contentsOf: url)
        } catch {
            Logger.error("Failed to read import file: \(error.localizedDescription)")
            throw ImportExportError.readError(error.localizedDescription)
        }
        
        let package: ExportPackage
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            package = try decoder.decode(ExportPackage.self, from: data)
        } catch {
            Logger.error("Failed to parse import file: \(error.localizedDescription)")
            throw ImportExportError.invalidJSON
        }
        
        // Check version compatibility
        guard package.version == "1.0" else {
            Logger.error("Incompatible export version: \(package.version)")
            throw ImportExportError.incompatibleVersion
        }
        
        var importedProfiles: [HotspotProfile] = []
        var skippedSSIDs: [String] = []
        var errors: [String] = []
        
        let existingSSIDs = Set(existingProfiles.map { $0.ssid })
        
        for exportedProfile in package.profiles {
            // Check for duplicates
            if existingSSIDs.contains(exportedProfile.ssid) {
                if skipDuplicates {
                    skippedSSIDs.append(exportedProfile.ssid)
                    Logger.info("Skipped duplicate profile: \(exportedProfile.ssid)")
                    continue
                } else {
                    // Generate new ID for duplicate
                    let profile = HotspotProfile(
                        ssid: exportedProfile.ssid + " (Imported)",
                        targetTTL: exportedProfile.targetTTL,
                        targetMTU: exportedProfile.targetMTU,
                        autoActivate: exportedProfile.autoActivate,
                        enableTrafficShaping: exportedProfile.enableTrafficShaping,
                        hourlyDataThreshold: exportedProfile.hourlyDataThreshold,
                        dailyDataThreshold: exportedProfile.dailyDataThreshold,
                        useEncryptedDNS: exportedProfile.useEncryptedDNS,
                        dnsProvider: HotspotProfile.DNSProvider(rawValue: exportedProfile.dnsProvider) ?? .cloudflare
                    )
                    importedProfiles.append(profile)
                }
            } else {
                let profile = exportedProfile.toHotspotProfile()
                importedProfiles.append(profile)
            }
        }
        
        Logger.info("Import complete: \(importedProfiles.count) imported, \(skippedSSIDs.count) skipped")
        
        return ImportResult(
            successCount: importedProfiles.count,
            skippedCount: skippedSSIDs.count,
            failedCount: errors.count,
            importedProfiles: importedProfiles,
            skippedSSIDs: skippedSSIDs,
            errors: errors
        )
    }
    
    /// Imports profiles from a JSON string
    func importFromJSON(_ jsonString: String, existingProfiles: [HotspotProfile], skipDuplicates: Bool = true) async throws -> ImportResult {
        guard let data = jsonString.data(using: .utf8) else {
            throw ImportExportError.invalidJSON
        }
        
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("temp_import_\(Date().timeIntervalSince1970).json")
        try data.write(to: tempFile)
        
        let result = try await importProfiles(from: tempFile, existingProfiles: existingProfiles, skipDuplicates: skipDuplicates)
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempFile)
        
        return result
    }
    
    // MARK: - Validation
    
    /// Validates if a file contains valid profile data
    func validateImportFile(_ url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url) else {
            return false
        }
        
        do {
            let decoder = JSONDecoder()
            _ = try decoder.decode(ExportPackage.self, from: data)
            return true
        } catch {
            return false
        }
    }
    
    /// Gets export file info without importing
    func getExportInfo(from url: URL) -> (profileCount: Int, deviceName: String, exportDate: Date)? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let package = try decoder.decode(ExportPackage.self, from: data)
            return (package.profiles.count, package.deviceName, package.exportDate)
        } catch {
            return nil
        }
    }
}

// MARK: - Extensions

extension ProfileImportExport.ImportResult {
    /// User-friendly summary of import result
    var summary: String {
        var parts: [String] = []
        
        if successCount > 0 {
            parts.append("\(successCount) profile(s) imported")
        }
        
        if skippedCount > 0 {
            parts.append("\(skippedCount) duplicate(s) skipped")
        }
        
        if failedCount > 0 {
            parts.append("\(failedCount) failed")
        }
        
        return parts.isEmpty ? "No profiles imported" : parts.joined(separator: ", ")
    }
    
    /// Whether the import was successful
    var isSuccessful: Bool {
        successCount > 0 && failedCount == 0
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

struct ProfileImportExportView: View {
    @ObservedObject var appState: AppState
    @State private var showingImportSheet = false
    @State private var showingExportSheet = false
    @State private var importResult: ProfileImportExport.ImportResult?
    @State private var importError: Error?
    @State private var showImportResult = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Export Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Export Profiles")
                    .font(.headline)
                
                Text("Export your configured hotspot profiles for backup or sharing.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button {
                    showingExportSheet = true
                } label: {
                    Label("Export \(appState.profiles.count) Profiles", systemImage: "square.and.arrow.up")
                }
                .disabled(appState.profiles.isEmpty)
            }
            
            Divider()
            
            // Import Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Import Profiles")
                    .font(.headline)
                
                Text("Import profiles from a backup file.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button {
                    showingImportSheet = true
                } label: {
                    Label("Import Profiles", systemImage: "square.and.arrow.down")
                }
            }
            
            if let result = importResult, showImportResult {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Import Result")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(result.summary)
                        .font(.caption)
                    
                    if !result.skippedSSIDs.isEmpty {
                        Text("Skipped duplicates: \(result.skippedSSIDs.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
        .padding()
        .frame(width: 400)
        .fileImporter(
            isPresented: $showingImportSheet,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        .fileExporter(
            isPresented: $showingExportSheet,
            document: ProfileExportDocument(profiles: appState.profiles),
            contentType: .json,
            defaultFilename: "TetherFlow_Profiles"
        ) { result in
            handleExport(result: result)
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                do {
                    let importExport = ProfileImportExport()
                    let result = try await importExport.importProfiles(
                        from: url,
                        existingProfiles: appState.profiles,
                        skipDuplicates: true
                    )
                    
                    await MainActor.run {
                        self.importResult = result
                        self.showImportResult = true
                        
                        // Add imported profiles
                        for profile in result.importedProfiles {
                            appState.saveProfile(profile)
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.importError = error
                    }
                }
            }
            
        case .failure(let error):
            self.importError = error
        }
    }
    
    private func handleExport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            Logger.info("Profiles exported to: \(url.path)")
        case .failure(let error):
            Logger.error("Export failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - File Document for Export

struct ProfileExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }
    
    var profiles: [HotspotProfile]
    
    init(profiles: [HotspotProfile]) {
        self.profiles = profiles
    }
    
    init(configuration: ReadConfiguration) throws {
        profiles = []
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let export = ProfileImportExport()
        let jsonString = try export.exportToJSON(profiles: profiles)
        let data = jsonString.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}
