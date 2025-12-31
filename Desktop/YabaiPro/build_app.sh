#!/bin/bash

# Build YabaiPro as a proper macOS app bundle

echo "🏗️  Building YabaiPro macOS App..."

# Clean previous builds
rm -rf .build
rm -rf YabaiPro.app

# Build the executable
echo "📦 Building executable..."
swift build --configuration release --product YabaiPro

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Create app bundle structure
echo "📱 Creating app bundle..."
mkdir -p YabaiPro.app/Contents/MacOS
mkdir -p YabaiPro.app/Contents/Resources

# Copy executable
cp .build/release/YabaiPro YabaiPro.app/Contents/MacOS/

# Copy Info.plist
cp Info.plist YabaiPro.app/Contents/

# Create a basic app icon (you can replace this with a proper icon later)
echo "🎨 Creating app icon..."
mkdir -p YabaiPro.app/Contents/Resources

# Create a simple 512x512 icon using a script (you can replace with proper icon)
cat > create_icon.sh << 'EOF'
#!/bin/bash
# Create a simple app icon
convert -size 512x512 xc:"#3B82F6" -fill white -pointsize 200 -gravity center -annotate +0+0 "Y" YabaiPro.app/Contents/Resources/AppIcon.png
EOF

chmod +x create_icon.sh

# Check if ImageMagick is available
if command -v convert &> /dev/null; then
    echo "🎨 Creating icon with ImageMagick..."
    ./create_icon.sh
else
    echo "⚠️  ImageMagick not found, creating placeholder icon..."
    # Create a simple placeholder icon file
    echo "Placeholder icon - replace with actual icon" > YabaiPro.app/Contents/Resources/AppIcon.png
fi

rm create_icon.sh

# Make executable
chmod +x YabaiPro.app/Contents/MacOS/YabaiPro

echo "✅ YabaiPro.app created successfully!"
echo ""
echo "🚀 To install to Applications folder:"
echo "   sudo cp -r YabaiPro.app /Applications/"
echo ""
echo "🎯 Or run directly:"
echo "   open YabaiPro.app"
echo ""
echo "📝 Note: Replace the placeholder icon with a proper app icon for better appearance"