# TetherFlow 多語言支援 (i18n)

## 功能概述

TetherFlow 現在支援**中英文雙語切換**，讓使用者可以根據偏好選擇介面語言。

## 語言支援

| 語言 | 代碼 | 狀態 |
|------|------|------|
| 繁體中文 | `zh-TW` | ✅ 完整支援 |
| English | `en` | ✅ 完整支援 |

## 切換方式

### 1. 語言切換按鈕
- 位置：頂部導航欄（主題切換按鈕左側）
- 顯示：顯示當前可切換的語言（中文顯示「EN」，英文顯示「中文」）
- 點擊即可切換

### 2. 自動記憶
- 系統會自動記憶使用者的語言偏好
- 下次開啟時自動套用
- 使用 LocalStorage 儲存

## 技術實現

### 檔案結構
```
web/frontend/
├── index.html          # HTML 模板（含 data-i18n 屬性）
├── js/
│   ├── i18n.js         # 國際化核心模組
│   └── app.js          # 更新後的應用程式
└── I18N-README.md      # 本文檔
```

### 翻譯機制

#### 1. HTML 靜態翻譯
```html
<span data-i18n="nav.dashboard">Dashboard</span>
```
- 使用 `data-i18n` 屬性標記需要翻譯的元素
- 自動在語言切換時更新

#### 2. JavaScript 動態翻譯
```javascript
const t = (key) => typeof i18n !== 'undefined' ? i18n.t(key) : key;
showToast(t('password.saved'));
```
- 使用 `i18n.t(key)` 方法獲取翻譯
- 支援動態內容（如 Toast 通知、狀態更新）

#### 3. Placeholder 翻譯
```html
<input data-i18n-placeholder="password.placeholder" placeholder="Enter password...">
```
- 使用 `data-i18n-placeholder` 屬性翻譯輸入框提示文字

### 翻譯檔案格式

```javascript
const translations = {
    'zh-TW': {
        'nav.dashboard': '儀表板',
        'nav.profiles': 'Wi-Fi 配置',
        // ...
    },
    'en': {
        'nav.dashboard': 'Dashboard',
        'nav.profiles': 'Wi-Fi Profiles',
        // ...
    }
};
```

## 新增語言

如需新增其他語言，請按照以下步驟：

### 1. 在 `i18n.js` 中添加翻譯
```javascript
const translations = {
    'zh-TW': { /* ... */ },
    'en': { /* ... */ },
    'ja': {  // 新增日語
        'nav.dashboard': 'ダッシュボード',
        // ...
    }
};
```

### 2. 更新語言切換邏輯（如需要）

### 3. 測試所有頁面

## 翻譯鍵命名規範

```
<模組>.<元件>.<屬性>

範例：
- nav.dashboard          - 導航選單
- page.dashboard.title   - 頁面標題
- password.placeholder   - 密碼輸入提示
- control.start          - 控制按鈕
- toast.success          - Toast 通知
- common.save            - 通用詞彙
```

## 注意事項

1. **動態內容**：JavaScript 動態生成的內容需要使用 `i18n.t()` 方法
2. **日期格式**：根據語言自動調整日期顯示格式
3. **圖標**：圖標不隨語言變化，保持統一
4. **響應式**：語言切換不影響響應式布局

## 未來增強

- [ ] 更多語言支援（日語、韓語等）
- [ ] 自動檢測瀏覽器語言
- [ ] 語言包懶加載
- [ ] RTL（從右至左）語言支援
