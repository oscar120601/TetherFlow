#!/bin/bash
#
# TetherFlow 自動啟動設定腳本
# 設定開機自動啟動 + 選單列應用
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.oscar1206.tetherflow.plist"

echo "╔══════════════════════════════════════════════════╗"
echo "║                                                  ║"
echo "║   🛡️  TetherFlow 自動啟動設定                   ║"
echo "║                                                  ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# 1. 建立 LaunchAgents 目錄
echo "📁 建立 LaunchAgents 目錄..."
mkdir -p "$LAUNCH_AGENTS_DIR"

# 2. 建立 plist 檔案
echo "📝 建立啟動設定檔..."
cat > "$LAUNCH_AGENTS_DIR/$PLIST_NAME" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.oscar1206.tetherflow</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>SCRIPT_DIR/web/backend/server.py</string>
    </array>
    
    <key>WorkingDirectory</key>
    <string>SCRIPT_DIR</string>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <true/>
    
    <key>StandardOutPath</key>
    <string>/tmp/tetherflow.out.log</string>
    
    <key>StandardErrorPath</key>
    <string>/tmp/tetherflow.err.log</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
EOF

# 替換 SCRIPT_DIR 為實際路徑
sed -i '' "s|SCRIPT_DIR|$SCRIPT_DIR|g" "$LAUNCH_AGENTS_DIR/$PLIST_NAME"

# 3. 安裝選單列應用依賴
echo "📦 安裝選單列應用依賴..."
cd "$SCRIPT_DIR/menubar"
pip3 install -r requirements.txt -q

# 4. 建立選單列啟動腳本（Automator 用）
echo "🎯 建立選單列啟動器..."
cat > "$SCRIPT_DIR/啟動選單列.command" << EOF
#!/bin/bash
cd "$SCRIPT_DIR/menubar"
python3 tetherflow_menubar.py
EOF
chmod +x "$SCRIPT_DIR/啟動選單列.command"

# 5. 載入 LaunchAgent
echo "🚀 啟動服務..."
launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_NAME" 2>/dev/null || true
launchctl load "$LAUNCH_AGENTS_DIR/$PLIST_NAME"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║                                                  ║"
echo "║   ✅ 設定完成！                                 ║"
echo "║                                                  ║"
echo "║   服務狀態:                                      ║"
echo "║"
launchctl list | grep com.oscar1206.tetherflow | awk '{print "║   PID: " $1 " | 狀態: " $2}'
echo "║                                                  ║"
echo "║   📋 下次開機時：                                ║"
echo "║   • Web 伺服器會自動啟動                        ║"
echo "║   • 手動雙擊「啟動選單列.command」              ║"
echo "║                                                  ║"
echo "║   🔧 管理指令：                                  ║"
echo "║   • 停止服務: launchctl unload ~/Library/LaunchAgents/$PLIST_NAME"
echo "║   • 啟動服務: launchctl load ~/Library/LaunchAgents/$PLIST_NAME"
echo "║   • 查看日誌: tail -f /tmp/tetherflow.out.log"
echo "║                                                  ║"
echo "╚══════════════════════════════════════════════════╝"
