#!/bin/bash
#
# TetherFlow Web Edition - 啟動腳本
#

echo "╔══════════════════════════════════════════════════╗"
echo "║                                                  ║"
echo "║   🛡️  TetherFlow Web Edition v3.0               ║"
echo "║                                                  ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# 檢查 Python
echo "📋 檢查環境..."
if ! command -v python3 &> /dev/null; then
    echo "❌ 錯誤: 找不到 python3"
    echo "請先安裝 Python 3: https://www.python.org/downloads/"
    exit 1
fi

echo "✅ Python 已安裝"

# 檢查 pip
if ! command -v pip3 &> /dev/null; then
    echo "❌ 錯誤: 找不到 pip3"
    exit 1
fi

echo "✅ pip 已安裝"

# 安裝依賴
echo ""
echo "📦 安裝依賴套件..."
cd web/backend
pip3 install -r requirements.txt -q

if [ $? -ne 0 ]; then
    echo "⚠️  安裝依賴時出現錯誤，嘗試使用 --user 選項..."
    pip3 install -r requirements.txt --user -q
fi

echo "✅ 依賴安裝完成"

# 啟動伺服器
echo ""
echo "🚀 啟動 TetherFlow Web Server..."
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║                                                  ║"
echo "║   🌐 伺服器已啟動！                             ║"
echo "║                                                  ║"
echo "║   請在瀏覽器開啟:                                ║"
echo "║   http://localhost:5001                          ║"
echo "║                                                  ║"
echo "║   或從其他設備訪問:                               ║"
echo "║   http://$(hostname):5001                        ║"
echo "║                                                  ║"
echo "║   按 Ctrl+C 結束                                ║"
echo "║                                                  ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

python3 server.py
