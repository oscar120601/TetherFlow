# TetherFlow 使用者手冊

## 目錄

1. [簡介](#簡介)
2. [安裝與設定](#安裝與設定)
3. [快速開始](#快速開始)
4. [功能說明](#功能說明)
5. [進階功能](#進階功能)
6. [故障排除](#故障排除)
7. [常見問題](#常見問題)

---

## 簡介

**TetherFlow** 是一個 macOS Menu Bar 應用程式，用於在連接到特定移動熱點時自動偽裝網路封包，讓 MacBook 的網路流量看起來像是來自移動設備。

### 主要功能

- 🔒 **智能情境感知** - 自動識別配置的 Wi-Fi SSID
- 🎭 **多層身份偽裝** - 修改 TTL 和 MTU 匹配移動設備特徵
- 🚦 **流量模式淨化** - 智能延遲桌面特定背景請求
- 🔐 **加密 DNS** - 預設使用 DoH/DoT 防止 ISP 分析
- 📊 **監控儀表板** - 即時網路速度圖表與安全閾值
- 🚨 **緊急停用開關** - 一鍵即時重置網路堆疊
- 🔄 **零狀態還原** - 斷線時即時還原所有設定

---

## 安裝與設定

### 系統需求

- macOS 13.0+ (Ventura)
- Apple Silicon 或 Intel Mac
- 管理員權限（用於安裝 Helper）

### 安裝步驟

1. 下載最新版本的 `TetherFlow.app`
2. 將應用程式拖曳到「應用程式」資料夾
3. 首次啟動時，前往「系統偏好設定」→「安全性與隱私」→「一般」
4. 點擊「仍要開啟」以允許執行

### 安裝 Helper 工具

首次執行 TetherFlow 時，會自動提示安裝 Privileged Helper Tool：

1. 點擊 Menu Bar 圖示開啟 TetherFlow
2. 點擊「Manage Profiles」
3. 系統會提示輸入管理員密碼
4. 輸入密碼後，Helper 工具會自動安裝

> **注意**：Helper 工具是必需的，用於修改系統網路參數。沒有它，TetherFlow 無法執行偽裝功能。

---

## 快速開始

### 第一步：新增熱點 Profile

1. 點擊 Menu Bar 中的 TetherFlow 圖示
2. 點擊「Manage Profiles...」
3. 點擊右上角的「+」按鈕
4. 輸入您的手機熱點 SSID（例如：`MyHotspot5G`）
5. 根據需要調整設定：
   - **Auto Activate**（自動啟動）- 連線時自動啟動偽裝
   - **Traffic Shaping**（流量整形）- 延遲背景更新
   - **Encrypted DNS**（加密 DNS）- 使用 Cloudflare 或 Quad9
6. 點擊「Save」儲存

### 第二步：連線測試

1. 將 MacBook 連線到您剛才配置的熱點
2. TetherFlow 圖示會變為 🟢 **綠色**（表示偽裝已啟動）
3. 點擊圖示查看狀態：
   - 顯示「Cloaking Active」
   - 顯示目前的 TTL 和 MTU 設定

### 第三步：使用儀表板監控

1. 點擊「Dashboard...」開啟儀表板
2. 查看即時網路速度圖表
3. 監控資料用量進度條
4. 查看會話統計資訊

---

## 功能說明

### Menu Bar 介面

```
┌─────────────────────────────────────┐
│  🟢 Cloaking Active                 │
│  Network: MyHotspot5G               │
├─────────────────────────────────────┤
│  Current Connection                 │
│  Network: MyHotspot5G               │
│  Session Time: 00:23:45             │
├─────────────────────────────────────┤
│  [Dashboard...]                     │
│  [Manage Profiles...]   3 configured│
├─────────────────────────────────────┤
│  Quick Select                       │
│  ⚡ MyHotspot5G (Auto)              │
│  ○ OfficeWiFi                       │
├─────────────────────────────────────┤
│  [Kill Switch]  [Quit]              │
└─────────────────────────────────────┘
```

#### 狀態圖示說明

| 圖示 | 狀態 | 說明 |
|------|------|------|
| ⚪ 灰色 | Idle | 待命中，未連線到配置的熱點 |
| 🟢 綠色 | Cloaking Active | 偽裝已啟動 |
| 🟡 黃色 | Reverting | 正在還原設定 |
| 🔴 紅色 | Error | 發生錯誤 |

### Dashboard 儀表板

#### 即時速度監控

- **上傳速度** - 即時上傳速度（藍色線）
- **下載速度** - 即時下載速度（綠色線）
- **歷史圖表** - 最近 30 秒的流量趨勢

#### 資料用量

- **Session Total** - 本次會話總資料用量
- **Uploaded** - 上傳資料量
- **Downloaded** - 下載資料量
- **進度條** - 視覺化顯示用量比例

#### 安全閾值

- **Hourly Limit** - 每小時資料限制（預設 10 GB）
- **Daily Limit** - 每日資料限制（預設 50 GB）
- **Risk Level** - 風險等級（綠/黃/橙/紅）

### Profile 管理

#### 新增 Profile

1. 點擊「Manage Profiles」
2. 點擊「+」按鈕
3. 設定以下參數：

**基本設定**
- **SSID** - Wi-Fi 名稱（必填）
- **Target TTL** - 目標 TTL（預設 65）
- **Target MTU** - 目標 MTU（預設 1400）

**進階設定**
- **Auto Activate** - 自動啟動偽裝
- **Traffic Shaping** - 啟用流量整形
- **Hourly Threshold** - 每小時警報閾值（GB）
- **Daily Threshold** - 每日警報閾值（GB）
- **Encrypted DNS** - 啟用加密 DNS
- **DNS Provider** - Cloudflare / Quad9 / Custom

#### 編輯 Profile

1. 在 Profile 列表中點擊要編輯的項目
2. 修改設定
3. 點擊「Save」儲存變更

#### 刪除 Profile

1. 在 Profile 列表中向左滑動
2. 點擊「Delete」
3. 確認刪除

---

## 進階功能

### 流量整形（Traffic Shaping）

當偽裝啟動時，TetherFlow 可以延遲特定類型的網路流量，讓您的連線看起來更像移動設備。

**支援的流量類型**

| 類型 | 延遲 | 限速 |
|------|------|------|
| macOS Updates | 500ms | 500 Kbps |
| iCloud Sync | 200ms | 1000 Kbps |
| App Store | 300ms | 2000 Kbps |
| Time Machine | 100ms | - |

**啟用方式**

1. 編輯 Profile
2. 勾選「Enable Traffic Shaping」
3. 儲存 Profile

### 自定義 DNS

除了預設的 Cloudflare 和 Quad9，您還可以新增自定義 DNS 伺服器：

1. 編輯 Profile
2. 選擇「Custom」DNS Provider
3. 輸入 DNS 伺服器 IP
4. 選擇性輸入 DoH/DoT 設定

### 鍵盤快捷鍵

**預設快捷鍵**

| 快捷鍵 | 功能 |
|--------|------|
| `⌘⇧T` | 切換偽裝 |
| `⌘⇧⌥⎋` | 緊急停用 |
| `⌘⇧D` | 開啟儀表板 |
| `⌘⇧P` | 開啟 Profile 管理 |

**修改快捷鍵**

1. 開啟 Settings（設定）
2. 選擇「Keyboard Shortcuts」
3. 點擊要修改的快捷鍵
4. 按下新的鍵盤組合

### Profile 匯入/匯出

**匯出 Profile**

1. 開啟「Manage Profiles」
2. 點擊「Export」按鈕
3. 選擇儲存位置
4. 檔案格式為 JSON

**匯入 Profile**

1. 開啟「Manage Profiles」
2. 點擊「Import」按鈕
3. 選擇 JSON 檔案
4. 確認匯入

> **注意**：匯入時會自動跳過重複的 SSID。

---

## 故障排除

### 無法安裝 Helper

**症狀**：提示「Helper installation failed」

**解決方案**：
1. 確保您有管理員權限
2. 檢查系統完整性保護（SIP）是否開啟
3. 手動刪除舊版 Helper：
   ```bash
   sudo rm -rf /Library/PrivilegedHelperTools/com.tetherflow.helper
   ```
4. 重新啟動 TetherFlow

### 偽裝無法啟動

**症狀**：連線到熱點但圖示未變綠

**解決方案**：
1. 檢查 Profile 的 SSID 是否正確
2. 確認「Auto Activate」已勾選
3. 手動點擊 Profile 啟動
4. 檢查 Helper 是否已安裝：
   - 開啟「Manage Profiles」
   - 查看右上角狀態指示器

### 斷線後無法還原

**症狀**：斷線後網路連線異常

**解決方案**：
1. 點擊「Kill Switch」強制還原
2. 在終端機手動還原：
   ```bash
   sudo sysctl net.inet.ip.ttl=64
   sudo networksetup -setMTU en0 1500
   ```
3. 重新啟動 Mac

### 儀表板速度顯示為 0

**症狀**：速度圖表顯示為 0

**原因**：
- 未啟用偽裝
- 系統未授權網路監控

**解決方案**：
1. 確保已連線到熱點並啟用偽裝
2. 檢查「系統偏好設定」→「安全性與隱私」→「隱私」→「輔助使用」中是否允許 TetherFlow

---

## 常見問題

### Q: TetherFlow 會影響我的網路速度嗎？

**A**: 會有極小的影響。修改 TTL/MTU 本身不會降低速度，但流量整形功能會延遲某些背景流量。

### Q: 使用 TetherFlow 是否合法？

**A**: TetherFlow 本身是中性的網路工具。但您需要自行確保遵守 ISP 的服務條款。

### Q: 為什麼需要 Helper 工具？

**A**: 修改系統網路參數（如 TTL）需要 root 權限。Helper 工具是 macOS 推薦的安全方式來執行這些操作。

### Q: 可以同時配置多個熱點嗎？

**A**: 可以。您可以為每個經常使用的熱點建立 Profile。

### Q: 如何確認偽裝正在運作？

**A**: 在終端機執行：
```bash
sysctl net.inet.ip.ttl
networksetup -getMTU en0
```
應該看到 TTL=65 和 MTU=1400。

### Q: 斷線後 TTL 會自動還原嗎？

**A**: 會。TetherFlow 會自動偵測斷線並還原所有設定。您也可以點擊「Kill Switch」手動還原。

### Q: 支援哪些 macOS 版本？

**A**: macOS 13.0 (Ventura) 及以上版本。

### Q: 如何完全移除 TetherFlow？

**A**: 
1. 退出 TetherFlow
2. 刪除應用程式
3. 刪除 Helper：
   ```bash
   sudo rm -rf /Library/PrivilegedHelperTools/com.tetherflow.helper
   sudo rm -f /Library/LaunchDaemons/com.tetherflow.helper.plist
   ```
4. 刪除設定檔：
   ```bash
   rm -rf ~/Library/Preferences/com.tetherflow.app
   ```

---

## 技術支援

如需更多協助，請：

1. 查看 [GitHub Issues](https://github.com/oscar120601/TetherFlow/issues)
2. 提交問題報告，包含：
   - macOS 版本
   - TetherFlow 版本
   - 問題描述
   - 相關日誌（位於 `~/Library/Logs/TetherFlow/`）

---

**文件版本**: 1.0  
**最後更新**: 2026-02-05
