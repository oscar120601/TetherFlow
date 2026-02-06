# TetherFlow Menu Bar App

使用 Python rumps 開發的 macOS 選單列圖示應用。

## 功能

- 🛡️ 在選單列顯示 TetherFlow 狀態
- 🟢/⚪ 圖示顏色表示偽裝狀態
- 快速啟動/停止偽裝
- 即時顯示 TTL/MTU 數值
- 一鍵打開 Web UI

## 安裝

```bash
# 安裝 rumps
pip3 install rumps

# 或者使用 requirements.txt
pip3 install -r requirements.txt
```

## 使用

### 方法 1: 直接執行

```bash
cd menubar
python3 tetherflow_menubar.py
```

### 方法 2: 使用啟動腳本

```bash
cd menubar
./start_menubar.sh
```

## 選單說明

| 選單項目 | 功能 |
|---------|------|
| 🛡️ 圖示 | 顯示目前狀態（🟢 偽裝中 / ⚪ 未偽裝 / ❌ 離線） |
| 狀態 | 顯示偽裝狀態和登入狀態 |
| TTL/MTU | 顯示目前的網路設定值 |
| 🟢 啟動偽裝 | 啟動偽裝（需要先在 Web UI 儲存密碼） |
| 🔴 停止偽裝 | 停止偽裝 |
| 🌐 打開 Web UI | 在瀏覽器開啟 Web 介面 |
| 🔄 立即更新 | 手動更新狀態 |
| 結束 | 結束選單列應用 |

## 需求

- macOS 13.0+
- Python 3.9+
- rumps
- TetherFlow Web 伺服器（需要執行在 localhost:5001）

## 注意事項

- 需要先啟動 TetherFlow Web 伺服器 (`./start.sh`)
- 需要在 Web UI 中儲存密碼才能控制偽裝
- 選單列應用每 5 秒自動更新狀態

## 打包為獨立應用（可選）

```bash
# 安裝 py2app
pip3 install py2app

# 打包
python3 setup.py py2app

# 打包後的應用在 dist/ 目錄中
```
