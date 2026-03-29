# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

WorldTrotter is a Swift iOS app from the Big Nerd Ranch "iOS Programming 6th Edition" book. It has two tabs: a temperature converter and a map view.

## Build & Run

```bash
# Build for simulator
xcodebuild -project WorldTrotter.xcodeproj -scheme WorldTrotter -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO

# Run unit tests
xcodebuild test -project WorldTrotter.xcodeproj -scheme WorldTrotter -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a single test method
xcodebuild test -project WorldTrotter.xcodeproj -scheme WorldTrotter -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WorldTrotterTests/WorldTrotterTests/testMethodName
```

Open `WorldTrotter.xcodeproj` in Xcode to build and run interactively.

## Architecture

Two-tab UITabBarController app wired entirely in `Main.storyboard`, except `MapViewController` which builds its view programmatically in `loadView()`.

- **`ConversionViewController`** — Temperature conversion screen. Uses `UITextFieldDelegate` to validate input (allows only valid decimals via `String.isValidDouble`). Conversion direction (°F↔°C) is toggled by a `UISegmentedControl` added in `viewDidLoad`. Uses `Measurement<UnitTemperature>` for the conversion math. Output label color changes to blue for sub-zero results.

- **`MapViewController`** — Full-screen `MKMapView` created in `loadView()` (no storyboard). Map type (Standard/Hybrid/Satellite) toggled by a `UISegmentedControl` pinned to the safe area. Uses `CLLocationManager` to center the map on the user's current location.

- **`ConversionDirection`** enum — Encapsulates the bidirectional conversion state (input/output units and symbols).

- **`String.isValidDouble`** extension — Validates numeric input allowing up to a configurable number of decimal places, locale-aware (`en_US`).

There are no networking, persistence, or third-party dependencies.
