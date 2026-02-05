#!/bin/bash
#
# codesign-check.sh
# TetherFlow
#
# Script to validate code signing configuration
#

set -e

MAIN_APP_BUNDLE_ID="com.tetherflow.app"
HELPER_BUNDLE_ID="com.tetherflow.helper"

echo "[TetherFlow] Checking code signing configuration..."

# Check if codesign is available
if ! command -v codesign &> /dev/null; then
    echo "[TetherFlow] Error: codesign not found. Are you running on macOS?"
    exit 1
fi

# Function to check a bundle
check_bundle() {
    local bundle_path="$1"
    local bundle_name="$2"
    
    echo ""
    echo "[TetherFlow] Checking $bundle_name..."
    
    if [ ! -d "$bundle_path" ]; then
        echo "[TetherFlow] Warning: $bundle_path not found"
        return 1
    fi
    
    # Get signing info
    codesign -dvv "$bundle_path" 2>&1 | head -20
    
    # Verify signature
    if codesign --verify "$bundle_path" 2>/dev/null; then
        echo "[TetherFlow] ✓ $bundle_name signature is valid"
    else
        echo "[TetherFlow] ✗ $bundle_name signature is INVALID"
        return 1
    fi
}

# Check main app
if [ -d "TetherFlow.app" ]; then
    check_bundle "TetherFlow.app" "Main App"
else
    echo "[TetherFlow] Note: Build TetherFlow.app first to check signing"
fi

# Check helper
if [ -d "TetherFlowHelper.xpc" ]; then
    check_bundle "TetherFlowHelper.xpc" "Helper Tool"
else
    echo "[TetherFlow] Note: Build TetherFlowHelper.xpc first to check signing"
fi

echo ""
echo "[TetherFlow] Code signing check complete"
