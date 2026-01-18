# MiddleScroller

A macOS menu bar application that enables Windows-style middle-click scrolling. Hold the middle mouse button and move the mouse to scroll in any direction.

## Features

- **Middle-click scroll mode**: Hold middle mouse button to activate scrolling, move mouse to scroll
- **Quick click passthrough**: Quick middle-clicks (< 300ms without movement) pass through to applications normally
- **Visual anchor indicator**: Shows a crosshair at the scroll anchor point
- **Adjustable scroll speed**: Choose from Slow, Normal, Fast, or Very Fast
- **Launch at login**: Option to start automatically when you log in
- **Menu bar control**: Enable/disable from the menu bar icon

## Requirements

- macOS 11.0 (Big Sur) or later
- Accessibility permissions (required for mouse event interception)

## Installation

### Download from Releases

1. Download the latest `.dmg` from [Releases](https://github.com/ryan-lowry/MiddleScroller/releases)
2. Open the `.dmg` and drag MiddleScroller to Applications
3. **First launch**: Right-click the app → "Open" → "Open" in the dialog
   
   > ⚠️ Since the app isn't signed with an Apple Developer certificate, macOS Gatekeeper will show a warning. This is normal for open-source apps distributed outside the App Store.

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/ryan-lowry/MiddleScroller.git
   cd MiddleScroller
   ```

2. Open the project in Xcode:
   ```bash
   open MiddleScroller.xcodeproj
   ```

3. Build and run (⌘R) or archive for distribution (⌘⇧R)

## Usage

1. **Launch the app** - A mouse icon appears in your menu bar
2. **Grant accessibility permissions** when prompted (required for the app to intercept mouse events)
3. **Hold middle mouse button** - A crosshair appears at the anchor point
4. **Move the mouse** - The window scrolls based on the distance and direction from the anchor
5. **Release middle button** - Scroll mode deactivates

### Quick Clicks

If you click and release the middle button quickly (within 300ms) without moving the mouse more than 5 pixels, the click passes through to the underlying application. This allows normal middle-click functionality (e.g., opening links in new tabs) to work.

### Menu Bar Options

Click the menu bar icon to access:
- **Enable/Disable** - Toggle scroll functionality
- **Preferences**
  - **Scroll Speed** - Adjust scrolling sensitivity
  - **Launch at Login** - Start automatically on login
- **Check Accessibility Permissions** - Verify permission status
- **Quit** - Exit the application

## Accessibility Permissions

MiddleScroller requires accessibility permissions to intercept mouse events. On first launch:

1. A system dialog will appear requesting permission
2. Click "Open System Preferences"
3. In Privacy & Security > Accessibility, enable MiddleScroller
4. You may need to restart the app after granting permissions

## Security & Permissions

MiddleScroller runs **without App Sandbox** because macOS requires unsandboxed access to create global event taps for intercepting mouse events. This is a system limitation for accessibility-based input monitoring apps.

The app:
- Only monitors middle mouse button events
- Stores preferences locally via `UserDefaults`
- Makes no network connections
- Collects no user data

## Debug Mode

To enable debug logging, run the app with the `MIDDLESCROLLER_DEBUG` environment variable:

```bash
MIDDLESCROLLER_DEBUG=1 /path/to/MiddleScroller.app/Contents/MacOS/MiddleScroller
```

Or in Xcode, add `MIDDLESCROLLER_DEBUG` to the scheme's environment variables.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
