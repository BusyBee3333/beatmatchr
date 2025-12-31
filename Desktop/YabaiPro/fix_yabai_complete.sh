#!/bin/bash

echo "🔧 COMPLETE YABAI FIX SCRIPT"
echo "============================"
echo ""

echo "📋 WHAT THIS SCRIPT DOES:"
echo "1. Completely disables SIP (requires restart)"
echo "2. Loads yabai scripting addition"
echo "3. Tests all features"
echo "4. Provides instructions for remaining steps"
echo ""

echo "⚠️  IMPORTANT: You MUST restart in Recovery Mode for SIP disable"
echo ""

read -p "Do you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborted"
    exit 1
fi

echo ""
echo "🔄 STEP 1: Restart in Recovery Mode"
echo "==================================="
echo ""
echo "1. Restart your Mac"
echo "2. Hold Command + R immediately when you hear startup sound"
echo "3. When Recovery Mode loads, open Terminal from menu bar"
echo "4. Run: csrutil disable"
echo "5. Restart normally"
echo ""
echo "After restart, run Step 2 below..."
echo ""

read -p "Press Enter after you complete Step 1 (restart with SIP disabled)..."

echo ""
echo "🔄 STEP 2: Load Scripting Addition"
echo "=================================="
sudo yabai --load-sa
echo ""

echo "🔄 STEP 3: Start Yabai Service"
echo "============================="
yabai --start-service
sleep 2

echo ""
echo "🔄 STEP 4: Test Features"
echo "========================"
echo ""
echo "Testing window opacity..."
yabai -m window --opacity 0.8 2>/dev/null || echo "❌ Window opacity failed (SIP still enabled?)"

echo ""
echo "Testing window animation..."
yabai -m config window_animation_duration 0.5 2>/dev/null || echo "❌ Window animation failed (Screen Recording permission needed)"

echo ""
echo "Testing auto balance..."
yabai -m config auto_balance on 2>/dev/null || echo "❌ Auto balance failed"

echo ""
echo "Testing mouse follows focus..."
yabai -m config mouse_follows_focus on 2>/dev/null || echo "❌ Mouse follows focus failed"

echo ""
echo "🔄 STEP 5: Grant Permissions"
echo "============================"
echo ""
echo "If animations fail, grant Screen Recording permission:"
echo "System Settings → Privacy & Security → Screen Recording → Add yabai"
echo ""
echo "If other features fail, grant Accessibility permission:"
echo "System Settings → Privacy & Security → Accessibility → Add yabai.osax"

echo ""
echo "🎉 SETUP COMPLETE!"
echo "=================="
echo ""
echo "Run your YabaiPro app and test the features!"
echo "If anything still doesn't work, run: ~/test_yabai_features.sh"

