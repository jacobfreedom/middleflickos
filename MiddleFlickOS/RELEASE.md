# Release checklist for MiddleFlickOS

1. Bump version/build in Xcode
   - Target -> General -> Version (Marketing Version) and Build.
2. Verify app metadata and deployment target
   - Confirm Target name is `MiddleFlickOS`.
   - Confirm Bundle Identifier is correct in target settings.
   - Confirm `LSUIElement=1` (menu-bar-only app) in `MiddleFlickOS/Info.plist`.
   - Confirm deployment target is macOS 13.0+.
3. Ensure signing for Release (outside Mac App Store)
   - Signing Certificate: Developer ID Application.
   - Team: your developer team.
   - Hardened Runtime: enabled.
   - App Sandbox: disabled.
4. App icon
   - Generate a minimalist icon: `scripts/generate_app_icon.swift ./MiddleFlickOS_1024.png`
   - Build the app icon set:
     `scripts/build_appiconset.sh ./MiddleFlickOS_1024.png ./MiddleFlickOS/Assets.xcassets/AppIcon.appiconset`
   - In Xcode target settings, set the App Icon to the `AppIcon` asset.
5. Menu bar icon
   - Generate base icon: `scripts/generate_menubar_icons.swift /tmp/MiddleFlickOS_MenuBar_1024.png`
   - Resize and overwrite assets:
     - `sips -z 18 18 /tmp/MiddleFlickOS_MenuBar_1024.png --out ./MiddleFlickOS/Assets.xcassets/MenuBarIcon.imageset/MenuBarIcon_18.png`
     - `sips -z 36 36 /tmp/MiddleFlickOS_MenuBar_1024.png --out ./MiddleFlickOS/Assets.xcassets/MenuBarIcon.imageset/MenuBarIcon_36.png`
     - `sips -z 54 54 /tmp/MiddleFlickOS_MenuBar_1024.png --out ./MiddleFlickOS/Assets.xcassets/MenuBarIcon.imageset/MenuBarIcon_54.png`
   - Verify the icon looks vertically centered in the menu bar on light/dark appearance.
6. Archive
   - Product -> Archive with destination "Any Mac (Apple Silicon, Intel)".
7. Notarize via Xcode
   - Organizer -> Distribute App -> Developer ID -> Upload.
   - Wait for success. Xcode will sign and notarize.
8. Export the app
   - From Organizer, Export the notarized `.app` to a folder.
9. Create DMG
   - Use `scripts/make_dmg.sh "/path/to/Exported/MiddleFlickOS.app"`.
10. Test the DMG
   - Mount the DMG, drag app to `/Applications`, launch.
   - Confirm first-run setup window appears and opens Accessibility settings.
   - Grant Accessibility in System Settings -> Privacy & Security -> Accessibility.
   - Confirm the menu shows `Running`.
   - Confirm `Launch at Login` toggle works.
   - Confirm `Website` opens `https://middleflickos.vercel.app/`.
11. Publish
   - Upload DMG to your website or GitHub Releases.
   - Provide SHA-256 checksum and release notes.
