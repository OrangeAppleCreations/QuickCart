# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

QuickCart is a SwiftUI-based iOS application. This is a minimal iOS project created with Xcode 26.0, using the standard SwiftUI app template structure.

## Project Structure

- **QuickCart/**: Main source directory containing Swift files
  - `QuickCartApp.swift`: Main app entry point using SwiftUI App lifecycle
  - `ContentView.swift`: Root view with basic "Hello, world!" content
  - `Assets.xcassets/`: Asset catalog for app icons and color assets
- **QuickCart.xcodeproj/**: Xcode project configuration

## Common Development Commands

### Building the Project
```bash
# Build for iOS Simulator (Debug)
xcodebuild -scheme QuickCart -destination 'platform=iOS Simulator,name=iPhone 15' build

# Build for iOS device (requires provisioning profile)
xcodebuild -scheme QuickCart -destination 'platform=iOS,name=Any iOS Device' build

# Build for Release
xcodebuild -scheme QuickCart -configuration Release build
```

### Running the App
- Open `QuickCart.xcodeproj` in Xcode and use Cmd+R to build and run
- Or use Xcode's command line tools with simulators

### Testing
This project currently has no test targets configured. To add tests, create test targets in Xcode.

## Development Guide

This project includes a comprehensive development guide:
- **DEVELOPMENT_GUIDE.md** - Master roadmap with 11 chapters
- **guides/** directory - Detailed chapter-by-chapter instructions

### Quick Start
1. Follow Chapter 1-3 for basic functionality (Weeks 1-3)
2. Each chapter has specific learning objectives and completion criteria
3. All code examples and tests are provided

## Development Notes

- Project uses Xcode 26.0 and Swift 6.0+ features with modular package architecture
- **Library** package contains all business logic in separate modules (AppFeature, Models)
- **Executable** contains only `@main` entry point for clean separation
- Uses SwiftData for persistent storage with repository pattern
- Minimum deployment target and build settings are configured in project file