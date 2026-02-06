# TetherFlow 自動啟動設定指南

讓 TetherFlow 在開機時自動啟動，無需開啟終端機！

---

## 🚀 快速設定（推薦）

### 步驟 1：設定開機自動啟動 Web 後端

```bash
# 在專案目錄執行
chmod +x setup_autostart.sh
./setup_autostart.sh
```

這會：
- ✅ 建立 LaunchAgent（開機自動啟動後端服務）
- ✅ 安裝選單列應用依賴
- ✅ 啟動服務

### 步驟 2：建立選單列應用程式

```bash
chmod +x create_menuapp.sh
./create_menuapp.sh
```

這會建立一個 `TetherFlow Menu.app`，你可以：
- 雙擊啟動
- 拖曳到 Dock
- 加入「登入項目」實現完全自動化

### 步驟 3：設定開機自動啟動選單列

1. 開啟「系統設定」→「一般」→「登入項目」
2. 點擊「+」
3. 選擇 `TetherFlow Menu.app`

---

## 📱 使用方式

### 開機後

| 時間 | 發生的事 |
|------|---------|
| 登入時 | Web 後端自動在背景啟動（localhost:5001）|
| 登入時 | 選單列圖示自動出現在選單列 🛡️ |
| 隨時 | 點擊選單列圖示控制 TetherFlow |

### 選單列功能

```
🛡️
├── TetherFlow
├── ─────────────
├── 狀態: 已啟動偽裝
├── TTL: 64
├── MTU: 1500
├── ─────────────
├── 🟢 啟動偽裝
├── 🔴 停止偽裝
├── ─────────────
├── 🌐 打開 Web UI  ← 點這個開網頁
└── 退出
```

---

## 🔧 管理指令

如果需要手動控制：

```bash
# 查看服務狀態
launchctl list | grep tetherflow

# 停止後端服務
launchctl unload ~/Library/LaunchAgents/com.oscar1206.tetherflow.plist

# 啟動後端服務
launchctl load ~/Library/LaunchAgents/com.oscar1206.tetherflow.plist

# 查看日誌
tail -f /tmp/tetherflow.out.log
tail -f /tmp/tetherflow.err.log
```

---

## ❓ 疑難排解

### 服務沒有自動啟動

1. 檢查 plist 檔案是否存在：
   ```bash
   ls ~/Library/LaunchAgents/com.oscar1206.tetherflow.plist
   ```

2. 手動載入：
   ```bash
   launchctl load ~/Library/LaunchAgents/com.oscar1206.tetherflow.plist
   ```

### 選單列應用無法開啟

1. 到「系統設定」→「隱私與安全性」
2. 允許「TetherFlow Menu」執行

### 埠號被佔用

如果 5001 被其他程式使用，修改：
- `web/backend/server.py` 中的埠號
- `menubar/tetherflow_menubar.py` 中的 `API_BASE`

---

## 🎨 進階：自定義

### 修改自動啟動延遲

編輯 `~/Library/LaunchAgents/com.oscar1206.tetherflow.plist`：

```xml
<key>StartInterval</key>
<integer>10</integer>  <!-- 開機後 10 秒啟動 -->
```

### 只在特定 Wi-Fi 時啟動

編輯 `setup_autostart.sh` 中的 plist，加入：

```xml
<key>WatchPaths</key>
<array>
    <string>/Library/Preferences/SystemConfiguration/com.apple.wifi.message-tracer.plist</string>
</array>
```

---

## ✅ 檢查清單

設定完成後，開機應該會看到：

- [ ] 選單列出現 🛡️ 圖示
- [ ] 點擊「打開 Web UI」可以開啟網頁
- [ ] 可以在選單列啟動/停止偽裝

---

**版本**: v1.0  
**更新日期**: 2025-02-06
