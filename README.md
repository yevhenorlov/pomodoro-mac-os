# Pomodoro

A small native macOS Pomodoro timer built with SwiftUI. No dependencies, no network access, and no data stored.

- 25-minute work sessions and 5-minute breaks
- When a session ends, a looping alarm plays and the window comes to the front until you respond
- The Dock badge shows the minutes left

## Requirements

- macOS 13 (Ventura) or later
- Swift 5.9+ (Xcode 15 or the Xcode Command Line Tools)

## Build

```sh
./build-app.sh
open Pomodoro.app
```

This creates an ad-hoc-signed `Pomodoro.app` in the repository root. Drag it to `/Applications` to install it.

To run it without building the app bundle:

```sh
swift run
```

## Usage

| State   | Actions                                                                     |
|---------|-----------------------------------------------------------------------------|
| Ready   | **Start Work** (Return) or **Start Break**                                  |
| Running | **Stop**                                                                    |
| Ringing | **Start Break** / **Start Work** (Return) to begin the next phase, or **Stop** |

Closing the window quits the app.

## License

[MIT](LICENSE)
