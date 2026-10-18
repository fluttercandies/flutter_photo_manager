#!/bin/sh
# Runs the Darwin unit tests in darwin/photo_manager/Tests on macOS (needs Xcode).
#
# The plugin's Swift package depends on the FlutterFramework package, which only
# exists inside a Flutter app build, so the tests cannot be a test target of
# darwin/photo_manager/Package.swift. They cover Foundation-only sources, which
# are compiled here together with the tests into an XCTest bundle that xctest runs.
set -eu

root=$(cd "$(dirname "$0")/../.." && pwd)
sources="$root/darwin/photo_manager/Sources/photo_manager/core"
tests="$root/darwin/photo_manager/Tests/photo_managerTests"
frameworks="$(xcrun --sdk macosx --show-sdk-platform-path)/Developer/Library/Frameworks"
bundle="$(mktemp -d)/photo_managerTests.xctest"

mkdir -p "$bundle/Contents/MacOS"
cat > "$bundle/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>photo_managerTests</string>
	<key>CFBundleIdentifier</key>
	<string>com.fluttercandies.photo-managerTests</string>
	<key>CFBundlePackageType</key>
	<string>BNDL</string>
</dict>
</plist>
PLIST

xcrun --sdk macosx clang -fobjc-arc -fmodules -bundle \
  -F "$frameworks" -framework XCTest -Xlinker -rpath -Xlinker "$frameworks" \
  -I "$sources" "$sources/PMFileHelper.m" "$tests"/*.m \
  -o "$bundle/Contents/MacOS/photo_managerTests"

xcrun xctest "$bundle"
