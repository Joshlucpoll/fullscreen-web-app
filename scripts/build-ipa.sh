#!/bin/sh
# Builds an unsigned WebApp.ipa for SideStore/AltStore (they re-sign it on the device).
# Optional overrides of project.yml: WEB_APP_URL, APP_DISPLAY_NAME, BUNDLE_ID.
set -eu
cd "$(dirname "$0")/.."

# Each sideloaded app needs its own bundle ID, so derive one from the name if only a name is given.
if [ -z "${BUNDLE_ID:-}" ] && [ -n "${APP_DISPLAY_NAME:-}" ]; then
  slug=$(printf '%s' "$APP_DISPLAY_NAME" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]')
  [ -n "$slug" ] && BUNDLE_ID="com.example.webapp.$slug"
fi

xcodegen generate --quiet
rm -rf build WebApp.ipa
xcodebuild -project WebApp.xcodeproj -scheme WebApp -configuration Release -sdk iphoneos \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO -quiet \
  ${WEB_APP_URL:+"WEB_APP_URL=$WEB_APP_URL"} \
  ${APP_DISPLAY_NAME:+"APP_DISPLAY_NAME=$APP_DISPLAY_NAME"} \
  ${BUNDLE_ID:+"PRODUCT_BUNDLE_IDENTIFIER=$BUNDLE_ID"} \
  build

app=build/Build/Products/Release-iphoneos/WebApp.app
for key in WebAppURL CFBundleDisplayName CFBundleIdentifier; do
  printf '%s: %s\n' "$key" "$(/usr/libexec/PlistBuddy -c "Print :$key" "$app/Info.plist")"
done
mkdir -p build/ipa/Payload
cp -R "$app" build/ipa/Payload/
(cd build/ipa && zip -qry ../../WebApp.ipa Payload)
echo "Built $(pwd)/WebApp.ipa"
