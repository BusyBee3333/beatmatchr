#!/bin/bash

echo "🎬 TESTING WINDOW ANIMATIONS"
echo "==========================="
echo ""

echo "Setting animation duration to 0.5 seconds..."
yabai -m config window_animation_duration 0.5

if [ $? -eq 0 ]; then
    echo "✅ SUCCESS: Window animations enabled!"
    echo ""
    echo "🎉 Your YabaiPro window animations should now work!"
else
    echo "❌ FAILED: Still need Screen Recording permission"
    echo ""
    echo "Make sure you granted the permission when prompted."
fi

echo ""
echo "Current animation settings:"
yabai -m config window_animation_duration 2>/dev/null && echo "Duration: $(yabai -m config window_animation_duration)" || echo "Cannot read config"

