#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION=${VERSION:-0.1.0}

swift build -c release
BIN="$(swift build -c release --show-bin-path)/Fluent"
APP=build/Fluent.app

rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build/icon
cp "$BIN" "$APP/Contents/MacOS/Fluent"
sed "s/__VERSION__/$VERSION/" Resources/Info.plist > "$APP/Contents/Info.plist"

swift Tools/makeicon.swift build/icon
mkdir -p Resources/AppIcon.icon/Assets
cp build/icon/glyph.png Resources/AppIcon.icon/Assets/
if xcrun actool Resources/AppIcon.icon --compile "$APP/Contents/Resources" \
    --output-format human-readable-text --notices --warnings --errors \
    --output-partial-info-plist build/icon/partial.plist \
    --app-icon AppIcon --include-all-app-icons \
    --target-device mac --minimum-deployment-target 26.0 --platform macosx; then
  echo "icon: layered"
else
  echo "icon: fallback"
  mkdir build/AppIcon.iconset
  for s in 16 32 128 256 512; do
    sips -z $s $s build/icon/fallback.png --out build/AppIcon.iconset/icon_${s}x${s}.png >/dev/null
    sips -z $((s*2)) $((s*2)) build/icon/fallback.png --out build/AppIcon.iconset/icon_${s}x${s}@2x.png >/dev/null
  done
  iconutil -c icns build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
fi

if [ -n "${SIGN_IDENTITY:-}" ]; then
  codesign --force --options runtime --timestamp --entitlements Resources/Fluent.entitlements --sign "$SIGN_IDENTITY" "$APP"
else
  codesign --force --sign - "$APP"
fi
(cd build && ditto -c -k --keepParent Fluent.app Fluent.zip)

# dmg
DMG=build/Fluent.dmg
mkdir -p build/dmg/.background
cp -R "$APP" build/dmg/
ln -s /Applications build/dmg/Applications
swift Tools/dmgbg.swift build/dmg/.background/bg.png
hdiutil create -volname Fluent -fs HFS+ -srcfolder build/dmg -ov -format UDRW build/rw.dmg >/dev/null
DEV=$(hdiutil attach -readwrite -noverify -noautoopen build/rw.dmg | awk 'NR==1 {print $1}')
osascript <<'OSA' || echo "dmg: plain layout"
tell application "Finder"
  tell disk "Fluent"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 120, 860, 520}
    set opts to the icon view options of container window
    set arrangement of opts to not arranged
    set icon size of opts to 128
    set background picture of opts to file ".background:bg.png"
    set position of item "Fluent.app" of container window to {165, 200}
    set position of item "Applications" of container window to {495, 200}
    close
    open
    update without registering applications
    delay 2
    close
  end tell
end tell
OSA
sync
echo "dmg device: $DEV"
hdiutil detach "$DEV" >/dev/null || { sleep 3; hdiutil detach -force "$DEV" >/dev/null; }
hdiutil convert build/rw.dmg -format UDZO -o "$DMG" >/dev/null
rm -rf build/rw.dmg build/dmg
echo "built $APP $DMG"

if [ -n "${SIGN_IDENTITY:-}" ]; then
  codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG"
  if [ -n "${NOTARY_KEY:-}" ]; then
    xcrun notarytool submit "$DMG" --key "$NOTARY_KEY" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER" --wait
    xcrun stapler staple "$DMG"
  fi
fi
