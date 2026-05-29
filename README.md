# Orbit 360

A native macOS transcoder for 360° video.

Convert 360° camera footage or equirectangular video into modern formats, with full control over resolution, codec, frame rate, quality, and audio handling.

Orbit 360 helps you prepare 360° video for editing, playback, sharing, or VR viewing. Drop in a 360° video file, inspect its technical details, choose your export settings, and decide how audio should be handled — keep the original track, create stereo audio, preserve multichannel/spatial audio when available, or attach audio from another source file.

The application is fully self-contained and comes pre-bundled with static `ffmpeg` and `ffprobe` binaries, requiring no external installation or command-line setup.

This project is open source and currently in early MVP/alpha stage.

## Reasons You'll Love Orbit 360

- **Convert 360° video** into standard video formats.
- **Control export settings**: output format, codec, resolution, frame rate, bitrate, and quality.
- **Flexible audio handling**: keep original audio, export stereo, preserve multichannel/spatial tracks when available, or remove audio completely.
- **Audio transfer**: copy audio from a source file into an already exported video without re-encoding the video stream when possible.
- **Inspect and verify**: read video and audio stream details before export and verify the output after processing.
- **Camera-agnostic workflow**: designed for common 360° camera exports and standard media files, not tied to one camera brand.
- **Fully self-contained**: pre-bundled with FFmpeg and FFprobe binaries—no Homebrew or external setup required.

## Typical Workflows

### 1. Convert 360° Video
Drop in a 360° camera export or equirectangular file, choose your export container, video codec, scaling, and frame rate, and decide how the audio stream should be processed (keep original, mix down to stereo, preserve spatial layouts, or strip audio).

### 2. Audio Transfer
Copy audio from a source file into an existing video export. This is useful when you already have a finished video master and want to replace or add the correct audio track (stereo, multi-channel, or spatial/ambisonic) without re-encoding the video stream.

## Requirements

- macOS 13 Ventura or newer
- Apple Silicon or Intel Mac

## For Developers & Maintainers

Orbit 360 is built with Swift 5.9+. If you are compiling from source or packaging releases:

### Fetching FFmpeg Binaries
To build the application yourself and bundle the required binaries:

```bash
# Download static macOS binaries into Resources/
./scripts/download_ffmpeg_macos.sh
```

If you prefer to use system-installed binaries (e.g. from Homebrew), you can change path overrides in the app Settings.

### Build and Run

Build from command line:

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

Bundled FFmpeg binaries are third-party software. See `THIRD_PARTY_NOTICES.md`.

## Notes

- Orbit 360 does not perform camera stitching or implement a custom video decoder.
- Video container and codec compatibility depends on the capabilities of the bundled or configured FFmpeg binaries.
- Advanced metadata tags are preserved when using stream copying.

## License

Released under the MIT License. See [LICENSE](file:///Users/jangajdos/Desktop/opensourceapp/LICENSE) for details.
