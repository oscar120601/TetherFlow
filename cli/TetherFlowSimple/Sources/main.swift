//
//  TetherFlowSimple - 簡化版 Menu Bar 應用
//  可正常執行的示範版本
//

import Cocoa
import SwiftUI

// MARK: - App Delegate
@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var menu: NSMenu!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 建立 Menu Bar 項目
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.title = "🛡️"
            button.action = #selector(showMenu)
            button.target = self
        }
        
        // 建立選單
        setupMenu()
        
        print("✅ TetherFlow 已啟動！")
        print("點擊 Menu Bar 的 🛡️ 圖示使用")
    }
    
    func setupMenu() {
        menu = NSMenu()
        
        // 標題
        let titleItem = NSMenuItem(title: "TetherFlow", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        // 狀態
        let statusItem = NSMenuItem(title: "狀態: 待機中", action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        menu.addItem(NSMenuItem.separator())
        
        // 功能選項
        menu.addItem(NSMenuItem(title: "🟢 啟動偽裝", action: #selector(startCloaking), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "🔴 停止偽裝", action: #selector(stopCloaking), keyEquivalent: "x"))
        menu.addItem(NSMenuItem.separator())
        
        // 檢查網路
        menu.addItem(NSMenuItem(title: "檢查 TTL/MTU", action: #selector(checkNetwork), keyEquivalent: "c"))
        menu.addItem(NSMenuItem.separator())
        
        // 說明
        menu.addItem(NSMenuItem(title: "使用說明", action: #selector(showHelp), keyEquivalent: "h"))
        menu.addItem(NSMenuItem.separator())
        
        // 結束
        menu.addItem(NSMenuItem(title: "結束", action: #selector(quit), keyEquivalent: "q"))
    }
    
    @objc func showMenu() {
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil  // 重置以便下次點擊
    }
    
    @objc func startCloaking() {
        print("\n🟢 啟動偽裝...")
        
        // 執行 sysctl 修改 TTL
        let ttlTask = Process()
        ttlTask.launchPath = "/usr/bin/sudo"
        ttlTask.arguments = ["/usr/sbin/sysctl", "net.inet.ip.ttl=65"]
        
        do {
            try ttlTask.run()
            ttlTask.waitUntilExit()
            
            // 修改 MTU
            let mtuTask = Process()
            mtuTask.launchPath = "/usr/bin/sudo"
            mtuTask.arguments = ["/sbin/ifconfig", "en0", "mtu", "1400"]
            try mtuTask.run()
            mtuTask.waitUntilExit()
            
            showAlert(title: "✅ 偽裝已啟動", message: "TTL 已設為 65\nMTU 已設為 1400")
        } catch {
            showAlert(title: "❌ 錯誤", message: "需要使用 sudo 權限\n請在終端機執行:\nsudo sysctl net.inet.ip.ttl=65")
        }
    }
    
    @objc func stopCloaking() {
        print("\n🔴 停止偽裝...")
        
        let ttlTask = Process()
        ttlTask.launchPath = "/usr/bin/sudo"
        ttlTask.arguments = ["/usr/sbin/sysctl", "net.inet.ip.ttl=64"]
        
        do {
            try ttlTask.run()
            ttlTask.waitUntilExit()
            
            let mtuTask = Process()
            mtuTask.launchPath = "/usr/bin/sudo"
            mtuTask.arguments = ["/sbin/ifconfig", "en0", "mtu", "1500"]
            try mtuTask.run()
            mtuTask.waitUntilExit()
            
            showAlert(title: "✅ 已還原", message: "TTL 已恢復為 64\nMTU 已恢復為 1500")
        } catch {
            showAlert(title: "❌ 錯誤", message: error.localizedDescription)
        }
    }
    
    @objc func checkNetwork() {
        print("\n📊 檢查網路設定...")
        
        // 檢查 TTL
        let ttlTask = Process()
        ttlTask.launchPath = "/usr/sbin/sysctl"
        ttlTask.arguments = ["net.inet.ip.ttl"]
        
        let pipe = Pipe()
        ttlTask.standardOutput = pipe
        
        do {
            try ttlTask.run()
            ttlTask.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "無法讀取"
            
            showAlert(title: "📊 網路狀態", message: output)
        } catch {
            showAlert(title: "❌ 錯誤", message: error.localizedDescription)
        }
    }
    
    @objc func showHelp() {
        let helpText = """
        TetherFlow 使用說明:
        
        1. 啟動偽裝：修改 TTL=65, MTU=1400
        2. 停止偽裝：還原 TTL=64, MTU=1500
        3. 檢查狀態：查看目前網路設定
        
        注意：需要管理員權限才能修改系統設定
        """
        showAlert(title: "使用說明", message: helpText)
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "確定")
        alert.runModal()
    }
}
