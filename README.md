# TetherFlow 🛡️

<p align="center">
  <img src="Assets/AppIcon.png" width="128" height="128" alt="TetherFlow Icon">
</p>

<p align="center">
  <strong>智能網路偽裝工具 for macOS</strong><br>
  <em>讓您的 MacBook 網路流量看起來像來自移動設備</em>
</p>

<p align="center">
  <a href="#功能">功能</a> •
  <a href="#安裝">安裝</a> •
  <a href="#使用方法">使用方法</a> •
  <a href="#文件">文件</a> •
  <a href="#貢獻">貢獻</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13.0+-blue?logo=apple" alt="macOS 13.0+">
  <img src="https://img.shields.io/badge/Swift-6.0-orange?logo=swift" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
</p>

---

## 功能

### 核心功能

- 🔍 **智能熱點識別** - 自動檢測配置的 Wi-Fi SSID
- 🎭 **多層身份偽裝** - TTL (65→64) 和 MTU (1400) 修改
- 🚦 **流量模式淨化** - 智能延遲桌面特定背景請求
- 🔐 **加密 DNS** - 預設使用 DoH/DoT 防止 ISP 分析
- 📊 **監控儀表板** - 即時網路速度圖表與安全閾值
- 🚨 **緊急停用開關** - 一鍵即時重置網路堆疊
- 🔄 **零狀態還原** - 斷線時即時還原所有設定

### 進階功能

- ⏱️ **流量整形** - 基於 pfctl 的背景流量延遲/限速
- ⌨️ **全域鍵盤快捷鍵** - 無需開啟應用即可快速控制
- 📦 **Profile 匯入/匯出** - JSON 格式的分享與備份
- 🔧 **自定義 DNS 支援** - 使用者定義的 DoH/DoT 伺服器
- 📱 **會話歷史** - 資料使用量的持久化分析
- 🔔 **安全閾值** - 可配置的資料使用警報

## 系統需求

- macOS 13.0+ (Ventura)
- Apple Silicon 或 Intel Mac
- 管理員權限（用於 Helper 工具安裝）

## 安裝

### 下載預建置版本

1. 從 [Releases](https://github.com/oscar120601/TetherFlow/releases) 下載最新版本
2. 將 `TetherFlow.app` 移至應用程式資料夾
3. 啟動 TetherFlow
4. 按照螢幕指示安裝 Helper 工具

### 從原始碼建置

```bash
# 複製儲存庫
git clone https://github.com/oscar120601/TetherFlow.git
cd TetherFlow

# 使用 Xcode 建置
xcodebuild -project TetherFlow.xcodeproj -scheme TetherFlowMain -configuration Release

# 或使用建置腳本
./Scripts/build-release.sh
```

## 使用方法

### 快速開始

1. **啟動 TetherFlow** - 點擊 Menu Bar 圖示 (🛡️)
2. **配置 Profile** - 點擊「Manage Profiles」→「+」新增您的熱點 SSID
3. **啟用自動啟動** - 勾選「Auto Activate」以自動啟動偽裝
4. **連線熱點** - TetherFlow 將自動檢測並啟動

### Menu Bar 狀態

| 圖示 | 狀態 | 說明 |
|------|------|------|
| ⚪ | 閒置 | 等待配置的熱點 |
| 🟢 | 啟動中 | 偽裝已啟動並運作中 |
| 🟡 | 還原中 | 正在還原網路設定 |
| 🔴 | 錯誤 | 配置或連線錯誤 |

### 儀表板

開啟儀表板進行即時監控：

- 網路速度圖表（上傳/下載）
- 資料用量進度條
- 會話持續時間追蹤
- 安全閾值指示器
- 緊急停用開關

## 系統架構

TetherFlow 使用特權 Helper 工具架構進行安全的網路修改：

```
┌─────────────────────────────────────────────────────────┐
│                    使用者空間 (App)                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐       │
│  │MenuBar   │  │Dashboard │  │Profile Management│       │
│  │  View    │  │   View   │  │    (Add/Edit)    │       │
│  └────┬─────┘  └────┬─────┘  └────────┬─────────┘       │
│       └─────────────┼─────────────────┘                  │
│                     │                                    │
│              ┌──────▼──────┐                             │
│              │  AppState   │  @Published                  │
│              │  (Observable│  Reactive UI Updates         │
│              │   Object)   │                             │
│              └──────┬──────┘                             │
└─────────────────────┼────────────────────────────────────┘
                      │
                      │ XPC Connection (NSXPCConnection)
                      │ 已認證、已簽署
┌─────────────────────▼────────────────────────────────────┐
│          ▓          特權空間 (Root)                       │
│          ▓                                               │
│  ┌───────▼──────┐  ┌──────────────┐  ┌──────────────┐   │
│  │   XPC        │  │  Network     │  │    DNS       │   │
│  │  Server      │  │  Modifier    │  │ Configurator │   │
│  │  (Helper)    │  │  (sysctl)    │  │(networksetup)│   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## 文件

- [使用者指南](DOCS/USER_GUIDE.md) - 完整使用手冊（繁體中文）
- [API 文件](DOCS/API_DOCUMENTATION.md) - Swift API 參考
- [架構指南](DOCS/ARCHITECTURE.md) - 系統架構詳情
- [貢獻指南](CONTRIBUTING.md) - 開發指南

## 安全性

### 特權 Helper 工具

TetherFlow 使用 macOS `SMJobBless` 模式進行安全的權限提升：

- Helper 工具已簽署並受沙盒限制
- 所有 XPC 呼叫都經過驗證
- 所有特權操作的稽核日誌
- 應用程式解除安裝時自動移除

### 網路修改

所有網路修改都是暫時且可逆的：

- TTL 變更是會話限定的
- 斷線時 MTU 會還原
- DNS 設定自動還原
- Kill switch 提供即時還原

### 資料隱私

- 無遙測或分析收集
- 所有資料本地儲存
- 會話歷史不會離開設備
- 開源以確保透明度

## 效能

TetherFlow 設計為最小資源使用：

| 指標 | 目標 | 實際 |
|------|------|------|
| CPU 使用率 | <0.1% | <0.05% |
| 記憶體使用量 | <50 MB | ~35 MB |
| XPC 延遲 | <10ms | ~3ms |
| 網路開銷 | <1% | <0.5% |

## 專案結構

```
TetherFlow/
├── TetherFlowMain/           # 主應用程式
│   ├── App/                  # 應用程式入口
│   ├── Views/                # SwiftUI 視圖
│   ├── Services/             # 商業邏輯服務
│   ├── Models/               # 資料模型
│   ├── Utils/                # 工具類別
│   └── Documentation.docc/   # DocC 文件
├── TetherFlowHelper/         # 特權 Helper 工具 (XPC)
├── Tests/                    # 測試套件
│   ├── TetherFlowTests/      # 單元測試
│   ├── TetherFlowUITests/    # UI 測試
│   └── IntegrationTests/     # 整合測試
├── Scripts/                  # 建置與部署腳本
├── Resources/                # 圖示與資源
└── DOCS/                     # 文件
```

## 開發

### 開發設定

```bash
# 安裝開發工具
xcode-select --install

# 複製專案
git clone https://github.com/oscar120601/TetherFlow.git
cd TetherFlow

# 建置測試版本
xcodebuild -scheme TetherFlowMain -configuration Debug build

# 執行測試
xcodebuild test -scheme TetherFlowMain
```

### 技術棧

- **語言**: Swift 6.0, Objective-C (XPC), C (sysctl)
- **UI 框架**: SwiftUI, Combine
- **網路**: CoreWLAN, NetworkExtension
- **安全**: ServiceManagement (SMJobBless)
- **測試**: XCTest, XCUITest

## 貢獻

我們歡迎貢獻！請參閱我們的[貢獻指南](CONTRIBUTING.md)了解詳情。

### 貢獻步驟

1. Fork 這個儲存庫
2. 建立您的功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的變更 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 開啟一個 Pull Request

## 授權

TetherFlow 採用 MIT 授權條款。詳見 [LICENSE](LICENSE) 文件。

## 致謝

- [CoreWLAN](https://developer.apple.com/documentation/corewlan) - Wi-Fi 監控
- [Network Extension](https://developer.apple.com/documentation/networkextension) - 網路配置
- [SwiftUI](https://developer.apple.com/documentation/swiftui) - 使用者介面

## 相關連結

- [專案首頁](https://github.com/oscar120601/TetherFlow)
- [問題追蹤](https://github.com/oscar120601/TetherFlow/issues)
- [版本發布](https://github.com/oscar120601/TetherFlow/releases)

---

<p align="center">
  <sub>用 ❤️ 為 macOS 社群打造</sub><br>
  <sub>© 2026 TetherFlow. All rights reserved.</sub>
</p>
