#!/bin/bash
#
# setup-helper.sh
# TetherFlow
#
# Script to install the privileged helper tool
# This is called automatically by SMJobBless on first run
#

set -e

HELPER_BUNDLE_ID="com.tetherflow.helper"
HELPER_NAME="TetherFlowHelper"
MAIN_APP_BUNDLE_ID="com.tetherflow.app"

echo "[TetherFlow] Setting up privileged helper tool..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "[TetherFlow] Error: This script must run with root privileges"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Path to the embedded helper
HELPER_PATH="${SCRIPT_DIR}/../TetherFlowHelper"

if [ ! -f "$HELPER_PATH" ]; then
    echo "[TetherFlow] Error: Helper binary not found at $HELPER_PATH"
    exit 1
fi

# Install to privileged location
HELPER_INSTALL_PATH="/Library/PrivilegedHelperTools/${HELPER_BUNDLE_ID}"

echo "[TetherFlow] Installing helper to $HELPER_INSTALL_PATH"
cp "$HELPER_PATH" "$HELPER_INSTALL_PATH"
chmod 755 "$HELPER_INSTALL_PATH"
chown root:wheel "$HELPER_INSTALL_PATH"

# Install launchd plist
LAUNCHD_PLIST_PATH="/Library/LaunchDaemons/${HELPER_BUNDLE_ID}.plist"

echo "[TetherFlow] Installing launchd plist to $LAUNCHD_PLIST_PATH"
cat > "$LAUNCHD_PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${HELPER_BUNDLE_ID}</string>
    <key>MachServices</key>
    <dict>
        <key>${HELPER_BUNDLE_ID}</key>
        <true/>
    </dict>
    <key>ProgramArguments</key>
    <array>
        <string>${HELPER_INSTALL_PATH}</string>
    </array>
</dict>
</plist>
EOF

chmod 644 "$LAUNCHD_PLIST_PATH"
chown root:wheel "$LAUNCHD_PLIST_PATH"

echo "[TetherFlow] Helper tool setup complete"
exit 0
