# TetherFlow 開機自動啟動完整設定指南

## 📋 已完成設定總覽

| 檔案 | 用途 | 狀態 |
|------|------|------|
| `TetherFlow Menu.app` | 選單列應用程式（雙擊啟動） | ✅ 已建立 |
| `啟動選單列.command` | 終端啟動腳本（備用） | ✅ 已建立 |
| `setup_autostart.sh` | 後端服務開機自動啟動設定 | ✅ 已執行 |
| `create_menuapp.sh` | 選單列 App 建立腳本 | ✅ 已執行 |

---

## 🚀 第一步：選單列開機自動啟動

### 方法 A：加入系統登入項目（推薦）

1. 開啟「**系統設定**」→「**一般**」→「**登入項目**」

2. 點擊「**+**」按鈕

3. 選擇以下任一檔案：
   - `/Users/chanoscar/TetherFlow/TetherFlow Menu.app` ⭐ 推薦
   - 或拖曳到 Dock 從 Dock 啟動

4. 確認列表中出現「TetherFlow Menu」

### 方法 B：使用 Automator（替代方案）

如果方法 A 無效：

```bash
# 建立 Automator 應用程式
open -a Automator
```

1. 選擇「應用程式」
2. 搜尋「執行 Shell 指令碼」
3. 輸入：
   ```bash
   cd /Users/chanoscar/TetherFlow/menubar
   python3 tetherflow_menubar.py
   ```
4. 儲存為「TetherFlow Auto.app」
5. 加入登入項目

---

## ⚙️ 第二步：確認後端服務開機自動啟動

後端服務已設定為開機自動啟動，確認方式：

```bash
# 檢查服務狀態
launchctl list | grep tetherflow

# 應該看到類似輸出：
# 3908	0	com.oscar1206.tetherflow
```

### 如果沒有看到

```bash
# 手動載入服務
cd /Users/chanoscar/TetherFlow
./setup_autostart.sh
```

---

## 🔄 第三步：重啟測試

設定完成後，建議重啟電腦測試：

### 開機後應該看到：

1. **選單列出現** 🛡️ 圖示（可能需等待 5-10 秒）
2. **點擊圖示** 顯示正確狀態
3. **Web UI** 可正常訪問 http://localhost:5001

---

## 🔧 常見問題排除

### Q1: 選單列沒有自動出現

**檢查步驟：**

```bash
# 1. 檢查後端是否運行
curl http://localhost:5001/api/status

# 2. 檢查選單列是否在運行
ps aux | grep tetherflow_menubar

# 3. 手動啟動測試
cd /Users/chanoscar/TetherFlow/menubar
python3 tetherflow_menubar.py
```

### Q2: 首次執行被系統阻擋

1. 到「系統設定」→「隱私與安全性」
2. 找到「TetherFlow Menu」被阻擋的提示
3. 點擊「仍要開啟」

### Q3: 如何停止開機自動啟動

**停止後端服務：**
```bash
launchctl unload ~/Library/LaunchAgents/com.oscar1206.tetherflow.plist
```

**停止選單列：**
- 到「系統設定」→「一般」→「登入項目」
- 移除「TetherFlow Menu」

---

## 📁 相關檔案位置

```
/Users/chanoscar/TetherFlow/
├── TetherFlow Menu.app          # 選單列應用程式
├── 啟動選單列.command            # 備用啟動腳本
├── setup_autostart.sh           # 自動啟動設定腳本
├── create_menuapp.sh            # App 建立腳本
├── AUTO_START_SETUP.md          # 本說明文件
└── menubar/
    └── tetherflow_menubar.py    # 選單列程式碼

~/Library/LaunchAgents/
└── com.oscar1206.tetherflow.plist  # 開機啟動設定
```

---

## 🎉 完成！

設定完成後，每次開機：
1. ✅ 後端服務自動啟動（背景運行）
2. ✅ 選單列自動出現（登入項目）
3. ✅ 一鍵控制偽裝 + DNS

**版本**: v1.0  
**更新日期**: 2026-02-06
