# CarFlip

A simple iOS app that helps you decide which car to drive on a given day through a fun coin-flip mechanism.

## Features

- Add multiple cars with names and photos
- Randomly select a car to drive with an animated flip
- View history of your car selections in a calendar
- Data persistence using UserDefaults

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository
2. Open `CarFlip.xcodeproj` in Xcode
3. Build and run the app on your device or simulator

### AltStore

Add this source in AltStore (Browse → Sources → +):

```
https://raw.githubusercontent.com/marianmolnar/CarFlip/main/altstore/apps.json
```

Or open [altstore://source?url=https://raw.githubusercontent.com/marianmolnar/CarFlip/main/altstore/apps.json](altstore://source?url=https://raw.githubusercontent.com/marianmolnar/CarFlip/main/altstore/apps.json) on your iPhone.

## Usage

1. Add at least two cars with their names and photos
2. Go to the Flip tab to randomly select which car to drive today
3. Check the History tab to see which car you drove on past days

## Architecture

- SwiftUI for the user interface
- MVVM pattern with ObservableObject for data management
- UserDefaults for simple data persistence

## License

MIT 