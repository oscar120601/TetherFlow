#!/bin/bash
#
# 建立 TetherFlow Menu Bar 應用程式 (.app)
# 讓你可以把應用放到 Dock 或 Launchpad
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="TetherFlow Menu.app"
APP_PATH="$SCRIPT_DIR/$APP_NAME"

echo "🛠️  建立 TetherFlow 選單列應用程式..."

# 建立應用程式包結構
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# 建立啟動腳本
cat > "$APP_PATH/Contents/MacOS/TetherFlow Menu" << 'EOF'
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$SCRIPT_DIR/menubar"

# 檢查伺服器是否運行
if ! curl -s http://localhost:5001/api/status > /dev/null 2>&1; then
    osascript -e 'display notification "正在啟動 TetherFlow 伺服器..." with title "TetherFlow"'
    
    # 啟動後端
    cd "$SCRIPT_DIR/web/backend"
    nohup python3 server.py > /tmp/tetherflow.out.log 2>&1 &
    
    # 等待伺服器啟動
    sleep 3
fi

# 啟動選單列
python3 tetherflow_menubar.py
EOF

chmod +x "$APP_PATH/Contents/MacOS/TetherFlow Menu"

# 建立 Info.plist
cat > "$APP_PATH/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>TetherFlow Menu</string>
    <key>CFBundleIdentifier</key>
    <string>com.oscar1206.tetherflow.menu</string>
    <key>CFBundleName</key>
    <string>TetherFlow Menu</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# 嘗試建立一個簡單的圖示（使用 emoji 轉換）
# 如果使用者有安裝 imagemagick，可以產生圖示
cat > "$APP_PATH/Contents/Resources/AppIcon.txt" << 'EOF'
🛡️
EOF

echo ""
echo "✅ 應用程式建立完成！"
echo ""
echo "📍 位置: $APP_PATH"
echo ""
echo "📋 使用方法："
echo "   1. 雙擊「$APP_NAME」啟動選單列"
echo "   2. 可拖曳到 Dock 或應用程式資料夾"
echo "   3. 開機自動啟動：系統設定 → 一般 → 登入項目"
echo ""
echo "⚠️  注意：首次執行可能需要到「系統設定 → 隱私與安全性」允許"
