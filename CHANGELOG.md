# Changelog

所有版本的變更記錄。

格式基於 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.0.0/)，
版本號採用 [語化版本控制](https://semver.org/lang/zh-TW/)。

## [1.0.0] - 2026-02-05

### 新增

#### 核心功能
- 智能熱點識別 - 自動檢測配置的 Wi-Fi SSID
- 多層身份偽裝 - TTL (65→64) 和 MTU (1400) 修改
- 流量模式淨化 - 智能延遲桌面特定背景請求
- 加密 DNS - 預設 DoH/DoT (Cloudflare/Quad9)
- 監控儀表板 - 即時網路速度圖表
- 緊急停用開關 - 一鍵即時重置
- 零狀態還原 - 斷線時即時還原設定

#### 進階功能
- 流量整形 (pfctl) - 背景流量延遲/限速
- 全域鍵盤快捷鍵 - Cmd+Shift+T 切換等
- Profile 匯入/匯出 - JSON 格式
- 自定義 DNS 支援
- 會話歷史與統計
- 安全閾值與警報

#### 技術實現
- SMJobBless 特權 Helper 工具架構
- XPC 安全通訊
- Actor 併發模型
- SwiftUI + Combine 響應式 UI
- DocC 文件

### 安全性
- 程式碼簽署驗證
- 稽核日誌記錄
- 輸入消毒
- 自動設定還原

### 效能
- <0.1% CPU 使用率 (待機)
- ~35 MB 記憶體使用量
- ~3ms XPC 延遲

## [0.9.0] - Beta 測試

### 新增
- Beta 測試版本
- 基礎偽裝功能
- 手動 Profile 管理

---

**比較版本**: [Unreleased] → [1.0.0]
