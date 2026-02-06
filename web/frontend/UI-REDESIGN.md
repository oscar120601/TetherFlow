# TetherFlow UI Redesign - Modern SaaS Edition

## 設計理念

這次 UI 重設計採用現代 SaaS 風格，強調：

- **玻璃擬效果 (Glassmorphism)** - 半透明、毛玻璃質感
- **深色/淺色模式** - 完整支援 Dark Mode
- **漸層動畫** - 流暢的色彩漸層背景
- **微交互** - 細緻的動畫和過渡效果

---

## 技術架構

| 技術 | 用途 |
|------|------|
| **Tailwind CSS (CDN)** | 原子化 CSS 框架 |
| **Lucide Icons** | 現代化圖標系統 |
| **Inter Font** | 專業無襯線字體 |
| **Vanilla JS** | 原生 JavaScript，無框架依賴 |

---

## 視覺特色

### 1. Glassmorphism 效果
```css
.glass {
    background: rgba(255, 255, 255, 0.7);
    backdrop-filter: blur(12px);
    border: 1px solid rgba(255, 255, 255, 0.3);
}
```

### 2. 動態漸層背景
- 頁面背景有流動的漸層色彩
- 卡片 hover 時有上浮效果
- 狀態指示器有脈衝動畫

### 3. 動畫效果
- **fade-in**: 頁面切換淡入
- **slide-up**: 彈窗上滑
- **float**: 圖標浮動效果
- **pulse**: 狀態指示脈衝

---

## 頁面結構

```
┌─────────────────────────────────────┐
│ Sidebar    │  Main Content          │
│            │                        │
│ 🛡️ Logo   │  ┌──────────────────┐  │
│            │  │ Header           │  │
│ ─────────  │  └──────────────────┘  │
│            │                        │
│ Dashboard  │  ┌──────────────────┐  │
│ Profiles   │  │ Status Cards     │  │
│ History    │  │ ┌──┐ ┌──┐ ┌──┐  │  │
│ Settings   │  └──────────────────┘  │
│            │                        │
│ ─────────  │  ┌──────────────────┐  │
│            │  │ Password Section │  │
│ v2.0       │  └──────────────────┘  │
└────────────┴────────────────────────┘
```

---

## 元件庫

### 狀態卡片 (Status Card)
- 玻璃擬背景
- 懸浮陰影效果
- 即時狀態指示

### 按鈕 (Buttons)
- 漸層背景
- Hover 放大效果
- Loading 狀態動畫

### Toast 通知
- 滑入滑出動畫
- 成功/錯誤/警告三種類型
- 自動消失

### Modal 彈窗
- 背景模糊
- 上滑進入動畫
- 點擊外部關閉

---

## 深色模式

支援完整的深色模式切換：

```javascript
// 自動檢測系統偏好
// 手動切換按鈕
// LocalStorage 記憶偏好
```

---

## 響應式設計

| 螢幕尺寸 | 布局 |
|----------|------|
| Desktop (>1024px) | 側邊欄 + 主內容 |
| Tablet (768-1024px) | 收合側邊欄 |
| Mobile (<768px) | 底部導航 |

---

## 效能優化

- **CDN 載入** - Tailwind 和圖標使用 CDN
- **懶加載** - 圖標按需初始化
- **CSS 動畫** - 使用 GPU 加速的 transform
- **無框架** - 原生 JS，無額外依賴

---

## 使用方式

### 1. 啟動後端
```bash
cd web/backend
python server.py
```

### 2. 開啟前端
直接在瀏覽器中開啟 `index.html`，或通過後端提供靜態檔案。

### 3. 切換主題
點擊右上角的 🌙/☀️ 圖標切換深色/淺色模式。

---

## 檔案結構

```
web/frontend/
├── index.html          # 主頁面 (Tailwind + 新設計)
├── css/
│   └── style.css       # 舊版 CSS (已不使用)
├── js/
│   └── app.js          # 更新後的 JavaScript
└── UI-REDESIGN.md      # 本文檔
```

---

## 未來增強

- [ ] PWA 支援
- [ ] 離線模式
- [ ] 更多主題色彩
- [ ] 動態背景粒子效果
- [ ] 鍵盤快捷鍵支援
