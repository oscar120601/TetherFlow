# Changelog

所有版本的變更記錄。

## [2.0.0] - 2026-02-06

### 🎉 重大更新：Web Edition

TetherFlow 全面改版為 Web UI，取代原有的 Swift macOS 應用程式。

### ✨ 新增

#### Phase 1 - 基礎架構 (已完成)
- **Web 後端**: Flask REST API
  - `/api/status` - 即時狀態監控
  - `/api/start` / `/api/stop` - 控制偽裝
  - `/api/profiles` - Profile CRUD
  - `/api/history` - 操作歷史
  - `/api/save-password` - 安全密碼管理
  
- **現代化 Web UI**
  - 響應式設計（支援手機/平板/桌面）
  - 側邊欄導航（儀表板/Profiles/歷史/設定）
  - 深色/亮色主題切換
  - Toast 通知系統
  
- **Profile 管理系統**
  - 新增/編輯/刪除 Wi-Fi Profiles
  - 自定義 TTL/MTU 設定
  - 本地 JSON 儲存

- **安全性**
  - UI 密碼輸入（記憶體儲存，不落地）
  - 操作歷史記錄
  - 錯誤處理與重試機制

### 🗑️ 移除

- Swift macOS 應用程式
- Xcode 專案設定
- Privileged Helper Tool (XPC)
- SMJobBless 架構

### 🔧 變更

- 執行方式：從 `.app` 改為 Web 瀏覽器
- 架構：從 Swift 改為 Python + Flask
- UI：從 SwiftUI 改為 HTML5/CSS3/JS

### 🚀 使用方法

```bash
# 啟動 Web 伺服器
./start.sh

# 開啟瀏覽器訪問
open http://localhost:5000
```

### 📋 已知問題

- 首次使用時瀏覽器可能需要強制重新整理 (Cmd + Shift + R)

---

## [1.0.0] - 2026-02-05

### 🎉 初始版本 (Swift macOS App)

#### 核心功能
- 智能熱點識別
- TTL (65→64) 和 MTU (1400) 修改
- 流量模式淨化
- 加密 DNS (DoH/DoT)
- 監控儀表板
- 緊急停用開關
- 零狀態還原

#### 技術實現
- Swift 6.0 + SwiftUI
- SMJobBless 特權 Helper
- XPC 通訊
- CoreWLAN Wi-Fi 監控

---

## 開發路線圖

### Phase 2 (進行中)
- [ ] 熱點自動偵測 Wi-Fi
- [ ] 網路速度監控儀表板
- [ ] Session 記錄與統計

### Phase 3 (規劃中)
- [ ] 🔐 **加密 DNS (DoH/DoT)** - macOS 原生支援
- [ ] 流量整形 (pfctl)
- [ ] 開機自動啟動
- [ ] Menu Bar 圖示整合

---

**完整計劃**: 請查看 [TETHERFLOW_WEB_PLAN.md](TETHERFLOW_WEB_PLAN.md)
