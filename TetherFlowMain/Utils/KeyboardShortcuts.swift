//
//  KeyboardShortcuts.swift
//  TetherFlow
//
//  Global keyboard shortcuts for quick actions
//

import SwiftUI
import Carbon

/// Manages global keyboard shortcuts for TetherFlow
class KeyboardShortcutsManager: ObservableObject {
    
    // MARK: - Types
    
    enum ShortcutAction: String, CaseIterable {
        case toggleCloaking = "toggle_cloaking"
        case activateKillSwitch = "activate_kill_switch"
        case openDashboard = "open_dashboard"
        case openProfileManager = "open_profile_manager"
        
        var displayName: String {
            switch self {
            case .toggleCloaking: return "Toggle Cloaking"
            case .activateKillSwitch: return "Activate Kill Switch"
            case .openDashboard: return "Open Dashboard"
            case .openProfileManager: return "Open Profile Manager"
            }
        }
        
        var defaultKeyCombo: KeyCombo? {
            switch self {
            case .toggleCloaking:
                return KeyCombo(keyCode: kVK_ANSI_T, modifiers: [.command, .shift])
            case .activateKillSwitch:
                return KeyCombo(keyCode: kVK_Escape, modifiers: [.command, .shift, .option])
            case .openDashboard:
                return KeyCombo(keyCode: kVK_ANSI_D, modifiers: [.command, .shift])
            case .openProfileManager:
                return KeyCombo(keyCode: kVK_ANSI_P, modifiers: [.command, .shift])
            }
        }
    }
    
    struct KeyCombo: Codable, Equatable {
        let keyCode: Int
        let modifiers: ModifierFlags
        
        struct ModifierFlags: OptionSet, Codable {
            let rawValue: Int
            
            static let command = ModifierFlags(rawValue: 1 << 0)
            static let option = ModifierFlags(rawValue: 1 << 1)
            static let control = ModifierFlags(rawValue: 1 << 2)
            static let shift = ModifierFlags(rawValue: 1 << 3)
            
            var carbonFlags: UInt32 {
                var flags: UInt32 = 0
                if contains(.command) { flags |= UInt32(cmdKey) }
                if contains(.option) { flags |= UInt32(optionKey) }
                if contains(.control) { flags |= UInt32(controlKey) }
                if contains(.shift) { flags |= UInt32(shiftKey) }
                return flags
            }
        }
        
        var displayString: String {
            var parts: [String] = []
            
            if modifiers.contains(.command) { parts.append("⌘") }
            if modifiers.contains(.option) { parts.append("⌥") }
            if modifiers.contains(.control) { parts.append("⌃") }
            if modifiers.contains(.shift) { parts.append("⇧") }
            
            parts.append(keyCodeToString(keyCode))
            
            return parts.joined(separator: "")
        }
        
        private func keyCodeToString(_ keyCode: Int) -> String {
            switch keyCode {
            case kVK_ANSI_A: return "A"
            case kVK_ANSI_B: return "B"
            case kVK_ANSI_C: return "C"
            case kVK_ANSI_D: return "D"
            case kVK_ANSI_E: return "E"
            case kVK_ANSI_K: return "K"
            case kVK_ANSI_P: return "P"
            case kVK_ANSI_T: return "T"
            case kVK_Escape: return "⎋"
            case kVK_Space: return "␣"
            case kVK_Return: return "↩"
            default: return "Key\(keyCode)"
            }
        }
    }
    
    // MARK: - Properties
    
    @Published var shortcuts: [ShortcutAction: KeyCombo] = [:]
    private var eventHandlers: [ShortcutAction: (() -> Void)] = [:]
    private var hotKeys: [UInt32: EventHotKeyRef] = [:]
    private var hotKeyID: UInt32 = 1
    
    static let shared = KeyboardShortcutsManager()
    
    // MARK: - Initialization
    
    private init() {
        loadShortcuts()
        registerForGlobalEvents()
    }
    
    deinit {
        unregisterAllHotKeys()
    }
    
    // MARK: - Public Interface
    
    /// Registers a handler for a shortcut action
    func registerHandler(for action: ShortcutAction, handler: @escaping () -> Void) {
        eventHandlers[action] = handler
    }
    
    /// Sets a keyboard shortcut for an action
    func setShortcut(_ keyCombo: KeyCombo?, for action: ShortcutAction) {
        // Unregister existing hotkey
        if let existingHotKey = hotKeys[hotKeyID(for: action)] {
            UnregisterEventHotKey(existingHotKey)
            hotKeys.removeValue(forKey: hotKeyID(for: action))
        }
        
        if let keyCombo = keyCombo {
            shortcuts[action] = keyCombo
            registerHotKey(keyCombo, for: action)
        } else {
            shortcuts.removeValue(forKey: action)
        }
        
        saveShortcuts()
    }
    
    /// Resets all shortcuts to defaults
    func resetToDefaults() {
        unregisterAllHotKeys()
        shortcuts.removeAll()
        
        for action in ShortcutAction.allCases {
            if let defaultCombo = action.defaultKeyCombo {
                shortcuts[action] = defaultCombo
                registerHotKey(defaultCombo, for: action)
            }
        }
        
        saveShortcuts()
        Logger.info("Keyboard shortcuts reset to defaults")
    }
    
    /// Disables all keyboard shortcuts
    func disableAllShortcuts() {
        unregisterAllHotKeys()
        Logger.info("All keyboard shortcuts disabled")
    }
    
    /// Enables all configured shortcuts
    func enableAllShortcuts() {
        for (action, keyCombo) in shortcuts {
            registerHotKey(keyCombo, for: action)
        }
        Logger.info("Keyboard shortcuts enabled")
    }
    
    /// Gets the shortcut for an action
    func shortcut(for action: ShortcutAction) -> KeyCombo? {
        return shortcuts[action]
    }
    
    // MARK: - Private Methods
    
    private func hotKeyID(for action: ShortcutAction) -> UInt32 {
        return UInt32(abs(action.rawValue.hashValue))
    }
    
    private func registerHotKey(_ keyCombo: KeyCombo, for action: ShortcutAction) {
        let hotKeyID = EventHotKeyID(
            signature: FourCharCode("TFLT"),
            id: hotKeyID(for: action)
        )
        
        var hotKeyRef: EventHotKeyRef?
        
        let status = RegisterEventHotKey(
            UInt32(keyCombo.keyCode),
            keyCombo.modifiers.carbonFlags,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr, let hotKey = hotKeyRef {
            hotKeys[hotKeyID.id] = hotKey
            Logger.debug("Registered hotkey for \(action.displayName): \(keyCombo.displayString)")
        } else {
            Logger.error("Failed to register hotkey for \(action.displayName)")
        }
    }
    
    private func unregisterAllHotKeys() {
        for (_, hotKeyRef) in hotKeys {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeys.removeAll()
    }
    
    private func registerForGlobalEvents() {
        // Set up event handler for hotkey events
        let eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        
        InstallEventHandler(
            GetEventDispatcherTarget(),
            { (_, eventRef, _) -> OSStatus in
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                
                KeyboardShortcutsManager.shared.handleHotKeyPress(id: hotKeyID.id)
                return noErr
            },
            1,
            [eventType],
            nil,
            nil
        )
    }
    
    private func handleHotKeyPress(id: UInt32) {
        // Find the action for this hotkey ID
        for action in ShortcutAction.allCases {
            if hotKeyID(for: action) == id {
                Logger.info("Hotkey pressed for: \(action.displayName)")
                eventHandlers[action]?()
                break
            }
        }
    }
    
    private func saveShortcuts() {
        do {
            let data = try JSONEncoder().encode(shortcuts)
            UserDefaults.standard.set(data, forKey: "com.tetherflow.keyboardShortcuts")
        } catch {
            Logger.error("Failed to save keyboard shortcuts: \(error.localizedDescription)")
        }
    }
    
    private func loadShortcuts() {
        if let data = UserDefaults.standard.data(forKey: "com.tetherflow.keyboardShortcuts") {
            do {
                shortcuts = try JSONDecoder().decode([ShortcutAction: KeyCombo].self, from: data)
            } catch {
                Logger.error("Failed to load keyboard shortcuts: \(error.localizedDescription)")
                resetToDefaults()
            }
        } else {
            // No saved shortcuts, use defaults
            resetToDefaults()
        }
    }
}

// MARK: - SwiftUI Integration

struct KeyboardShortcutSettingView: View {
    @StateObject private var manager = KeyboardShortcutsManager.shared
    @State private var recordingAction: KeyboardShortcutsManager.ShortcutAction?
    
    var body: some View {
        Form {
            Section(header: Text("Global Shortcuts")) {
                ForEach(KeyboardShortcutsManager.ShortcutAction.allCases, id: \.self) { action in
                    ShortcutRow(
                        action: action,
                        keyCombo: manager.shortcut(for: action),
                        isRecording: recordingAction == action,
                        onTap: {
                            recordingAction = (recordingAction == action) ? nil : action
                        }
                    )
                }
            }
            
            Section {
                Button("Reset to Defaults") {
                    manager.resetToDefaults()
                }
                .foregroundColor(.red)
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            manager.enableAllShortcuts()
        }
    }
}

struct ShortcutRow: View {
    let action: KeyboardShortcutsManager.ShortcutAction
    let keyCombo: KeyboardShortcutsManager.KeyCombo?
    let isRecording: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Text(action.displayName)
                .frame(width: 180, alignment: .leading)
            
            Spacer()
            
            if isRecording {
                Text("Press shortcut...")
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            } else if let combo = keyCombo {
                Text(combo.displayString)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            } else {
                Text("Not set")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
            }
            
            Button("Change") {
                onTap()
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}
