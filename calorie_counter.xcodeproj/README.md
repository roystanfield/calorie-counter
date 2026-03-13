# Calorie Counter App

A SwiftUI-based calorie tracking application with CloudKit integration for seamless data synchronization across devices.

## Features

- Track daily calorie intake
- SwiftData for local data persistence
- CloudKit integration for cross-device synchronization
- Clean, intuitive SwiftUI interface

## Requirements

- iOS 17.0+ / macOS 14.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

1. Clone this repository
2. Open the project in Xcode
3. Configure CloudKit capabilities in your Apple Developer account
4. Build and run the project

## Project Structure

- `calorie_counterApp.swift` - Main app entry point with CloudKit configuration
- `ContentView.swift` - Primary user interface
- `CalorieEntry.swift` - Data model for calorie entries
- `CalorieManager.swift` - Business logic for managing calorie data

## CloudKit Setup

This app uses CloudKit for data synchronization. Make sure to:

1. Enable CloudKit capability in your project
2. Configure CloudKit database schema to match your data models
3. Test with both development and production CloudKit environments

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.