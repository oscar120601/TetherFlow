#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TetherFlow 選單列應用程式
=======================

功能說明:
---------
- 顯示即時網路偽裝狀態 (TTL/MTU/DNS)
- 一鍵啟動/停止偽裝 + 加密 DNS
- 快速開啟 Web UI 管理介面

檔案位置:
---------
/Users/chanoscar/TetherFlow/menubar/tetherflow_menubar.py

開機自動啟動設定:
----------------
1. 系統設定 → 一般 → 登入項目
2. 加入「TetherFlow Menu.app」

作者: TetherFlow Team
版本: 1.1.0
更新: 2026-02-06
"""

import rumps
import requests
import webbrowser

# API 基礎網址
API_BASE = "http://localhost:5001/api"


class TetherFlowMenuBar(rumps.App):
    """
    TetherFlow 選單列應用程式主類別
    """
    
    def __init__(self):
        super().__init__(
            name="TetherFlow",
            title="🛡️",           # 選單列圖示
            icon=None,            # 不使用圖檔，使用 emoji
            quit_button=None      # 使用自訂結束選項
        )
        
        # 初始化選單
        self.setup_menu()
        
        # 啟動定時更新 (每 3 秒)
        rumps.Timer(self.update_status, 3).start()
    
    def setup_menu(self):
        """
        建立選單項目
        
        選單結構:
        - TetherFlow (標題)
        - 狀態/TTL/MTU/DNS (動態更新)
        - 啟動/停止按鈕
        - 設定/Web UI
        - 結束
        """
        # 狀態顯示項目（保存參照以便更新）
        self.status_item = rumps.MenuItem("狀態: 初始化...", callback=None)
        self.ttl_item = rumps.MenuItem("TTL: --", callback=None)
        self.mtu_item = rumps.MenuItem("MTU: --", callback=None)
        self.dns_item = rumps.MenuItem("DNS: --", callback=None)
        
        # 主選單
        self.menu = [
            rumps.MenuItem("TetherFlow", callback=None),
            None,  # 分隔線
            self.status_item,
            self.ttl_item,
            self.mtu_item,
            self.dns_item,
            None,
            rumps.MenuItem("🟢 啟動偽裝 + DNS", callback=self.start_cloaking),
            rumps.MenuItem("⚪ 停止偽裝 + DNS", callback=self.stop_cloaking),
            None,
            rumps.MenuItem("🔐 加密 DNS 設定", callback=self.open_dns_settings),
            rumps.MenuItem("🌐 打開 Web UI", callback=self.open_web_ui),
            None,
            rumps.MenuItem("結束", callback=self.quit_app),
        ]
    
    def api_call(self, endpoint, method="GET", data=None):
        """
        呼叫 TetherFlow Web API
        
        Args:
            endpoint: API 端點 (如 "/status")
            method: HTTP 方法 (GET/POST)
            data: POST 資料 (dict)
        
        Returns:
            API 回應 (dict) 或 None (失敗)
        """
        try:
            url = f"{API_BASE}{endpoint}"
            if method == "GET":
                response = requests.get(url, timeout=5)
            else:
                response = requests.post(url, json=data or {}, timeout=10)
            return response.json()
        except Exception as e:
            print(f"API 呼叫失敗: {e}")
            return None
    
    def update_status(self, timer=None):
        """
        更新選單狀態顯示
        
        每 3 秒自動執行，同步:
        - 標題圖示 (🛡️🟢/🛡️⚪)
        - 狀態文字
        - TTL/MTU 數值
        - DNS 狀態
        """
        data = self.api_call("/status")
        
        if data and data.get("success"):
            d = data.get("data", {})
            
            # 取得狀態資訊
            is_cloaked = d.get("is_cloaked", False)
            has_password = d.get("has_password", False)
            ttl = d.get("ttl", 64)
            mtu = d.get("mtu", 1500)
            
            # DNS 設定
            dns = d.get("dns_settings", {})
            dns_enabled = dns.get("enabled", False)
            dns_provider = dns.get("provider", "cloudflare")
            
            # 更新標題圖示
            # 🟢 = 偽裝中, ⚪ = 未偽裝, ❌ = 離線
            self.title = "🛡️🟢" if is_cloaked else "🛡️⚪"
            
            # 更新狀態文字
            status_text = "偽裝已啟動" if is_cloaked else "未啟動"
            if not has_password:
                status_text += " (未登入)"
            self.status_item.title = f"狀態: {status_text}"
            
            # 更新數值
            self.ttl_item.title = f"TTL: {ttl}"
            self.mtu_item.title = f"MTU: {mtu}"
            
            # 更新 DNS 狀態
            dns_text = "✅ 已啟用" if dns_enabled else "❌ 未啟用"
            provider_name = self._get_provider_name(dns_provider)
            self.dns_item.title = f"DNS: {dns_text} ({provider_name})"
            
        else:
            # 伺服器離線
            self.title = "🛡️❌"
            self.status_item.title = "狀態: 伺服器離線"
            self.ttl_item.title = "TTL: --"
            self.mtu_item.title = "MTU: --"
            self.dns_item.title = "DNS: --"
    
    def _get_provider_name(self, provider):
        """
        將 DNS provider key 轉換為顯示名稱
        
        Args:
            provider: provider key (如 "cloudflare")
        
        Returns:
            顯示名稱 (如 "Cloudflare")
        """
        providers = {
            'cloudflare': 'Cloudflare',
            'cloudflare_family': 'Cloudflare Family',
            'google': 'Google DNS',
            'quad9': 'Quad9',
            'opendns': 'OpenDNS',
            'custom': '自訂'
        }
        return providers.get(provider, provider)
    
    @rumps.clicked("🟢 啟動偽裝 + DNS")
    def start_cloaking(self, _):
        """
        啟動網路偽裝並啟用加密 DNS
        
        執行順序:
        1. 檢查伺服器狀態
        2. 檢查密碼是否已儲存
        3. 啟動偽裝 (TTL=65, MTU=1400)
        4. 啟用加密 DNS
        5. 更新狀態顯示
        """
        # 檢查伺服器
        status = self.api_call("/status")
        if not status or not status.get("success"):
            rumps.alert("❌ 錯誤", "後端伺服器未啟動\n請先執行 ./start.sh")
            return
        
        # 檢查密碼
        if not status.get("data", {}).get("has_password", False):
            rumps.alert("🔐 需要密碼", "請先在 Web UI 中儲存系統密碼")
            self.open_web_ui(None)
            return
        
        # 啟動偽裝
        resp = self.api_call("/start", method="POST", data={
            "ttl": 65,
            "mtu": 1400
        })
        
        if resp and resp.get("success"):
            # 啟用 DNS
            self.api_call("/dns/settings", method="POST", data={
                "enabled": True,
                "provider": "cloudflare",
                "custom_servers": []
            })
            
            # 立即更新顯示
            self.update_status()
            
            # 顯示成功通知
            rumps.notification(
                title="TetherFlow",
                subtitle="✅ 偽裝 + DNS 已啟動",
                message="網路流量已偽裝為行動設備"
            )
        else:
            error = resp.get("error", "啟動失敗") if resp else "連線失敗"
            rumps.alert("❌ 啟動失敗", error)
    
    @rumps.clicked("⚪ 停止偽裝 + DNS")
    def stop_cloaking(self, _):
        """
        停止網路偽裝並停用加密 DNS
        
        執行順序:
        1. 停止偽裝
        2. 停用加密 DNS
        3. 更新狀態顯示
        """
        resp = self.api_call("/stop", method="POST")
        
        if resp and resp.get("success"):
            # 停用 DNS
            self.api_call("/dns/settings", method="POST", data={
                "enabled": False,
                "provider": "cloudflare",
                "custom_servers": []
            })
            
            # 立即更新顯示
            self.update_status()
            
            # 顯示通知
            rumps.notification(
                title="TetherFlow",
                subtitle="🔴 偽裝 + DNS 已停止",
                message="已還原為預設網路設定"
            )
        else:
            error = resp.get("error", "停止失敗") if resp else "連線失敗"
            rumps.alert("❌ 停止失敗", error)
    
    @rumps.clicked("🔐 加密 DNS 設定")
    def open_dns_settings(self, _):
        """
        開啟 Web UI 的 DNS 設定頁面
        """
        webbrowser.open("http://localhost:5001")
        rumps.notification(
            title="TetherFlow",
            subtitle="🌐 已開啟 Web UI",
            message="請在「系統設定」標籤中設定 DNS"
        )
    
    @rumps.clicked("🌐 打開 Web UI")
    def open_web_ui(self, _):
        """
        開啟 TetherFlow Web 管理介面
        """
        webbrowser.open("http://localhost:5001")
    
    def quit_app(self, _):
        """
        結束選單列應用程式
        """
        rumps.quit_application()


def main():
    """
    程式進入點
    """
    app = TetherFlowMenuBar()
    app.run()


if __name__ == "__main__":
    main()
