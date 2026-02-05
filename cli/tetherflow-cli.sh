#!/bin/bash
#
# TetherFlow CLI - 命令列版本
# 在終端機直接控制網路偽裝
#

echo "================================"
echo "  TetherFlow CLI 工具"
echo "================================"
echo ""

show_menu() {
    echo "請選擇功能："
    echo ""
    echo "1) 🟢 啟動偽裝 (TTL=65, MTU=1400)"
    echo "2) 🔴 停止偽裝 (還原設定)"
    echo "3) 📊 檢查目前狀態"
    echo "4) ❌ 結束"
    echo ""
    echo -n "請輸入選項 (1-4): "
}

start_cloaking() {
    echo ""
    echo "🟢 正在啟動偽裝..."
    echo "   - 修改 TTL 為 65"
    echo "   - 修改 MTU 為 1400"
    echo ""
    
    # 使用 sudo 修改 TTL
    sudo sysctl net.inet.ip.ttl=65
    
    # 修改 MTU
    sudo ifconfig en0 mtu 1400
    
    echo ""
    echo "✅ 偽裝已啟動！"
    echo ""
    check_status
}

stop_cloaking() {
    echo ""
    echo "🔴 正在停止偽裝..."
    echo "   - 還原 TTL 為 64"
    echo "   - 還原 MTU 為 1500"
    echo ""
    
    sudo sysctl net.inet.ip.ttl=64
    sudo ifconfig en0 mtu 1500
    
    echo ""
    echo "✅ 已還原設定！"
    echo ""
    check_status
}

check_status() {
    echo "📊 目前網路狀態："
    echo "--------------------------------"
    
    # 檢查 TTL
    TTL=$(sysctl net.inet.ip.ttl 2>/dev/null | awk '{print $2}')
    echo "   TTL: $TTL"
    
    if [ "$TTL" = "65" ]; then
        echo "       🟢 偽裝模式 (TTL=65)"
    elif [ "$TTL" = "64" ]; then
        echo "       🔴 正常模式 (TTL=64)"
    else
        echo "       ⚠️  其他值"
    fi
    
    # 檢查 MTU
    MTU=$(ifconfig en0 2>/dev/null | grep mtu | awk '{print $4}')
    echo "   MTU: $MTU"
    
    if [ "$MTU" = "1400" ]; then
        echo "       🟢 偽裝模式 (MTU=1400)"
    elif [ "$MTU" = "1500" ]; then
        echo "       🔴 正常模式 (MTU=1500)"
    else
        echo "       ⚠️  其他值"
    fi
    
    echo ""
}

# 主選單循環
while true; do
    show_menu
    read choice
    
    case $choice in
        1)
            start_cloaking
            ;;
        2)
            stop_cloaking
            ;;
        3)
            check_status
            ;;
        4)
            echo ""
            echo "再見！"
            exit 0
            ;;
        *)
            echo ""
            echo "❌ 無效的選項，請重試"
            echo ""
            ;;
    esac
done
