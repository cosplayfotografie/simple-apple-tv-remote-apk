# ATV-RC (Apple TV Remote Control)

A fast, latency-free, native Apple TV Remote for Android devices built with Flutter and Python (`pyatv`).

## Features

*   **Zero Latency Control**: Commands are sent directly to the Apple TV using the modern `Companion` protocol via an asynchronous Python bridge.
*   **Auto Discovery**: Automatically scans your Wi-Fi network for Apple TVs (or allows manual IP entry).
*   **Secure Pairing**: Supports the standard 4-digit PIN pairing required by tvOS.
*   **Classic D-Pad & Buttons**: Familiar, intuitive layout matching the physical Apple Siri Remote.
*   **Touchpad & Keyboard**: Large touch area for fast swiping and scrolling, plus direct text input to your Apple TV.
*   **App Launcher**: See a grid of all installed apps on your Apple TV and launch them instantly with a tap.

## How it works

The app uses a hybrid architecture for maximum performance and compatibility:
*   **UI (Dart/Flutter)**: Provides a beautiful, responsive, and native-feeling interface.
*   **Bridge (Kotlin)**: Communicates between the Flutter UI and the embedded Python runtime.
*   **Backend (Python/Chaquopy)**: Uses the excellent [`pyatv`](https://pyatv.dev/) library running locally on your Android device to handle the complex MDNS discovery, SRP pairing, and Protocol buffers required to communicate with tvOS 15+.

## Getting Started

### Prerequisites
*   Flutter SDK (^3.12.2)
*   Android Studio / SDK (Target API 34+)

### Building from Source

1.  Clone this repository:
    ```bash
    git clone https://github.com/yourusername/atv-rc.git
    cd atv-rc
    ```
2.  Get dependencies:
    ```bash
    flutter pub get
    ```
3.  Build the APK:
    ```bash
    flutter build apk
    ```
4.  Install on your device:
    ```bash
    flutter install
    ```

## Usage

1.  Ensure your Android phone and Apple TV are on the **same Wi-Fi network**.
2.  Open the app and wait for it to discover your Apple TV.
3.  Tap your Apple TV in the list.
4.  If this is the first time connecting, a 4-digit PIN will appear on your TV. Enter it in the app.
5.  You're connected! Use the tabs at the bottom to switch between the D-Pad, Touchpad, and App Launcher.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## KNOWN BUGS

- A Default Flutter 90MB “fat APK.” (it contains the entire code for all existing mobile processor types (i.e., ARM32, ARM64, and x86 for emulators) at the same time.)
- The power-off button doesn't seem to work reliably
- In trackpad mode, you can't reliably swipe up and down
