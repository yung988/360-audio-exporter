# 360 Audio Exporter

Native macOS SwiftUI utility for exporting 360 video and attaching 4-channel spatial/ambisonic audio to finished videos.

The app keeps the UI native and delegates heavy media work to `ffmpeg` and `ffprobe` through `Process`.

This project is open source and currently in early MVP/alpha stage.

## Features

- Export 360 videos to MP4, M4V, MOV, MKV, or WebM.
- Choose H.264, HEVC, ProRes, VP9, or stream copy where compatible.
- Pick common 2:1 360 resolutions from 2K to 8K, or enter a custom resolution.
- Use bitrate presets or a custom video bitrate.
- Keep original audio, export stereo AAC, export 4-channel spatial audio, or remove audio.
- Attach spatial audio from a 360 source, MP4/MOV, WAV, M4A, or AAC file without re-encoding the video.
- Show source file metadata, streams, channels, codec, duration, size, and likely 360/spatial status.
- Show export stage, percentage, current media timestamp, speed, and ETA.
- Validate output with `ffprobe` after export.

## Requirements

- macOS 14 or newer
- Swift 5.9+
- `ffmpeg` and `ffprobe`

Install ffmpeg with Homebrew:

```bash
brew install ffmpeg
```

The app looks for binaries in `/opt/homebrew/bin`, `/usr/local/bin`, and `/usr/bin`. You can override paths in Settings.

## Build

```bash
swift build
```

Run from Swift Package Manager:

```bash
swift run 360AudioExporter
```

Create a local `.app` bundle and `.dmg`:

```bash
swift build -c release
./create_app.sh
```

## Notes

- The app does not implement camera stitching or a custom video decoder.
- GoPro `.360` and Insta360 `.insv` support depends on what the installed ffmpeg build can read.
- Four audio channels are treated as likely spatial/ambisonic audio, but some VR platforms may also require platform-specific metadata.

## License

MIT

## AI Assistance

This project was developed with AI coding assistance and is being prepared as an open-source macOS utility for the developer community.
