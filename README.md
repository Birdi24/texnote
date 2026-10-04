# BirdWrite

A modern Flutter note-taking app for tablets and desktop development. BirdWrite supports handwritten and text notes, folders, collections, favorites, PDF-backed handwritten pages (under construction), and a browser-style tab system for working with multiple notes at once.

**Project status:** Active development
**Platform focus:** Android tablets
**Framework:** Flutter / Dart

> **Note:** The app is called **BirdWrite**, but the repository and project folder are named **`texnote`**. You will see `texnote` in the clone URL and when you `cd` into the project.

---

## Features

### Text notes

- Rich text editing
- Headings, bold, italic, checklists, tables
- Text-note saving and autosave
- Note statistics

### Handwritten notes

- Freehand drawing with `perfect_freehand`
- Pen and eraser tools
- Text Box *(under construction)*
- Undo/redo
- Lasso selection
- Stylus button support *(under construction)*
- Multiple pages
- Add, duplicate, delete and reorder pages
- PDF pages as backgrounds *(under construction)*
- Zoom and two-finger navigation
- Lazy PDF page rendering for large documents *(under construction)*

### Folders

Organize your notes into folders. You can:

- **Add** a new folder
- **Rename** a folder
- **Move** a folder
- **Delete** a folder

### Favorites

- Mark notes as favorites for quick access

### Search

- Search through notes from the home screen

### Sorting

- Sort notes by different criteria

### Note tabs

- Open multiple notes at the same time
- Up to 3 notes can be open simultaneously
- Tabs work similarly to browser tabs
- Pressing the **+** button takes you back to the Home screen so another note can be selected
- Switch between open notes without closing them

### Themes

- Multiple built-in themes
- Custom theme support

---

## Getting Started

### Prerequisites

Install these before you begin:

| Tool | Why you need it |
|------|-----------------|
| [Git](https://git-scm.com/downloads) | To download the source code |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | To build and run the app |
| [Android Studio](https://developer.android.com/studio) | Provides the Android SDK and platform tools |

For Android builds you also need:

- Android SDK
- Android SDK Platform Tools
- An Android device or emulator

On Linux, you can install Flutter with:

```bash
sudo snap install flutter --classic
```

On Windows and macOS, follow the [official Flutter install guide](https://docs.flutter.dev/get-started/install).

### 1. Get the source code

The repository is named `texnote`:

```bash
git clone https://github.com/Birdi24/texnote.git
cd texnote
```

### 2. Check your setup

```bash
flutter doctor
```

Fix any problems it reports before continuing. For Android, also accept the SDK licences:

```bash
flutter doctor --android-licenses
```

### 3. Install dependencies

```bash
flutter pub get
```

This downloads the packages required by the project.

---

## Running the App

### On a laptop (for development and testing)

The laptop is mainly useful for development and testing.

List the devices Flutter can see:

```bash
flutter devices
```

Then run the app:

```bash
flutter run
```

To pick a specific device, for example Linux desktop (if Linux desktop support is enabled):

```bash
flutter run -d linux
```

Or use any device ID from `flutter devices`:

```bash
flutter run -d <device-id>
```

#### Android emulator

Start an emulator from Android Studio, then run:

```bash
flutter devices
flutter run
```

> Emulators do not reproduce stylus and multi-touch input accurately. Use a real tablet to test handwriting.

### On an Android tablet

Choose **one** of the three methods below.

#### Method A: USB debugging (best for development)

1. On the tablet, enable **Developer options**
   (Settings → About tablet → tap *Build number* 7 times).
2. In Developer options, enable **USB debugging**.
3. Connect the tablet to your computer with a USB cable.
4. Tap **Allow** on the debugging authorization prompt that appears on the tablet.
5. Confirm Flutter can see the tablet:
   ```bash
   flutter devices
   ```
6. Run the app:
   ```bash
   flutter run
   ```

Flutter installs and launches the app on the tablet automatically.

Tablet not showing up? See [Troubleshooting](#troubleshooting).

#### Method B: Build an APK and copy it over

1. Build the APK:
   ```bash
   flutter build apk --release
   ```
2. Find it at:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```
3. Copy the file to the tablet. You can use:
    - USB file transfer
    - KDE Connect
    - A cloud storage service
    - Any other transfer method
4. Open the APK on the tablet and follow Android's installation prompts.

Android may ask you to allow installation from unknown sources when installing an APK manually.

#### Method C: Install the APK with ADB

Use this if you have already built the APK, have Android Platform Tools installed, and have USB debugging enabled.

1. Check that your tablet is listed:
   ```bash
   adb devices
   ```
2. Install the app:
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

The `-r` option updates an existing installation while keeping its app data when possible.

---

## Quick Start

```bash
git clone https://github.com/Birdi24/texnote.git
cd texnote
flutter pub get
flutter devices
flutter run
```

Or build an APK to install on the tablet:

```bash
flutter build apk --release
```

Then install `build/app/outputs/flutter-apk/app-release.apk` on the Android tablet.

---

## Development Workflow

After making changes to the source code:

```bash
flutter pub get
flutter analyze
flutter run
```

For a release APK:

```bash
flutter build apk --release
```

### Recommended development setup

- Flutter
- Dart
- Android Studio or another Flutter-compatible IDE
- A physical Android tablet for testing touch, stylus, gestures and performance
- Git for version control

A physical tablet is recommended for testing handwritten notes because emulator input does not accurately reproduce stylus and multi-touch behaviour.

---

## Project Structure

The main Flutter source code is in `lib/`:

```
lib/
├── models/          # Note and data models
├── screens/         # Application screens
├── widgets/         # Reusable UI components
├── io/              # File and storage handling
├── handwritten/     # Handwritten-note functionality
├── app_style.dart   # Global styling/theme values
└── main.dart        # Application entry point
```

The exact directory structure may change as development continues.

---

## Note Tabs

The tab system allows up to three notes to remain open at once.

```
┌─────────────────────────────────────────────┐
│  Note 1        Note 2        Note 3      +  │
├─────────────────────────────────────────────┤
│                                             │
│              Current Note                   │
│                                             │
└─────────────────────────────────────────────┘
```

**Opening another note:** Press the **+** button in the tab bar. This returns you to the Home screen, where you can select another note.

**Maximum number of tabs:** A maximum of 3 notes can be open at the same time. This keeps the interface manageable on tablets while still allowing quick switching between related notes.

**Switching notes:** Tap another tab to immediately return to that open note. The purpose is similar to browser tabs: several notes can remain open without having to repeatedly navigate through the Home screen.

---

## Data and Storage

Notes are stored locally on the device. The application maintains its own application data directory and stores note files and supporting data there.

Important application data includes:

- Note files
- Folders
- Favorites
- Collections
- Handwritten note pages
- Handwritten strokes
- PDF-related page data
- Application preferences

> Because the app stores notes locally, back up your note data before uninstalling the app or resetting the device.

---

## PDF Handwritten Notes *(under construction)*

Handwritten notes can use PDF documents as page backgrounds.

Large PDFs are handled using lazy loading so the application does not need to keep every PDF page rendered in memory at once. Only pages near the current page are actively rendered when possible. This is especially important for very large documents.

---

## Building for Android

For a normal release APK:

```bash
flutter build apk --release
```

For smaller APKs targeted at specific Android architectures, use split builds:

```bash
flutter build apk --split-per-abi
```

The resulting APK files are placed in:

```
build/app/outputs/flutter-apk/
```

---

## Troubleshooting

### Flutter cannot find the Android device

```bash
flutter devices
```

If the tablet is missing, check ADB:

```bash
adb devices
```

If it is listed as `unauthorized`, unlock the tablet and accept the USB debugging prompt.

### Dependencies are missing

```bash
flutter clean
flutter pub get
```

Then try:

```bash
flutter run
```

### Build problems after updating Flutter

```bash
flutter clean
flutter pub get
flutter doctor
```

Then rebuild the application.

### Android SDK problems

```bash
flutter doctor --android-licenses
flutter doctor
```

Follow the instructions shown by Flutter Doctor.

---

## Contributing

1. Fork or clone the repository.
2. Create a branch for your changes.
3. Make your changes.
4. Run:
   ```bash
   flutter analyze
   ```
5. Test the application on an Android device.
6. Commit your changes.
7. Open a pull request.

