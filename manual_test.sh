#!/bin/bash
#
# 手動測試 TetherFlow 指令
# 這個腳本幫助你確認系統是否支援修改 TTL/MTU
#

echo "═══════════════════════════════════════════════════════════"
echo "  🧪 TetherFlow 手動測試"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "這個腳本會測試修改 TTL 和 MTU，需要你的密碼。"
echo ""

# 測試前狀態
echo "📊 測試前的網路設定:"
echo "   TTL: $(sysctl net.inet.ip.ttl 2>/dev/null | awk '{print $2}')"
echo "   MTU: $(ifconfig en0 2>/dev/null | grep mtu | awk '{print $NF}')"
echo ""

# 測試 TTL 修改
echo "🧪 測試 1: 修改 TTL 為 65..."
if sudo sysctl net.inet.ip.ttl=65 2>&1 | grep -q "65"; then
    echo "   ✅ TTL 修改成功"
    NEW_TTL=$(sysctl net.inet.ip.ttl 2>/dev/null | awk '{print $2}')
    echo "   目前 TTL: $NEW_TTL"
else
    echo "   ❌ TTL 修改失敗"
    echo "   錯誤: $(sudo sysctl net.inet.ip.ttl=65 2>&1)"
fi
echo ""

# 測試 MTU 修改
echo "🧪 測試 2: 修改 MTU 為 1400..."
if sudo ifconfig en0 mtu 1400 2>&1 | grep -q ""; then
    sleep 1
    NEW_MTU=$(ifconfig en0 2>/dev/null | grep mtu | awk '{print $NF}')
    if [ "$NEW_MTU" = "1400" ]; then
        echo "   ✅ MTU 修改成功"
    else
        echo "   ⚠️  MTU 指令執行但未生效 (目前: $NEW_MTU)"
    fi
    echo "   目前 MTU: $NEW_MTU"
else
    echo "   ❌ MTU 修改失敗"
fi
echo ""

# 測試後狀態
echo "📊 偽裝狀態 (TTL=65 且 MTU=1400 表示已偽裝):"
echo "   TTL: $(sysctl net.inet.ip.ttl 2>/dev/null | awk '{print $2}')"
echo "   MTU: $(ifconfig en0 2>/dev/null | grep mtu | awk '{print $NF}')"
echo ""

# 還原
echo "🔄 還原設定..."
sudo sysctl net.inet.ip.ttl=64 >/dev/null 2>&1
sleep 1
sudo ifconfig en0 mtu 1500 >/dev/null 2>&1
echo "   ✅ 已還原 (TTL=64, MTU=1500)"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "  測試完成"
echo "═══════════════════════════════════════════════════════════"
echo ""

# 檢查結果
FINAL_TTL=$(sysctl net.inet.ip.ttl 2>/dev/null | awk '{print $2}')
FINAL_MTU=$(ifconfig en0 2>/dev/null | grep mtu | awk '{print $NF}')

if [ "$FINAL_TTL" = "64" ] && [ "$FINAL_MTU" = "1500" ]; then
    echo "✅ 測試成功！你的系統支援 TetherFlow"
    echo ""
    echo "🚀 現在可以啟動 TetherFlow:"
    echo "   ./restart_and_test.sh"
else
    echo "⚠️  還原可能未完成"
    echo "   手動還原指令:"
    echo "   sudo sysctl net.inet.ip.ttl=64"
    echo "   sudo ifconfig en0 mtu 1500"
fi
echo ""
