#!/bin/bash
#
# TetherFlow 診斷腳本 - 找出無法啟用偽裝的原因
#

echo "═══════════════════════════════════════════════════════════"
echo "  🔍 TetherFlow 診斷工具"
echo "═══════════════════════════════════════════════════════════"
echo ""

# 1. 檢查系統版本
echo "📱 系統資訊:"
echo "   macOS 版本: $(sw_vers -productVersion 2>/dev/null || echo '無法取得')"
echo ""

# 2. 檢查網路介面
echo "🌐 網路介面狀態:"
networksetup -listallhardwareports 2>/dev/null | grep -A 1 "Wi-Fi" | head -4
echo ""
echo "   預設閘道介面:"
route -n get default 2>/dev/null | grep interface | sed 's/^/   /'
echo ""

# 3. 檢查目前 TTL/MTU
echo "📊 目前網路設定:"
echo "   TTL: $(sysctl net.inet.ip.ttl 2>/dev/null | awk '{print $2}' || echo '無法讀取')"
echo "   MTU: $(ifconfig en0 2>/dev/null | grep mtu | awk '{print $NF}' || echo '無法讀取')"
echo ""

# 4. 檢查 sudo 權限
echo "🔐 Sudo 權限檢查:"
if sudo -n true 2>/dev/null; then
    echo "   ✅ 目前具有免密碼 sudo 權限"
else
    echo "   ⚠️  需要輸入密碼才能使用 sudo"
    echo "      這是正常的，TetherFlow 會要求你輸入密碼"
fi
echo ""

# 5. 測試 sysctl 指令
echo "🧪 測試 sysctl 指令 (只讀取，不修改):"
if sysctl net.inet.ip.ttl >/dev/null 2>&1; then
    echo "   ✅ 可以讀取 TTL 設定"
else
    echo "   ❌ 無法讀取 TTL 設定"
fi
echo ""

# 6. 檢查網路服務狀態
echo "🔌 網路服務狀態:"
if networksetup -getinfo "Wi-Fi" 2>/dev/null | head -5 | sed 's/^/   /'; then
    :
else
    echo "   ⚠️  無法取得 Wi-Fi 資訊"
fi
echo ""

# 7. 檢查是否有其他程式正在執行
echo "⚙️  相關程序檢查:"
if pgrep -f "server.py" > /dev/null; then
    echo "   ✅ TetherFlow 伺服器正在執行"
else
    echo "   ❌ TetherFlow 伺服器未執行"
    echo "      請先執行: ./start.sh"
fi
echo ""

# 8. 檢查網頁後端資料夾
echo "📁 資料夾檢查:"
if [ -d "web/backend/data" ]; then
    echo "   ✅ 資料目錄存在"
    echo "   📄 歷史記錄: $(ls web/backend/data/*.json 2>/dev/null | wc -l) 個檔案"
else
    echo "   ⚠️  資料目錄不存在"
fi
echo ""

# 9. 檢查檔案權限
echo "🔒 檔案權限檢查:"
if [ -w "web/backend/data" ]; then
    echo "   ✅ 資料目錄可寫入"
else
    echo "   ❌ 資料目錄無法寫入"
fi
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "  診斷完成"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "💡 常見問題:"
echo "   1. 如果 TTL 顯示 64 → 偽裝未啟動 (正常狀態)"
echo "   2. 如果 TTL 顯示 65 → 偽裝已啟動"
echo "   3. 如果無法修改 TTL → 可能是 SIP (系統完整性保護)"
echo "   4. 如果網路斷線 → MTU 修改後網路需要時間重連"
echo ""
echo "🚀 啟動 TetherFlow:"
echo "   ./start.sh"
echo ""
