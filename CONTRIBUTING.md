# Contributing

Thanks for helping improve 360 Audio Exporter.

## Development

Requirements:

- macOS 14+
- Swift 5.9+
- ffmpeg and ffprobe installed locally

Build:

```bash
swift build
```

Run:

```bash
swift run 360AudioExporter
```

Create a local DMG:

```bash
swift build -c release
./create_app.sh
```

## Pull Requests

- Keep changes focused and easy to review.
- Prefer small fixes over large rewrites.
- Include a short explanation of user-facing behavior changes.
- Run `swift build` before opening a PR.

## Media Handling Notes

- Do not commit sample videos unless they are tiny, redistributable test fixtures.
- Do not commit generated `.app`, `.dmg`, or `.build` artifacts.
- Release binaries belong in GitHub Releases, not in Git history.
