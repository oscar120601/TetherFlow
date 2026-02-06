# TetherFlow Web Edition 🛡️

TetherFlow 的 Web UI 版本 - 讓您的 MacBook 網路流量看起來像來自移動設備

## 🌟 功能特性

### ✅ 已完成 (Phase 1-3)
- **現代化 Web UI**
  - 響應式設計（支援手機/平板/桌面）
  - 側邊欄導航（儀表板/Profiles/歷史/設定）
  - 深色/亮色主題切換
  - 中英文多語言支援
  
- **核心功能**
  - 即時 TTL/MTU 狀態監控
  - 一鍵啟動/停止偽裝
  - Profile 管理系統
  - 操作歷史記錄
  - Session 統計與分析
  
- **Phase 2 功能**
  - Wi-Fi 自動偵測
  - 網路速度測試
  - Session 記錄持久化
  
- **Phase 3 功能** 🆕
  - 🔐 **加密 DNS (DoH/DoT)**
  - 流量整形 (Traffic Shaping)
  - 開機自動啟動 / 選單列圖示
  
- **選單列應用** 🛡️
  - Python + rumps 開發
  - 即時狀態顯示（🟢 偽裝中 / ⚪ 未偽裝）
  - 快速啟動/停止偽裝
  - 一鍵打開 Web UI
  
- **安全性**
  - UI 密碼輸入（記憶體儲存）
  - 密碼驗證後才能操作
  - 錯誤處理與通知

### 📋 版本資訊

**v3.0** - Phase 3 完成
- Wi-Fi 自動偵測與自動啟動
- 5 種加密 DNS 提供者支援
- 流量整形規則管理
- 系統整合設定

## 🚀 快速開始

### 安裝與啟動

```bash
# 1. 啟動 Web 伺服器
./start.sh

# 2. 開啟瀏覽器
open http://localhost:5000
```

### 使用選單列圖示

```bash
# 啟動選單列應用（Python rumps）
cd menubar
./start_menubar.sh
```

### 使用 CLI 版本

```bash
# 使用簡單 CLI
./cli/tetherflow.sh
```

## 📸 介面預覽

```
┌─────────────────────────────────────────┐
│  🛡️ TetherFlow                    ⚙️  │
├─────────────────────────────────────────┤
│  📊 儀表板                               │
│                                         │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  │ TTL: 64 │ │ MTU:1500│ │ 🔴 正常 │  │
│  │  正常   │ │  正常   │ │         │  │
│  └─────────┘ └─────────┘ └─────────┘  │
│                                         │
│  🔐 管理員密碼                            │
│  [輸入密碼...] [儲存]                    │
│                                         │
│  [🟢 啟動偽裝]  [🔴 停止偽裝]            │
└─────────────────────────────────────────┘
```

## 📁 專案結構

```
TetherFlow/
├── web/                      # Web UI 主程式
│   ├── backend/
│   │   ├── server.py        # Flask REST API
│   │   └── requirements.txt
│   └── frontend/
│       ├── index.html       # 主頁面
│       ├── css/style.css    # 樣式
│       └── js/app.js        # 前端邏輯
├── menubar/                  # 選單列應用（rumps）
│   ├── tetherflow_menubar.py
│   └── start_menubar.sh
├── cli/                      # CLI 工具
│   └── tetherflow.sh
├── start.sh                  # 啟動腳本
├── TETHERFLOW_WEB_PLAN.md    # 開發計劃
└── README.md
```

## 📚 文件

| 文件 | 說明 |
|------|------|
| [📖 功能說明](./DOCS/FEATURES.md) | 詳細功能介紹與使用指南 |
| [⚡ 快速參考](./DOCS/QUICK_REFERENCE.md) | 一頁式功能速查卡片 |
| [🔄 流程圖](./DOCS/FLOW_DIAGRAMS.md) | 視覺化功能流程與架構 |
| [👤 使用者手冊](./DOCS/USER_GUIDE.md) | 完整使用教學 |
| [🔌 API 文件](./DOCS/API_DOCUMENTATION.md) | 開發者 API 參考 |
| [🏗️ 架構說明](./DOCS/ARCHITECTURE.md) | 系統設計文件 |

## 🔧 技術棧

- **後端**: Python 3.9+ + Flask
- **前端**: HTML5 + CSS3 + Vanilla JS
- **選單列**: Python + rumps
- **UI**: 自定義響應式設計
- **API**: RESTful API with CORS

## 🔐 加密 DNS (DoH) 功能

✅ **已完成！**

macOS Big Sur (11.0+) 原生支援加密 DNS，已在 Phase 3 實作：

**支援的 DNS 提供者：**
- 🌐 Cloudflare (1.1.1.1 / 1.0.0.1)
- 👨‍👩‍👧‍👦 Cloudflare Family (1.1.1.3) - 過濾成人內容
- 🔍 Google (8.8.8.8 / 8.8.4.4)
- 🛡️ Quad9 (9.9.9.9) - 安全導向
- 🔧 OpenDNS (208.67.222.222)
- ✏️ 自訂 DNS 伺服器

**功能：**
- 一鍵啟用/停用加密 DNS
- 保護瀏覽隱私，防止 ISP 追蹤
- 可選擇不同 DNS 提供者

## ⚠️ 安全說明

- 密碼僅儲存在瀏覽器記憶體中
- 不會永久儲存在任何地方
- 重新整理頁面後密碼清除
- 僅在本機執行（localhost）

## 📝 開發計劃

| 階段 | 內容 | 狀態 |
|------|------|------|
| Phase 1 | 基礎架構 (Web UI + API) | ✅ 完成 |
| Phase 2 | 進階功能 (監控 + Profiles) | ✅ 完成 |
| Phase 3 | 增強功能 (DoH + 自動化) | ✅ 完成 |

### Phase 3 功能詳情
- ✅ Wi-Fi 自動偵測與自動啟動
- ✅ 加密 DNS (DoH/DoT) 支援
- ✅ 流量整形 (Traffic Shaping)
- ✅ 系統整合設定 (自動啟動、選單列)

## 💻 系統需求

- macOS 13.0+ (Ventura)
- Python 3.9+
- 現代瀏覽器（Chrome, Safari, Firefox）

## 🤝 貢獻

歡迎提交 Issue 和 PR！

## 📄 License

MIT License

---

**GitHub**: https://github.com/oscar120601/TetherFlow  
**版本**: v3.1 Web Edition + Menu Bar
