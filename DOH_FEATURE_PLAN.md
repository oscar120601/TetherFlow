# macOS 內建加密 DNS (DoH/DoT) 功能規劃

## ✅ 可行性確認

**完全可行！** macOS 從 Big Sur (11.0) 開始原生支援 DoH/DoT。

## 🔧 實作方式

### 方法 1: 使用設定檔案（推薦）
macOS 支援透過 `.mobileconfig` 設定檔或 `networksetup` 指令啟用 DoH/DoT。

```bash
# 使用 networksetup 設定 DoH
sudo networksetup -setdnsservers "Wi-Fi" "empty"
sudo networksetup -setdnsservers "Wi-Fi" 1.1.1.1

# 或使用設定描述檔
```

### 方法 2: 使用設定描述檔 (Configuration Profile)
建立 XML 設定檔案，包含 DoH/DoT 設定，使用者只需雙擊安裝。

## 📋 功能規劃

### 位置: Phase 3 - T008 (取代原 DNS 設定)

**T008: 加密 DNS (DoH/DoT) 設定**

#### 功能項目：
- [ ] 偵測 macOS 版本（需 11.0+）
- [ ] 提供預設 DNS 選項：
  - Cloudflare (1.1.1.1 / 1.0.0.1)
  - Cloudflare DoH (https://cloudflare-dns.com/dns-query)
  - Quad9 (9.9.9.9 / 149.112.112.112)
  - Google (8.8.8.8 / 8.8.4.4)
  - AdGuard DNS
- [ ] 支援自定義 DoH URL
- [ ] 一鍵啟用/停用 DoH
- [ ] 自動備份/還原原始 DNS 設定

#### API 端點：
```
GET  /api/dns/status          # 取得目前 DNS 狀態
POST /api/dns/enable          # 啟用 DoH
POST /api/dns/disable         # 停用 DoH
GET  /api/dns/providers       # 取得支援的 DNS 列表
```

#### UI 設計：
- 在「設定」頁面新增「加密 DNS」區塊
- 下拉選單選擇 DNS 提供者
- 切換開關啟用/停用
- 顯示目前 DNS 狀態

## 🔒 安全性考量

1. **需要 sudo 權限**：修改 DNS 設定需要管理員密碼
2. **自動還原**：停止偽裝時自動還原原始 DNS
3. **備份機制**：修改前備份目前 DNS 設定

## 📱 Web UI 整合

```
設定頁面
├── ⚙️ 系統設定
├── 🌐 加密 DNS (新增)
│   ├── 狀態: 🔴 未啟用 / 🟢 已啟用
│   ├── 提供者: [Cloudflare ▼]
│   ├── [啟用 DoH] [停用 DoH]
│   └── 目前 DNS: 1.1.1.1
└── ℹ️ 關於
```

## ⏰ 時程規劃

**Phase 3 時加入（後天或之後）**

優先級：
1. T007: 熱點自動偵測（明天）
2. T008: 加密 DNS（後天）
3. T009: 流量整形
4. T010: 系統整合

## 💻 技術實作範例

```python
# server.py 新增

# 支援的 DNS 提供者
DNS_PROVIDERS = {
    'cloudflare': {
        'name': 'Cloudflare',
        'ips': ['1.1.1.1', '1.0.0.1'],
        'doh_url': 'https://cloudflare-dns.com/dns-query'
    },
    'quad9': {
        'name': 'Quad9',
        'ips': ['9.9.9.9', '149.112.112.112'],
        'doh_url': 'https://dns.quad9.net/dns-query'
    },
    # ... 更多
}

@app.route('/api/dns/status')
def get_dns_status():
    # 取得目前 DNS 設定
    result = subprocess.run(['scutil', '--dns'], capture_output=True, text=True)
    # 解析輸出...
    return jsonify({'success': True, 'dns': current_dns})

@app.route('/api/dns/enable', methods=['POST'])
def enable_doh():
    provider = request.json.get('provider', 'cloudflare')
    # 設定 DoH...
    return jsonify({'success': True})
```

## ✅ 結論

**完全辦得到！** 而且這是很好的安全功能。

建議安排在 **Phase 3 - T008**（後天進行）。
這樣我們明天先完成 Phase 2 的核心功能，後天再加入 DoH。
