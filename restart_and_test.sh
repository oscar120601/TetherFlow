#!/bin/bash
#
# TetherFlow 重啟和測試腳本
#

echo "═══════════════════════════════════════════════════════════"
echo "  🔄 TetherFlow 重啟和測試"
echo "═══════════════════════════════════════════════════════════"
echo ""

# 停止現有的伺服器
echo "🛑 停止現有伺服器..."
pkill -f "server.py" 2>/dev/null
sleep 2
echo "   ✅ 已停止"
echo ""

# 啟動新伺服器
echo "🚀 啟動伺服器..."
cd web/backend
python3 server.py &
SERVER_PID=$!
sleep 3

# 檢查伺服器是否成功啟動
if ps -p $SERVER_PID > /dev/null; then
    echo "   ✅ 伺服器已啟動 (PID: $SERVER_PID)"
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  ✅ 修復完成！請在瀏覽器開啟:"
    echo "     http://localhost:5001"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "📋 修復內容:"
    echo "   1. 改進密碼驗證機制"
    echo "   2. 改進錯誤訊息顯示"
    echo "   3. 同步執行偽裝指令（即時回饋錯誤）"
    echo "   4. 啟動失敗時自動還原 TTL"
    echo ""
    echo "📝 使用步驟:"
    echo "   1. 開啟 http://localhost:5001"
    echo "   2. 輸入您的 macOS 系統管理員密碼"
    echo "   3. 點擊「儲存密碼」"
    echo "   4. 如果密碼正確，會顯示綠色提示"
    echo "   5. 點擊「啟動偽裝」"
    echo ""
    echo "⚠️  注意事項:"
    echo "   - 必須輸入正確的 macOS 系統管理員密碼"
    echo "   - 密碼只會儲存在記憶體中，重新整理頁面後需要重新輸入"
    echo "   - 如果啟動失敗，會顯示具體錯誤原因"
    echo ""
    echo "按 Ctrl+C 停止伺服器"
    echo ""
    wait $SERVER_PID
else
    echo "   ❌ 伺服器啟動失敗"
    exit 1
fi
