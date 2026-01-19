# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MiddleScroller is a macOS menu bar utility enabling Windows-style middle-click scrolling. It intercepts middle mouse button events and converts them into scroll events based on cursor movement from an anchor point. The app requires Accessibility permissions for global event taps and runs as a menu bar-only app (no dock icon).

## Build Commands

```bash
# Open project in Xcode
open MiddleScroller/MiddleScroller.xcodeproj

# Build Release
cd MiddleScroller && xcodebuild -scheme MiddleScroller -configuration Release -derivedDataPath build -destination 'platform=macOS' clean build

# Run tests
cd MiddleScroller && xcodebuild -scheme MiddleScroller -destination 'platform=macOS' test

# Local build with DMG
./build_local.sh
```

## Debug Logging

Enable debug output by setting environment variable:
```bash
MIDDLESCROLLER_DEBUG=1 /path/to/MiddleScroller.app/Contents/MacOS/MiddleScroller
```

## Architecture

### Core Components (MiddleScroller/Core/)

- **MouseEventHandler.swift** - Global mouse event interception using `CGEvent.tapCreate()`. Implements click decision protocol: 300ms timer decides between quick-click passthrough (synthetic events) vs scroll mode activation based on 5px movement threshold.

- **ScrollController.swift** - Runs at 60 Hz. Calculates scroll vectors from anchor point with 10px dead zone. Applies perpendicular suppression (50% threshold) to prevent accidental cross-axis scrolling.

- **PreferencesManager.swift** - Singleton managing UserDefaults storage. Settings: `scrollSpeedMultiplier` (0.5-2.0), `launchAtLogin`.

- **PermissionsManager.swift** - Accessibility permission handling via `AXIsProcessTrusted()` APIs.

- **Logger.swift** - Debug logging gated by `MIDDLESCROLLER_DEBUG` env var, only active in DEBUG builds.

### UI Components (MiddleScroller/UI/)

- **StatusBarController.swift** - Menu bar UI with enable toggle, speed preferences, permissions check.

- **AnchorOverlayWindow.swift / AnchorOverlayView.swift** - Visual anchor indicator (48x48 transparent window with crosshair).

### App Lifecycle (AppDelegate.swift)

Initialization: Creates overlay → MouseEventHandler → StatusBarController → Checks permissions → Polls every 2s if permissions pending. Cleanup in `applicationWillTerminate`.

## Key Technical Constraints

- **App Sandbox disabled** - Required for `CGEventTap` global event interception
- **LSUIElement=true** - Menu bar only, no dock icon
- **macOS 11.0+ required** - Deployment target
- **Coordinate systems** - CGEvent (Y=0 at top) vs NSWindow (Y=0 at bottom) - overlay window handles conversion

## Testing

Unit tests cover: PreferencesManager defaults/persistence, ScrollController dead zone/vector calculations/suppression logic, Logger environment gating. Tests located in `MiddleScroller/MiddleScrollerTests/`.
