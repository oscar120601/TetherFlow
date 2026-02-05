# 貢獻指南

感謝您對 TetherFlow 的興趣！本文件將指導您如何參與專案開發。

## 目錄

- [開發環境](#開發環境)
- [專案結構](#專案結構)
- [建置專案](#建置專案)
- [測試](#測試)
- [提交變更](#提交變更)
- [程式碼規範](#程式碼規範)

## 開發環境

### 系統需求

- macOS 13.0+ (Ventura)
- Xcode 15.0+ (包含 Swift 6.0)
- Apple Developer 帳號（用於簽署）

### 安裝步驟

1. **安裝 Xcode**
   ```bash
   xcode-select --install
   ```

2. **複製專案**
   ```bash
   git clone https://github.com/oscar120601/TetherFlow.git
   cd TetherFlow
   ```

3. **設定簽署**
   - 開啟 `TetherFlow.xcodeproj`
   - 選擇專案 → Signing & Capabilities
   - 設定您的 Team ID
   - 更新 Bundle Identifier

## 專案結構

```
TetherFlow/
├── TetherFlowMain/              # 主應用程式
│   ├── App/
│   │   └── TetherFlowApp.swift  # 應用程式入口
│   ├── Views/                   # SwiftUI 視圖
│   │   ├── MenuBarView.swift
│   │   ├── DashboardView.swift
│   │   ├── ProfileListView.swift
│   │   └── ProfileAddEditView.swift
│   ├── Services/                # 商業邏輯
│   │   ├── WiFiMonitor.swift
│   │   ├── ProfileStore.swift
│   │   ├── CloakingEngine.swift
│   │   ├── XPCClient.swift
│   │   ├── MetricsCollector.swift
│   │   ├── SafetyMonitor.swift
│   │   ├── TrafficShaper.swift
│   │   ├── ReversionVerifier.swift
│   │   └── SessionStore.swift
│   ├── Models/                  # 資料模型
│   │   ├── AppState.swift
│   │   ├── HotspotProfile.swift
│   │   ├── CloakingSession.swift
│   │   └── SafetyThreshold.swift
│   ├── Utils/                   # 工具類別
│   │   ├── Logger.swift
│   │   ├── KeyboardShortcuts.swift
│   │   └── ProfileImportExport.swift
│   └── Documentation.docc/      # DocC 文件
├── TetherFlowHelper/            # 特權 Helper 工具
│   ├── XPCServer.m              # XPC 伺服器
│   ├── main.m                   # 入口點
│   └── NetworkModifier.c        # 網路修改
├── Tests/                       # 測試
│   ├── TetherFlowTests/         # 單元測試
│   ├── TetherFlowUITests/       # UI 測試
│   └── IntegrationTests/        # 整合測試
└── Scripts/                     # 建置腳本
```

## 建置專案

### 使用 Xcode

```bash
# 開啟專案
open TetherFlow.xcodeproj

# 或使用 xcodebuild
xcodebuild -project TetherFlow.xcodeproj -scheme TetherFlowMain -configuration Debug build
```

### 使用建置腳本

```bash
# 建置 Debug 版本
./Scripts/build-debug.sh

# 建置 Release 版本
./Scripts/build-release.sh

# 建立安裝套件
./Scripts/build-dmg.sh
```

## 測試

### 執行所有測試

```bash
xcodebuild test -project TetherFlow.xcodeproj -scheme TetherFlowMain
```

### 執行特定測試

```bash
# 單元測試
xcodebuild test -scheme TetherFlowMain -only-testing:TetherFlowTests

# UI 測試
xcodebuild test -scheme TetherFlowMain -only-testing:TetherFlowUITests

# 整合測試
xcodebuild test -scheme TetherFlowMain -only-testing:IntegrationTests
```

### 測試規範

- 所有新功能必須包含單元測試
- UI 變更必須包含 UI 測試
- 關鍵流程必須包含整合測試
- 測試覆蓋率目標：>80%

## 提交變更

### Git 工作流程

1. **建立分支**
   ```bash
   git checkout -b feature/your-feature-name
   # 或
   git checkout -b fix/issue-description
   ```

2. **進行變更**
   - 遵循程式碼規範
   - 撰寫測試
   - 更新文件

3. **提交變更**
   ```bash
   git add .
   git commit -m "類別: 簡短描述"
   ```

4. **推送分支**
   ```bash
   git push origin feature/your-feature-name
   ```

5. **建立 Pull Request**
   - 提供清晰的描述
   - 參考相關 Issue
   - 確保所有測試通過

### 提交訊息規範

格式：`類別: 描述`

類別：
- `feat`: 新功能
- `fix`: 錯誤修復
- `docs`: 文件變更
- `style`: 程式碼格式（不影響功能）
- `refactor`: 重構
- `test`: 測試相關
- `chore`: 建置/工具變更

範例：
```
feat: 新增流量整形功能
fix: 修復斷線後無法還原的問題
docs: 更新 API 文件
test: 新增 XPC 通訊測試
```

## 程式碼規範

### Swift 規範

- 使用 Swift 6.0 語法
- 遵循 Swift API Design Guidelines
- 使用 `actor` 處理併發
- 使用 `@MainActor` 處理 UI 更新

#### 命名規範

```swift
// 類別/結構體：PascalCase
class HotspotProfile { }
struct WiFiNetwork { }

// 函式/變數：camelCase
func activateProfile(_ profile: HotspotProfile) { }
var currentNetwork: WiFiNetwork?

// 常數：大寫 camelCase 或全大寫
let MaxRetryCount = 3
let defaultTTL = 65

// 協定：描述性名稱
protocol WiFiMonitoring { }
protocol XPCServiceProtocol { }
```

#### 文件註解

```swift
/// 管理熱點 Profile 的儲存與檢索
class ProfileStore: ObservableObject {
    /// 儲存 Profile
    /// - Parameter profile: 要儲存的 Profile
    func saveProfile(_ profile: HotspotProfile) {
        // 實作
    }
}
```

### 錯誤處理

```swift
enum CloakingError: Error {
    case xpcConnectionFailed
    case networkModificationFailed(String)
    case timeout
}

do {
    try await cloakingEngine.activate(profile: profile, interface: "en0")
} catch CloakingError.timeout {
    // 處理超時
} catch {
    // 處理其他錯誤
}
```

### 併發處理

```swift
// 使用 Actor 確保執行緒安全
actor CloakingEngine {
    private var state: State = .idle
    
    func activate() async throws {
        // 自動序列化存取
    }
}

// UI 更新使用 MainActor
@MainActor
class AppState: ObservableObject {
    @Published var status: AppStatus = .idle
}
```

## 除錯

### 啟用除錯日誌

```swift
// 在 AppDelegate 或 App 初始化時
Logger.minimumLogLevel = .debug
Logger.logToConsole = true
```

### 查看日誌

```bash
# 使用 Console.app
open /Applications/Utilities/Console.app

# 或使用命令列
log stream --predicate 'subsystem == "com.tetherflow.app"'
```

### 稽核日誌位置

```
~/Library/Application Support/TetherFlow/Logs/audit.log
```

## 發布流程

### 版本號規範

採用語化版本控制（Semantic Versioning）：`主版本.次版本.修訂版本`

- 主版本：不相容的 API 變更
- 次版本：向下相容的功能新增
- 修訂版本：向下相容的問題修復

### 建立發布

1. 更新版本號
2. 更新 CHANGELOG.md
3. 建立 Git 標籤
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```
4. 使用 GitHub Releases 建立發布
5. 上傳建置好的 `.app` 和 `.dmg`

## 取得協助

- [GitHub Issues](https://github.com/oscar120601/TetherFlow/issues)
- [GitHub Discussions](https://github.com/oscar120601/TetherFlow/discussions)

## 致謝

感謝所有貢獻者讓這個專案成為可能！

---

**文件版本**: 1.0  
**最後更新**: 2026-02-05
