# MiddleFlickOS

_middle click on macOS_

Converts Fn + Left Click into a Middle Click at the OS level. Built for rotating 3D viewports on macOS with a trackpad. If you're a 3D artist, this is for you. If not… neat that you're here anyway.

- macOS 12+ (Monterey or later)
- Intel + Apple Silicon
- ~83 KB app
- [MIT License](LICENSE)

[Download MiddleFlickOS.dmg](https://github.com/jacobfreedom/middle-click-macos-app/raw/main/MiddleFlickOS.dmg)

---

## What it does

- **Input:** Fn + Click
- **Output:** Middle-click event

Works across apps: Blender, Maya, Cinema 4D, Houdini, ZBrush, browsers, and more. It's an OS-level event.

> **Known limitation:** External keyboards aren't supported yet (built for the MacBook keyboard only). PRs welcome.

---

## How it works

MiddleFlickOS installs a [CGEvent tap](https://developer.apple.com/documentation/coregraphics/cgeventtap) at the session level. When it detects a left mouse button press with the Fn flag set, it synthesizes a middle-click event and suppresses the original. Drag and release events are handled the same way to support viewport orbiting.

That's the entire app. No background services, no daemons, no configuration files.

---

## Installation

**1. Download**

Download the [`.dmg`](https://github.com/jacobfreedom/middle-click-macos-app/raw/main/MiddleFlickOS.dmg). Open it, drag `MiddleFlickOS.app` into your Applications folder, then eject the disk image.

**2. Bypass Gatekeeper** (first launch only)

Not code-signed yet. Right-click the app → Open → Confirm. Or remove the quarantine attribute via Terminal:

```bash
xattr -cr /Applications/MiddleFlickOS.app
```

**3. Grant Accessibility permission**

System Settings → Privacy & Security → Accessibility → Enable MiddleFlickOS.

Add it manually if it doesn't appear in the list.

**Done.** Try Fn + Click.

---

## Privacy

No network access. No analytics. No telemetry. The app listens for Fn + Click and generates a middle-click event. That's it.

Read every line of source. Build it yourself. Fork it.

---

## FAQ

**Why not Karabiner or BetterTouchTool?**
Those are massive apps with thousands of features. This is 83 KB. Press Fn, click, it works. No configuration, no menus. Install and forget it exists.

**Works with [3D software]?**
Yes. Blender, Maya, C4D, Houdini, ZBrush, whatever. It's an OS-level event — if the app accepts middle-click, it works.

**External keyboard bug fix ETA?**
Eventually. Or fork it and fix it. PRs welcome.

**Can I donate?**
If enough people chip in to cover the $99 Apple developer fee, I'll code-sign it so you don't have to bypass Gatekeeper. Hit me up:
- Instagram: [@rolledhand](https://instagram.com/rolledhand)
- Discord: `rolledhand`

---

## Contributing

PRs welcome. The external keyboard issue is the main known bug — fixing it would be a great first contribution.

---

## License

[MIT](LICENSE)
