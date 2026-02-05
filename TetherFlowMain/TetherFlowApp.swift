//
//  TetherFlowApp.swift
//  TetherFlow
//
//  Main application entry point for the menu bar utility
//

import SwiftUI

@main
struct TetherFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("TetherFlow", systemImage: "antenna.radiowaves.left.and.right") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide app from dock (LSUIElement is set in Info.plist)
        NSApp.setActivationPolicy(.accessory)
        
        Logger.info("TetherFlow launched successfully")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        Logger.info("TetherFlow is terminating")
    }
}
