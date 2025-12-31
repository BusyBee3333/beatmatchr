#!/bin/bash

echo "🔧 LOADING YABAI SCRIPTING ADDITION"
echo "==================================="
echo ""

echo "This will load the yabai scripting addition (requires sudo)..."
echo ""

sudo yabai --load-sa

echo ""
echo "🧪 TESTING SCRIPTING ADDITION..."
echo ""

if yabai --check-sa 2>/dev/null; then
    echo "✅ SUCCESS: Scripting addition is loaded!"
    echo ""
    echo "🎉 Your yabai features should now work!"
    echo "Try running your YabaiPro app and test the features."
else
    echo "❌ FAILED: Scripting addition not loaded"
    echo ""
    echo "Try running again with: sudo yabai --load-sa"
fi

