# WeLinked

WeLinked is a real-time notification, status, and location synchronization application.

## Features

- **Alert System**: One-tap alert triggers (Red, Green, Blue, Yellow) with full-screen overlays, local sound playbacks, and haptic feedback.
- **Alert Status Lifecycle**: 4 distinct synchronization states (`created`, `delivered`, `seen`, and `acknowledged`) + archiving.
- **Client Status Synchronization**: Real-time telemetry monitoring including battery percentage, GPS status, connectivity state, and active presence.
- **Live Coordinates**: Interfacing with Google Maps to display client location updates based on movement thresholds.
- **Background Execution**: Background services utilizing foreground tasks to maintain synchronization on Android devices.

## Tech Stack

- **Frontend**: Flutter (Dart)
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Backend Services**: Firebase Auth, Cloud Firestore, Firebase Cloud Messaging
- **Background Processing**: flutter_foreground_task

## Setup

For configuration, Firebase project initialization, security rules, and build instructions, see [SETUP.md](SETUP.md).
