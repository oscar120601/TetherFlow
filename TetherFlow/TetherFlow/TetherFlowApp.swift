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
            ContentView()
                .frame(width: 360)
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
