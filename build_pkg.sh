#!/bin/bash
set -e

# Configuration
APP_NAME="ClipboardApp"
PKG_NAME="ClipboardAppInstaller.pkg"
BUNDLE_ID="com.rainielmontanez.clipboardapp"
VERSION="1.0.0"
INSTALL_LOCATION="/Applications"

echo "--- Building $APP_NAME in Release Mode ---"

# 1. Build the project using Swift Package Manager
swift build -c release

# Find the binary path more reliably
BIN_PATH=$(swift build -c release --show-bin-path)
BINARY_PATH="$BIN_PATH/$APP_NAME"

# Fallback: Search for the binary if the direct path fails
if [ ! -f "$BINARY_PATH" ]; then
    echo "Binary not found at $BINARY_PATH, searching in .build directory..."
    SEARCHED_PATH=$(find .build -type f -name "$APP_NAME" | grep "release" | head -n 1)
    if [ -n "$SEARCHED_PATH" ]; then
        BINARY_PATH="$SEARCHED_PATH"
    fi
fi

if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: Build failed. Binary not found in .build directory."
    exit 1
fi

echo "Using binary at: $BINARY_PATH"

echo "--- Creating App Bundle ---"

# 2. Create the .app bundle structure
# Try to remove existing bundle, fail if permissions denied (user must fix manually)
if [ -d "$APP_NAME.app" ]; then
    rm -rf "$APP_NAME.app" || { echo "Error: Failed to remove existing $APP_NAME.app. You may need to run 'sudo rm -rf $APP_NAME.app'"; exit 1; }
fi

mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"

# 3. Copy the binary into the bundle
cp "$BINARY_PATH" "$APP_NAME.app/Contents/MacOS/"

# 4. Create the Info.plist file
cat > "$APP_NAME.app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "--- Generating Package Installer ---"

# 5. Build the .pkg
# Ensure scripts directory exists
if [ ! -d "scripts" ]; then
    mkdir -p scripts
    cat > scripts/postinstall <<EOF
#!/bin/bash
APP_PATH="/Applications/$APP_NAME.app"
EXECUTABLE_PATH="\$APP_PATH/Contents/MacOS/$APP_NAME"
chmod +x "\$EXECUTABLE_PATH"
CURRENT_USER=\$(stat -f%Su /dev/console)
if [ -n "\$CURRENT_USER" ] && [ "\$CURRENT_USER" != "root" ]; then
    USER_ID=\$(id -u "\$CURRENT_USER")
    launchctl asuser "\$USER_ID" open "\$APP_PATH"
fi
exit 0
EOF
    chmod +x scripts/postinstall
fi

pkgbuild --identifier "$BUNDLE_ID" \
         --version "$VERSION" \
         --install-location "$INSTALL_LOCATION" \
         --component "$APP_NAME.app" \
         --scripts "scripts" \
         "$PKG_NAME"

echo "--------------------------------------------------"
echo "Done! Installer created: $PKG_NAME"
echo "You can now distribute this .pkg file."
echo "--------------------------------------------------"
