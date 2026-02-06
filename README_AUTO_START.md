# 🚀 TetherFlow 開機自動啟動設定（更新版）

## ⚠️ 重要更新

由於 macOS 的「登入項目」對於自製 .app 支援不佳，我們改用 **LaunchAgent** 方式，這是更可靠的開機自動啟動方案。

---

## ✅ 已完成設定

### 1. 後端服務自動啟動
- **設定檔**: `~/Library/LaunchAgents/com.oscar1206.tetherflow.plist`
- **狀態**: ✅ 已啟用
- **PID**: `launchctl list | grep tetherflow`

### 2. 選單列自動啟動（NEW！）
- **設定檔**: `~/Library/LaunchAgents/com.oscar1206.tetherflow.menubar.plist`
- **狀態**: ✅ 已啟用
- **PID**: 3739（正在運行）

---

## 📋 如果你之前設定過「登入項目」

請手動移除：

1. 開啟「**系統設定**」→「**一般**」→「**登入項目**」
2. 找到「**TetherFlow Menu.app**」
3. 點擊「**-**」移除

---

## 🎯 新的使用方式

### 開機後會自動發生：

| 時間 | 事件 |
|------|------|
| 登入後 | Web 後端自動啟動（背景） |
| 登入後 | **選單列自動出現**（無需設定） |
| 隨時 | 點擊 🛡️ 圖示控制 TetherFlow |

### 選單功能
```
🛡️🟢 或 🛡️⚪
├── TetherFlow
├── ─────────────
├── 狀態: 偽裝已啟動
├── TTL: 65
├── MTU: 1400
├── DNS: ✅ 已啟用 (Cloudflare)
├── ─────────────
├── 🟢 啟動偽裝 + DNS
├── ⚪ 停止偽裝 + DNS
├── ─────────────
├── 🔐 加密 DNS 設定
├── 🌐 打開 Web UI
└── 結束
```

---

## 🔧 管理指令

### 查看狀態
```bash
# 查看所有 TetherFlow 服務
launchctl list | grep tetherflow

# 預期輸出：
# 741	0	com.oscar1206.tetherflow          ← 後端
# 3739	0	com.oscar1206.tetherflow.menubar  ← 選單列
```

### 停止服務
```bash
# 停止選單列
launchctl unload ~/Library/LaunchAgents/com.oscar1206.tetherflow.menubar.plist

# 停止後端
launchctl unload ~/Library/LaunchAgents/com.oscar1206.tetherflow.plist
```

### 啟動服務
```bash
# 啟動選單列
launchctl load ~/Library/LaunchAgents/com.oscar1206.tetherflow.menubar.plist

# 啟動後端
launchctl load ~/Library/LaunchAgents/com.oscar1206.tetherflow.plist
```

### 查看日誌
```bash
# 選單列日誌
tail -f /tmp/tetherflow_menubar.out.log
tail -f /tmp/tetherflow_menubar.err.log

# 後端日誌
tail -f /tmp/tetherflow.out.log
```

---

## 📁 相關檔案

```
~/Library/LaunchAgents/
├── com.oscar1206.tetherflow.plist         ← 後端服務
└── com.oscar1206.tetherflow.menubar.plist ← 選單列（新）

/Users/chanoscar/TetherFlow/
├── setup_menubar_autostart.sh   ← 選單列自動啟動設定腳本
├── setup_autostart.sh           ← 後端自動啟動設定腳本
├── README_AUTO_START.md         ← 本說明文件
└── menubar/
    └── tetherflow_menubar.py    ← 選單列程式碼
```

---

## 🆘 疑難排解

### 開機後選單列沒出現

1. **檢查服務狀態**:
   ```bash
   launchctl list | grep tetherflow
   ```
   應該看到兩個服務都在運行。

2. **手動重新載入**:
   ```bash
   cd /Users/chanoscar/TetherFlow
   ./setup_menubar_autostart.sh
   ```

3. **檢查日誌**:
   ```bash
   cat /tmp/tetherflow_menubar.err.log
   ```

### 權限問題

如果看到「無法開啟」提示：
1. 開啟「系統設定」→「隱私與安全性」
2. 允許相關權限

---

## 🎉 完成！

現在 **完全不需要設定「登入項目」**，開機後：

1. ✅ 後端服務自動啟動
2. ✅ **選單列自動出現**
3. ✅ 一鍵控制偽裝 + DNS

**重新開機測試看看吧！**

---

**更新日期**: 2026-02-06  
**版本**: 1.1.0
