# Orbit 360

A simple 360° video transcoder for VR-ready exports.

Convert 360° video from camera files or equirectangular exports into modern formats, with stereo, original, or spatial audio intact.

Orbit 360 is a native macOS tool for converting 360° video into clean, VR-ready exports. Drop in a 360° camera file or an equirectangular video, choose your output format, resolution, codec, frame rate, and audio mode, then export a file ready for playback, editing, sharing, or VR viewing.

Orbit 360 can preserve original audio, export stereo audio, keep 4-channel spatial/ambisonic audio intact, or restore spatial audio by copying it from the original camera file into an already exported video.

This project is open source and currently in early MVP/alpha stage.

## Reasons You'll Love Orbit 360

- Convert 360° video into modern formats.
- Preserve stereo, original, or spatial audio.
- Restore spatial audio from source footage into finished stereo exports.
- Queue up to 20 videos and export them as a sequential batch.
- Create VR-ready equirectangular video files.
- Verify resolution, frame rate, codecs, audio channels, and metadata before export.
- Use a native macOS interface.
- Keep the workflow simple with no timeline and no editing clutter.

## Typical Workflow

1. Drop in a 360° camera file or equirectangular export.
2. Choose output format, resolution, codec, frame rate, and audio mode.
3. Queue up to 20 videos when you need a batch export.
4. Export clean VR-ready files.
5. Check validation before playback, editing, sharing, or VR viewing.

## Requirements

- macOS 13 Ventura or newer
- Apple Silicon or Intel Mac
- Swift 5.9+
- `ffmpeg` and `ffprobe`

Install ffmpeg with Homebrew:

```bash
brew install ffmpeg
```

The app looks for binaries in `/opt/homebrew/bin`, `/usr/local/bin`, and `/usr/bin`. You can override paths in Settings.

Without Homebrew, download an ffmpeg build from https://ffmpeg.org/download.html, then select the `ffmpeg` and `ffprobe` binaries in Settings.

Release maintainers can also bundle binaries by placing executable files at `Resources/ffmpeg` and `Resources/ffprobe` before running `./create_app.sh`.

For convenience, maintainers can fetch redistributable static macOS binaries before packaging:

```bash
./scripts/download_ffmpeg_macos.sh
swift build -c release --arch arm64
swift build -c release --arch x86_64
./create_app.sh
```

Bundled FFmpeg binaries are third-party software. See `THIRD_PARTY_NOTICES.md`.

## Build

```bash
swift build
```

Run from Swift Package Manager:

```bash
swift run Orbit360
```

Create a local `.app` bundle and `.dmg`:

```bash
swift build -c release --arch arm64
swift build -c release --arch x86_64
./create_app.sh
```

## Notes

- Orbit 360 does not implement camera stitching or a custom video decoder.
- GoPro `.360` and Insta360 `.insv` support depends on what the installed ffmpeg build can read.
- Four audio channels are treated as likely ambisonic / spatial audio, but some VR platforms may also require platform-specific metadata.

## License

MIT
