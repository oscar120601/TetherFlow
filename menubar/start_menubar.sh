#!/bin/bash
#
# TetherFlow Menu Bar App 啟動腳本
#

echo "🛡️ TetherFlow Menu Bar App"
echo ""

# 檢查 Python
if ! command -v python3 &> /dev/null; then
    echo "❌ 錯誤: 找不到 python3"
    exit 1
fi

# 檢查 rumps
if ! python3 -c "import rumps" 2>/dev/null; then
    echo "📦 安裝 rumps 套件..."
    pip3 install rumps
fi

# 檢查伺服器是否執行
if ! curl -s http://localhost:5001/api/status > /dev/null; then
    echo "⚠️  警告: TetherFlow Web 伺服器未執行"
    echo "   請先執行: ./start.sh"
    echo ""
    read -p "是否仍要啟動選單列應用？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "🚀 啟動選單列圖示..."
cd "$(dirname "$0")"
python3 tetherflow_menubar.py &

echo "✅ 選單列圖示已啟動！"
echo "   在選單列尋找 🛡️ 圖示"
echo ""
