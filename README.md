# TetherFlow Web Edition 🛡️

TetherFlow 的 Web UI 版本 - 讓您的 MacBook 網路流量看起來像來自移動設備

## 🌟 功能特性

### ✅ 已完成 (Phase 1)
- **現代化 Web UI**
  - 響應式設計（支援手機/平板/桌面）
  - 側邊欄導航（儀表板/Profiles/歷史/設定）
  - 深色/亮色主題切換
  
- **核心功能**
  - 即時 TTL/MTU 狀態監控
  - 一鍵啟動/停止偽裝
  - Profile 管理系統
  - 操作歷史記錄
  
- **安全性**
  - UI 密碼輸入（記憶體儲存）
  - 密碼驗證後才能操作
  - 錯誤處理與通知

### 📋 計劃功能

**Phase 2** (進行中)
- [ ] 熱點自動偵測 Wi-Fi
- [ ] 網路速度監控儀表板
- [ ] Session 記錄與統計

**Phase 3** (即將推出)
- [ ] 🔐 **加密 DNS (DoH/DoT)** - 原生 macOS 支援
- [ ] 流量整形 (pfctl)
- [ ] 開機自動啟動

## 🚀 快速開始

### 安裝與啟動

```bash
# 1. 啟動 Web 伺服器
./start.sh

# 2. 開啟瀏覽器
open http://localhost:5000
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
├── cli/                      # CLI 工具（保留）
│   └── tetherflow.sh
├── start.sh                  # 啟動腳本
├── TETHERFLOW_WEB_PLAN.md    # 開發計劃
├── DOH_FEATURE_PLAN.md       # DoH 功能規劃
└── README.md
```

## 🔧 技術棧

- **後端**: Python 3.9+ + Flask
- **前端**: HTML5 + CSS3 + Vanilla JS
- **UI**: 自定義響應式設計
- **API**: RESTful API with CORS

## 🔐 加密 DNS (DoH) 功能

### 即將推出！

macOS Big Sur (11.0+) 原生支援加密 DNS，我們將在 Phase 3 加入：

**支援的 DNS 提供者：**
- 🌐 Cloudflare (1.1.1.1)
- 🛡️ Quad9 (9.9.9.9)
- 🔍 Google (8.8.8.8)
- 🚫 AdGuard DNS

**功能：**
- 一鍵啟用/停用 DoH
- 自動備份原始 DNS
- 與偽裝功能連動

## ⚠️ 安全說明

- 密碼僅儲存在瀏覽器記憶體中
- 不會永久儲存在任何地方
- 重新整理頁面後密碼清除
- 僅在本機執行（localhost）

## 📝 開發計劃

| 階段 | 內容 | 狀態 |
|------|------|------|
| Phase 1 | 基礎架構 (Web UI + API) | ✅ 完成 |
| Phase 2 | 進階功能 (監控 + Profiles) | 🚧 進行中 |
| Phase 3 | 增強功能 (DoH + 自動化) | 📅 規劃中 |

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
**版本**: v2.0 Web Edition
