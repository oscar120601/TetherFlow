#!/usr/bin/env python3
"""
TetherFlow Menu Bar App
使用 rumps 開發的 macOS 選單列圖示
"""

import rumps
import requests
import json
import threading
import time

API_BASE = "http://localhost:5001/api"


class TetherFlowMenuBar(rumps.App):
    def __init__(self):
        super().__init__(
            name="TetherFlow",
            title="🛡️",
            icon=None
        )
        
        # 狀態
        self.is_cloaked = False
        self.has_password = False
        self.ttl = 64
        self.mtu = 1500
        self.server_online = False
        
        # 建立選單
        self.setup_menu()
        
        # 啟動背景執行緒檢查狀態
        self.update_timer = threading.Thread(target=self.status_loop, daemon=True)
        self.update_timer.start()
    
    def setup_menu(self):
        """建立選單項目"""
        self.menu = [
            rumps.MenuItem("TetherFlow", callback=None),
            None,  # 分隔線
            rumps.MenuItem("狀態: 檢查中...", callback=None),
            rumps.MenuItem("TTL: --", callback=None),
            rumps.MenuItem("MTU: --", callback=None),
            None,
            rumps.MenuItem("🟢 啟動偽裝", callback=self.start_cloaking),
            rumps.MenuItem("🔴 停止偽裝", callback=self.stop_cloaking),
            None,
            rumps.MenuItem("🌐 打開 Web UI", callback=self.open_web_ui),
            rumps.MenuItem("🔄 立即更新", callback=self.manual_update),
            None,
            rumps.MenuItem("結束", callback=self.quit_app),
        ]
    
    def api_call(self, endpoint, method="GET", data=None):
        """呼叫 Web API"""
        try:
            url = f"{API_BASE}{endpoint}"
            if method == "GET":
                response = requests.get(url, timeout=5)
            else:
                response = requests.post(
                    url, 
                    json=data or {},
                    headers={"Content-Type": "application/json"},
                    timeout=10
                )
            return response.json()
        except Exception as e:
            print(f"API 錯誤: {e}")
            return None
    
    def status_loop(self):
        """背景執行緒：定期更新狀態"""
        while True:
            self.update_status()
            time.sleep(5)  # 每 5 秒更新一次
    
    def update_status(self):
        """更新狀態顯示"""
        data = self.api_call("/status")
        
        if data and data.get("success"):
            self.server_online = True
            status_data = data.get("data", {})
            
            self.is_cloaked = status_data.get("is_cloaked", False)
            self.has_password = status_data.get("has_password", False)
            self.ttl = status_data.get("ttl", 64)
            self.mtu = status_data.get("mtu", 1500)
            
            # 更新選單顯示
            self.update_menu_display()
        else:
            self.server_online = False
            self.title = "🛡️❌"
            self.update_menu_offline()
    
    def update_menu_display(self):
        """更新選單顯示"""
        # 更新標題圖示
        if self.is_cloaked:
            self.title = "🛡️🟢"
        else:
            self.title = "🛡️⚪"
        
        # 更新選單項目
        status_text = "偽裝已啟動" if self.is_cloaked else "偽裝未啟動"
        if not self.has_password:
            status_text += " (未登入)"
        
        # 找到並更新選單項目
        for item in self.menu:
            if isinstance(item, rumps.MenuItem):
                if item.title.startswith("狀態:"):
                    item.title = f"狀態: {status_text}"
                elif item.title.startswith("TTL:"):
                    item.title = f"TTL: {self.ttl}"
                elif item.title.startswith("MTU:"):
                    item.title = f"MTU: {self.mtu}"
    
    def update_menu_offline(self):
        """伺服器離線時的選單顯示"""
        for item in self.menu:
            if isinstance(item, rumps.MenuItem):
                if item.title.startswith("狀態:"):
                    item.title = "狀態: 伺服器離線"
                elif item.title.startswith("TTL:"):
                    item.title = "TTL: --"
                elif item.title.startswith("MTU:"):
                    item.title = "MTU: --"
    
    @rumps.clicked("🟢 啟動偽裝")
    def start_cloaking(self, _):
        """啟動偽裝"""
        if not self.server_online:
            rumps.alert("錯誤", "伺服器未啟動，請先執行 ./start.sh")
            return
        
        if not self.has_password:
            rumps.alert("提示", "請先在 Web UI 中儲存密碼")
            self.open_web_ui(None)
            return
        
        response = self.api_call("/start", method="POST", data={"ttl": 65, "mtu": 1400})
        
        if response and response.get("success"):
            rumps.notification("TetherFlow", "✅ 偽裝已啟動", "TTL=65, MTU=1400")
            self.update_status()
        else:
            error = response.get("error", "未知錯誤") if response else "連線失敗"
            rumps.alert("❌ 啟動失敗", error)
    
    @rumps.clicked("🔴 停止偽裝")
    def stop_cloaking(self, _):
        """停止偽裝"""
        if not self.server_online:
            rumps.alert("錯誤", "伺服器未啟動")
            return
        
        response = self.api_call("/stop", method="POST")
        
        if response and response.get("success"):
            rumps.notification("TetherFlow", "🔴 偽裝已停止", "已還原預設值")
            self.update_status()
        else:
            error = response.get("error", "未知錯誤") if response else "連線失敗"
            rumps.alert("❌ 停止失敗", error)
    
    @rumps.clicked("🌐 打開 Web UI")
    def open_web_ui(self, _):
        """打開瀏覽器"""
        import webbrowser
        webbrowser.open("http://localhost:5001")
    
    @rumps.clicked("🔄 立即更新")
    def manual_update(self, _):
        """手動更新狀態"""
        self.update_status()
        if self.server_online:
            rumps.notification("TetherFlow", "✅ 狀態已更新", f"TTL={self.ttl}, MTU={self.mtu}")
    
    @rumps.clicked("結束")
    def quit_app(self, _):
        """結束應用"""
        rumps.quit_application()


def main():
    """主程式"""
    app = TetherFlowMenuBar()
    app.run()


if __name__ == "__main__":
    main()
