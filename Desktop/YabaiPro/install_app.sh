#!/bin/bash

# Install YabaiPro to Applications folder

echo "📦 Installing YabaiPro to Applications folder..."

# Check if app exists
if [ ! -d "YabaiPro.app" ]; then
    echo "❌ YabaiPro.app not found! Run ./build_app.sh first."
    exit 1
fi

# Copy to Applications
sudo cp -r YabaiPro.app /Applications/

if [ $? -eq 0 ]; then
    echo "✅ YabaiPro installed successfully!"
    echo ""
    echo "🎯 You can now:"
    echo "   • Find YabaiPro in your Applications folder"
    echo "   • Drag it to your Dock for quick access"
    echo "   • Use Spotlight to search for 'YabaiPro'"
    echo ""
    echo "🚀 Launch: open /Applications/YabaiPro.app"
else
    echo "❌ Installation failed!"
    exit 1
fi


