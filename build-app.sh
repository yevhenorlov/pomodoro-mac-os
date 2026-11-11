#!/bin/bash
# Builds Pomodoro.app in the repository root.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
BIN="$(swift build -c release --show-bin-path)/Pomodoro"

APP="Pomodoro.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/Pomodoro"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Pomodoro</string>
    <key>CFBundleDisplayName</key><string>Pomodoro</string>
    <key>CFBundleIdentifier</key><string>local.pomodoro.timer</string>
    <key>CFBundleExecutable</key><string>Pomodoro</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

# Ad-hoc signature so Gatekeeper treats the local build as a coherent bundle.
if ! codesign --force --sign - "$APP" >/dev/null 2>&1; then
    echo "warning: ad-hoc codesign failed; the app may still run locally" >&2
fi

echo "Built $(pwd)/$APP — drag it to /Applications or run: open $APP"
