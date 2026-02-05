# TetherFlow Web UI 版本規劃

## 目標
將 TetherFlow 從 macOS Swift 應用程式改為 **純 Web UI 版本**，保留 CLI 工具作為備用。

## 新的系統架構

```
TetherFlow/
├── web/                          # Web UI 主程式
│   ├── backend/
│   │   ├── server.py            # Flask/FastAPI 伺服器
│   │   ├── network_controller.py # 網路控制邏輯
│   │   └── requirements.txt
│   ├── frontend/
│   │   ├── index.html           # 主頁面
│   │   ├── css/
│   │   │   └── style.css
│   │   └── js/
│   │       └── app.js
│   └── README.md
├── cli/                          # CLI 版本（保留）
│   ├── tetherflow-cli.sh
│   └── tetherflow-advanced.sh
├── docs/                         # 文件
│   ├── README.md
│   ├── USER_GUIDE.md
│   └── API.md
└── install.sh                    # 安裝腳本
```

## Phase 1: 基礎架構 (今天完成)

### T001: 建立 Web 後端
- [ ] 使用 Flask/FastAPI 建立 REST API
- [ ] 實作 sudo 密碼管理（記憶體儲存）
- [ ] API 端點：
  - `GET /api/status` - 取得 TTL/MTU 狀態
  - `POST /api/start` - 啟動偽裝（需密碼）
  - `POST /api/stop` - 停止偽裝（需密碼）
  - `POST /api/save-password` - 儲存密碼（僅記憶體）
- [ ] 錯誤處理與日誌

### T002: 建立現代化 Web UI
- [ ] 使用 HTML5 + CSS3 + Vanilla JS
- [ ] 響應式設計（支援手機/平板）
- [ ] 功能：
  - 即時狀態顯示（TTL/MTU）
  - 密碼輸入與儲存
  - 啟動/停止按鈕
  - 操作歷史記錄
  - 通知/提示系統
- [ ] 深色/亮色主題切換

### T003: 整合測試
- [ ] 確保 Web UI 可以正常控制網路設定
- [ ] 測試密碼管理功能
- [ ] 錯誤處理測試

## Phase 2: 進階功能

### T004: Profile 管理系統
- [ ] 建立 Profile 資料模型
- [ ] 使用本地儲存（LocalStorage）
- [ ] 功能：
  - 新增/編輯/刪除 Profile
  - 設定 SSID、TTL、MTU
  - 自動啟動選項
  - Profile 切換

### T005: 即時監控儀表板
- [ ] 網路速度監控（使用 speedtest-cli）
- [ ] 資料用量統計
- [ ] 圖表顯示（Chart.js）
- [ ] 會計時器

### T006: Session 記錄
- [ ] 記錄每次偽裝會話
- [ ] 儲存到本地 JSON
- [ ] 歷史記錄查詢
- [ ] 資料統計

## Phase 3: 增強功能

### T007: 熱點自動偵測
- [ ] 使用系統指令偵測 Wi-Fi SSID
- [ ] 自動匹配 Profile
- [ ] 自動啟動/停止偽裝
- [ ] 通知提醒

### T008: DNS 設定
- [ ] 支援修改 DNS 伺服器
- [ ] 預設 DNS 選項（Cloudflare、Quad9）
- [ ] 自定義 DNS

### T009: 流量整形
- [ ] 使用 pfctl 控制背景流量
- [ ] 圖形化規則設定
- [ ] 啟用/停用開關

### T010: 系統整合
- [ ] 開機自動啟動
- [ ] Menu Bar 圖示（使用 Python rumps）
- [ ] 全域快捷鍵

## 要保留的檔案

```
TetherFlow/
├── tetherflow-cli.sh           ✅ 保留
├── TetherFlowSimple/           ✅ 保留（簡單 CLI 版本）
│   ├── Package.swift
│   └── Sources/
├── TetherFlowWeb/              ✅ 保留（目前的 Web 版本）
│   └── web_server.py
├── README.md                   ✅ 更新
├── LICENSE                     ✅ 保留
└── CHANGELOG.md                ✅ 更新
```

## 要刪除的檔案

```
TetherFlow/
├── TetherFlowMain/             ❌ 刪除（Swift 主程式）
├── TetherFlowHelper/           ❌ 刪除（XPC Helper）
├── TetherFlow.xcodeproj/       ❌ 刪除（Xcode 專案）
├── Tests/                      ❌ 刪除（Swift 測試）
├── Scripts/                    ❌ 刪除（建置腳本）
├── Resources/                  ❌ 刪除
├── project.yml                 ❌ 刪除
├── setup-and-build.sh          ❌ 刪除
├── build/                      ❌ 刪除
└── .specify/                   ❌ 刪除
```

## 安裝與使用

### 安裝
```bash
git clone https://github.com/oscar120601/TetherFlow.git
cd TetherFlow
./install.sh
```

### 啟動 Web UI
```bash
cd web
python3 server.py
# 開啟瀏覽器 http://localhost:8080
```

### 使用 CLI
```bash
./tetherflow-cli.sh
```

## 技術棧

- **後端**: Python + Flask/FastAPI
- **前端**: HTML5 + CSS3 + JavaScript (Vanilla)
- **UI 框架**: 可選使用 Vue.js 或 React
- **圖表**: Chart.js
- **樣式**: Tailwind CSS 或自訂 CSS

## 時間規劃

- **今天**: Phase 1 (T001-T003) - 基礎功能
- **明天**: Phase 2 (T004-T006) - 進階功能
- **後續**: Phase 3 (T007-T010) - 增強功能
