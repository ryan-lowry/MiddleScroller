# Contributing to MiddleScroller

Thank you for your interest in contributing to MiddleScroller! This document provides guidelines for contributing.

## Reporting Bugs

Before reporting a bug, please:

1. Check existing issues to avoid duplicates
2. Include the following information:
   - macOS version
   - Steps to reproduce
   - Expected vs actual behavior
   - Any error messages or debug output (run with `MIDDLESCROLLER_DEBUG=1`)

## Suggesting Features

Feature suggestions are welcome! Please:

1. Check existing issues/discussions first
2. Describe the use case and why the feature would be valuable
3. Consider if it fits the app's scope (simple, focused middle-click scrolling)

## Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/ryan-lowry/MiddleScroller.git
   cd MiddleScroller
   ```

2. **Open in Xcode**
   ```bash
   open MiddleScroller.xcodeproj
   ```

3. **Build and run** (⌘R)

4. **Enable debug mode** by adding `MIDDLESCROLLER_DEBUG=1` to your scheme's environment variables

## Pull Request Process

1. **Fork the repository** and create a feature branch from `main`
2. **Follow the existing code style** - the project uses standard Swift conventions
3. **Test your changes** thoroughly, including:
   - Normal scroll mode activation/deactivation
   - Quick click passthrough
   - Menu bar functionality
   - Edge cases (rapid clicking, permission changes, etc.)
4. **Write clear commit messages** using conventional commits:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation changes
   - `refactor:` for code refactoring
5. **Submit the PR** with a clear description of changes

## Code Style Guidelines

- Follow Swift naming conventions (camelCase for variables/functions, PascalCase for types)
- Keep functions focused and reasonably sized
- Use meaningful variable and function names
- Add comments only where the code isn't self-explanatory
- Use `Logger.debug()` for debug output instead of `print()`

## Project Structure

```
MiddleScroller/
├── main.swift              # App entry point
├── AppDelegate.swift       # Application lifecycle
├── Core/
│   ├── MouseEventHandler.swift   # Mouse event interception
│   ├── ScrollController.swift    # Scroll event generation
│   ├── Logger.swift              # Debug logging utility
│   ├── PermissionsManager.swift  # Accessibility permissions
│   └── PreferencesManager.swift  # User preferences
└── UI/
    ├── StatusBarController.swift  # Menu bar interface
    └── AnchorOverlayWindow.swift  # Visual anchor indicator
```

## Questions?

If you have questions about contributing, feel free to open a discussion or issue.
