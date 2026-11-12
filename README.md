# Khota | خُطى

Khota is a graduation project at King Saud University. It is a mobile
application that allows citizens in Riyadh to report sidewalk and curb ramp
issues by submitting a photo and a location, and to track the status of their
reports.

## Team Members

- Hala Alduhayan
- Rand Aldahmash
- Rahaf Alshalwi
- Haifa Alromaih

Supervisor: Prof. Reham Alabduljabbar

## Release 1 Features

- Account registration, login, logout, password reset, and profile editing
- Report submission in three steps: photo (camera or gallery), location
  (GPS or manual selection on the map), and review
- My Reports: the user's reports with status filters and report details
- Map of submitted reports using OpenStreetMap
- Arabic (RTL) interface, adjustable font size, and light/dark appearance

AI-based severity assessment, PIQS scoring, notifications, and the
administrator dashboard are planned for Release 2. The machine-learning code
is in a separate repository: https://github.com/hcchly/Khota-ML

## Technologies

- Flutter and Dart
- Firebase Authentication, Cloud Firestore, Firebase Storage, and Cloud Functions
- flutter_map and OpenStreetMap (map tiles and Nominatim address lookup)
- Geolocator and camera / image_picker

## Requirements

- Flutter SDK (stable channel; see `pubspec.yaml` for the Dart SDK version)
- Android Studio with an Android emulator or device, or Xcode with an iOS
  simulator or device (macOS only)
- Node.js and the Firebase CLI (only for deploying rules and Cloud Functions)

## Setup and Run

1. Clone the repository and open the project folder:

   ```bash
   git clone https://github.com/hcchly/Khota.git
   cd Khota
   ```

2. Install the packages:

   ```bash
   flutter pub get
   ```

3. Check that a device or emulator is available:

   ```bash
   flutter devices
   ```

4. Run the application:

   ```bash
   flutter run
   ```

   Allow camera and location permissions when the app asks for them. The
   app is designed for Android and iOS; camera and GPS features may be
   limited when it is run in a web browser.

### Firebase configuration

The app connects to the Khota Firebase project. The configuration files are
included in the repository. To use a different Firebase project, run
`flutterfire configure` and replace the generated files.

### Security rules and Cloud Functions (project owners only)

```bash
firebase deploy --only firestore:rules,storage
cd functions-map
npm install
firebase deploy --only functions
```

The `syncKhotaMapReport` function copies the location, issue class, severity,
and status of each report to the `mapReports` collection used by the map.

## Testing

```bash
flutter test
```

## Project Structure

```
lib/
  screens/    App screens (auth, home, reports, map, profile, settings)
  services/   Firebase, camera, location, and storage services
  widgets/    Shared UI components
test/         Unit and widget tests
functions-map/  Cloud Function that maintains the mapReports collection
```

## Repository

https://github.com/hcchly/Khota
