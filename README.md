# MiddleFlickOS

_middle click on macOS_

Fn + Click -> Middle Click.  
OS-level. Menu bar app. No config. No bloat.

- macOS 13+
- Intel + Apple Silicon
- ~83 KB
- [MIT License](LICENSE)

## Links

- Website: [middleflickos.vercel.app](https://middleflickos.vercel.app)
- Download: [MiddleFlickOS.dmg](https://github.com/jacobfreedom/middle-click-macos-app/raw/main/MiddleFlickOS.dmg)
- Source: [github.com/jacobfreedom/middleflickos](https://github.com/jacobfreedom/middleflickos)

---

## 01 / FUNCTION

**INPUT**: Fn + Click  
**OUTPUT**: Middle-click event

If an app accepts middle-click, this works.

- Blender
- Maya
- Cinema 4D
- Houdini
- ZBrush
- Browsers
- Anything else reading mouse input

> Known limitation: external keyboards are not supported yet (MacBook keyboard only).

---

## 02 / HOW IT WORKS

MiddleFlickOS installs a [CGEvent tap](https://developer.apple.com/documentation/coregraphics/cgeventtap) at session level.

When left mouse down/up/drag is detected with Fn pressed, it emits middle-click equivalents and suppresses the original left-click path.

That’s the app.

---

## 03 / INSTALL

### 1) Download

Download the [`.dmg`](https://github.com/jacobfreedom/middle-click-macos-app/raw/main/MiddleFlickOS.dmg), open it, drag `MiddleFlickOS.app` into `/Applications`.

### 2) Gatekeeper (first launch only)

Unsigned build (open-source). macOS will warn once.

GUI path:
- Right-click app -> Open -> Confirm

Terminal path:
```bash
xattr -cr /Applications/MiddleFlickOS.app
```

### 3) Accessibility

System Settings -> Privacy & Security -> Accessibility -> enable `MiddleFlickOS`.

If it doesn’t appear, add it manually.

### 4) First run behavior

- MiddleFlickOS runs in the menu bar (top-right of your screen).
- Once Accessibility is granted, it activates automatically.
- On first successful run, it recommends enabling **Launch at Login**.
- The menu includes:
  - `Launch at Login` toggle
  - `About MiddleFlickOS…` (explains privacy/update policy and links to [middleflickos.vercel.app](https://middleflickos.vercel.app))
  - `Quit`

Done. Try Fn + Click.

---

## 04 / TRUST

No network.  
No analytics.  
No telemetry.

Listens for Fn + Click. Emits middle-click. That’s it.

Read the code. Build it yourself. Fork it.

---

## 05 / FAQ

### Why not Karabiner / BetterTouchTool?

Those tools are broad and powerful. This is intentionally narrow.

### Works with [software]?

Yes, if it accepts middle-click.

### External keyboard fix ETA?

Eventually. PRs welcome.

### Donate?

If enough support covers Apple’s $99 dev fee, code-signing gets easier.

- Instagram: [@rolledhand](https://instagram.com/rolledhand)
- Discord: `rolledhand`

---

## Contributing

PRs welcome.  
Best first target: external keyboard support.

---

## License

[MIT](LICENSE)
