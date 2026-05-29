<p align="center">
  <img src="assets/app_icon.png" width="120" height="120" alt="Orbit 360 Logo">
</p>

<h1 align="center">Orbit 360</h1>

<p align="center">
  <strong>A native macOS transcoder for 360° video files.</strong>
</p>

<p align="center">
  <a href="https://github.com/yung988/Orbit-360/releases/download/v1.0.0/Orbit360.dmg">
    <img src="https://img.shields.io/badge/Download-DMG-0066CC?style=for-the-badge&logo=apple&logoColor=white" alt="Download DMG">
  </a>
  <img src="https://img.shields.io/badge/Platform-macOS%2013+-1E2229?style=for-the-badge&logo=apple&logoColor=white" alt="macOS 13+">
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-10B981?style=for-the-badge" alt="MIT License">
  </a>
</p>

<p align="center">
  <img src="assets/orbit360_mockup.png" width="800" alt="Orbit 360 App Screenshot" style="border-radius: 12px; box-shadow: 0 20px 40px rgba(0,0,0,0.4);">
</p>

---

**Orbit 360** helps you prepare 360° video for editing, playback, sharing, or VR viewing. Drop in a 360° video file, inspect its technical details, choose your export settings, and decide how audio should be handled — keep the original track, create stereo audio, preserve multichannel/spatial audio when available, or attach audio from another source file.

The application is **fully self-contained** and comes pre-bundled with static `ffmpeg` and `ffprobe` binaries, requiring no external installation or terminal setups.

---

## ⚡ Reasons You'll Love Orbit 360

* 🎥 **Convert 360° Video** – Transcode 360° camera footage or equirectangular exports into standard video formats.
* 🎛️ **Control Export Settings** – Easily choose output format, codec, resolution, frame rate, bitrate, and quality.
* 🔊 **Flexible Audio Handling** – Keep original audio, export stereo, preserve multichannel/spatial tracks when available, or remove audio completely.
* 🔄 **Audio Transfer** – Copy audio from a source file into an already exported video without re-encoding the video stream when possible.
* 🔍 **Inspect and Verify** – Read video and audio stream information before export and verify the output specs (channels, resolution, codec) after processing.
* 📦 **Fully Self-Contained** – Pre-bundled with static FFmpeg and FFprobe binaries—no Homebrew or external setup required.
* 🧩 **Camera-Agnostic** – Designed for common 360° camera exports and standard media files, not tied to one camera brand.

---

## 🚀 Workflows

### 1. Convert 360° Video
Drop in a 360° camera export or equirectangular file, choose your export container (MP4, MOV, M4V, MKV, WebM), video codec (including hardware-accelerated HEVC/H.264), scaling, and frame rate, and select how audio should be processed (stereo downmix, keep original, preserve spatial, or strip).

### 2. Audio Transfer
Copy audio from a source file into an existing video export. This is useful when you already have a finished high-quality video master (e.g. from DaVinci Resolve or Premiere Pro) and want to replace or add the correct audio track (stereo, original camera audio, multi-channel, or spatial/ambisonic) without re-encoding the video stream.

---

## 💻 Requirements

* macOS 13 Ventura or newer
* Apple Silicon or Intel Mac

---

## 🛠️ For Developers & Maintainers

Orbit 360 is built using Swift 5.9+ and SwiftUI.

### Fetching FFmpeg Binaries
If you are compiling from source or packaging releases, download static macOS binaries into the `Resources/` folder first:

```bash
./scripts/download_ffmpeg_macos.sh
```

*(Note: Advanced users who compile from source can also specify system-installed binary paths in the app Settings.)*

### Build and Run

Build the package:
```bash
swift build
```

Run from Swift Package Manager:
```bash
swift run Orbit360
```

Create a local `.app` bundle and `.dmg` installer:
```bash
swift build -c release --arch arm64
swift build -c release --arch x86_64
./create_app.sh
```

---

## 📄 License

Orbit 360 is released under the **MIT License**. See [LICENSE](LICENSE) for the full text.
