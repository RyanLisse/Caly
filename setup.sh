#!/bin/bash
set -e

APP_BUNDLE="/Applications/Caly.app"

echo "🚀 Building Caly..."
swift build -c release

echo "📦 Creating app bundle at $APP_BUNDLE..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp .build/release/caly "$APP_BUNDLE/Contents/MacOS/caly"

# Create Info.plist for app bundle
cat > "$APP_BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.ryanlisse.caly</string>
    <key>CFBundleName</key>
    <string>Caly</string>
    <key>CFBundleDisplayName</key>
    <string>Caly</string>
    <key>CFBundleExecutable</key>
    <string>caly</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSCalendarsUsageDescription</key>
    <string>Caly needs access to your calendar to list, search, and create events.</string>
    <key>NSCalendarsFullAccessUsageDescription</key>
    <string>Caly needs full access to your calendar to read and write events.</string>
</dict>
</plist>
PLIST

echo "🔐 Signing app bundle..."
codesign --force --deep --options runtime --sign - --entitlements Caly.entitlements "$APP_BUNDLE"

echo "🔗 Creating symlink in /usr/local/bin..."
sudo ln -sf "$APP_BUNDLE/Contents/MacOS/caly" /usr/local/bin/caly

echo "✅ Done!"
echo ""
echo "If this is your first install, launch once to grant permissions:"
echo "  open -a Caly"
echo ""
echo "Then use from terminal: caly list"
