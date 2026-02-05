# TetherFlow Web Edition 🛡️

TetherFlow 的 Web UI 版本 - 讓您的 MacBook 網路流量看起來像來自移動設備

## 快速開始

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

# 或使用進階 CLI
./cli/tetherflow-cli.sh
```

## 功能特性

### ✅ 已完成 (Phase 1)

- **現代化 Web UI**
  - 響應式設計（支援手機/平板）
  - 側邊欄導航
  - 深色/亮色主題
  
- **核心功能**
  - 即時 TTL/MTU 狀態監控
  - 一鍵啟動/停止偽裝
  - Profile 管理系統
  - 操作歷史記錄
  
- **安全性**
  - UI 密碼輸入（記憶體儲存）
  - 密碼驗證後才能操作
  - 錯誤處理與通知

### 📋 計劃功能 (Phase 2-3)

- [ ] 熱點自動偵測
- [ ] 網路速度監控
- [ ] DNS 設定
- [ ] 流量整形
- [ ] 開機自動啟動

## 專案結構

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
│   ├── tetherflow.sh
│   └── tetherflow-cli.sh
├── start.sh                  # 啟動腳本
└── README.md
```

## 技術棧

- **後端**: Python + Flask
- **前端**: HTML5 + CSS3 + Vanilla JS
- **UI**: 自定義響應式設計
- **CORS**: 支援跨域請求

## 安全說明

- 密碼僅儲存在瀏覽器記憶體中
- 不會永久儲存在任何地方
- 重新整理頁面後密碼清除
- 僅在本機執行（localhost）

## 系統需求

- macOS 13.0+
- Python 3.9+
- 現代瀏覽器（Chrome, Safari, Firefox）

## License

MIT License
