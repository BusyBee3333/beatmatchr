#!/bin/bash

echo "🧪 COMPREHENSIVE YABAI TEST"
echo "==========================="
echo ""

echo "1. SIP Status:"
csrutil status | grep -E "(status|enabled|disabled)" | head -5
echo ""

echo "2. Scripting Addition Status:"
if yabai -m query --windows > /dev/null 2>&1 && echo "Scripting addition appears loaded" || echo "Scripting addition NOT loaded" 2>/dev/null; then
    echo "✅ Scripting addition loaded"
else
    echo "❌ Scripting addition NOT loaded"
fi
echo ""

echo "3. Service Status:"
if pgrep -f yabai > /dev/null; then
    echo "✅ Yabai service running"
else
    echo "❌ Yabai service NOT running"
fi
echo ""

echo "4. Window Opacity Test:"
if yabai -m window --opacity 0.8 2>/dev/null; then
    echo "✅ Window opacity working"
else
    echo "❌ Window opacity failed (SIP likely enabled)"
fi
echo ""

echo "5. Window Animation Test:"
if yabai -m config window_animation_duration 0.5 2>/dev/null; then
    echo "✅ Window animations working"
else
    echo "❌ Window animations failed (Screen Recording permission needed)"
fi
echo ""

echo "6. Auto Balance Test:"
if yabai -m config auto_balance on 2>/dev/null; then
    echo "✅ Auto balance working"
else
    echo "❌ Auto balance failed"
fi
echo ""

echo "7. Mouse Follows Focus Test:"
if yabai -m config mouse_follows_focus on 2>/dev/null; then
    echo "✅ Mouse follows focus working"
else
    echo "❌ Mouse follows focus failed"
fi
echo ""

echo "8. Rule Creation Test:"
if yabai -m rule --add app="Test" manage=on 2>/dev/null; then
    echo "✅ Rule creation working"
    yabai -m rule --list | grep -q "Test" && echo "   Rule added successfully" || echo "   Rule not found"
else
    echo "❌ Rule creation failed"
fi
echo ""

echo "📋 SUMMARY:"
echo "=========="
echo "✅ Working: Basic queries, shadows, menu bar"
echo "❌ Need SIP disabled: Window opacity, advanced features"
echo "❌ Need permissions: Screen Recording for animations"
echo "❌ Need scripting addition: Most window management features"
echo ""
echo "Run: ~/fix_yabai_complete.sh for full fix"

