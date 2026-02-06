#!/bin/bash
#
# TetherFlow 選單列開機自動啟動設定
# 使用 LaunchAgent 方式（比 .app 更可靠）
#

set -e

SCRIPT_DIR="/Users/chanoscar/TetherFlow"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.oscar1206.tetherflow.menubar.plist"

echo "╔══════════════════════════════════════════════════╗"
echo "║                                                  ║"
echo "║   🛡️  TetherFlow 選單列自動啟動設定             ║"
echo "║                                                  ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# 建立 plist 檔案
echo "📝 建立 LaunchAgent 設定檔..."
cat > "$LAUNCH_AGENTS_DIR/$PLIST_NAME" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.oscar1206.tetherflow.menubar</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>$SCRIPT_DIR/menubar/tetherflow_menubar.py</string>
    </array>
    
    <key>WorkingDirectory</key>
    <string>$SCRIPT_DIR/menubar</string>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <true/>
    
    <key>StandardOutPath</key>
    <string>/tmp/tetherflow_menubar.out.log</string>
    
    <key>StandardErrorPath</key>
    <string>/tmp/tetherflow_menubar.err.log</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
        <key>PYTHONPATH</key>
        <string>$SCRIPT_DIR/menubar</string>
    </dict>
</dict>
</plist>
EOF

echo "✅ 設定檔已建立"
echo ""

# 如果正在運行，先停止
pkill -f tetherflow_menubar.py 2>/dev/null || true

# 移除舊的登入項目中的 .app（因為我們改用 LaunchAgent）
echo "📝 提示：請手動從「系統設定 → 一般 → 登入項目」移除 TetherFlow Menu.app"
echo ""

# 載入服務
echo "🚀 啟動選單列服務..."
launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_NAME" 2>/dev/null || true
launchctl load "$LAUNCH_AGENTS_DIR/$PLIST_NAME"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║                                                  ║"
echo "║   ✅ 設定完成！                                 ║"
echo "║                                                  ║"
echo "║   下次開機時，選單列會自動啟動！                ║"
echo "║                                                  ║"
echo "║   🔧 管理指令：                                  ║"
echo "║   • 查看狀態: launchctl list | grep tetherflow  ║"
echo "║   • 停止服務: launchctl unload ~/Library/LaunchAgents/$PLIST_NAME"
echo "║   • 啟動服務: launchctl load ~/Library/LaunchAgents/$PLIST_NAME"
echo "║                                                  ║"
echo "║   📋 查看日誌：                                  ║"
echo "║   • tail -f /tmp/tetherflow_menubar.out.log     ║"
echo "║   • tail -f /tmp/tetherflow_menubar.err.log     ║"
echo "║                                                  ║"
echo "╚══════════════════════════════════════════════════╝"
