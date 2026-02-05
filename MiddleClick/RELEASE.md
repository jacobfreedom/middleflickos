# Release checklist for MiddleFlickOS

1. Bump version/build in Xcode
   - Target -> General -> Version (Marketing Version) and Build.
2. Ensure signing for Release (outside Mac App Store)
   - Signing Certificate: Developer ID Application.
   - Team: your developer team.
   - Hardened Runtime: enabled.
   - App Sandbox: disabled.
3. Set app metadata (name, bundle id, agent mode)
   - Run: `scripts/set_metadata.sh /path/to/Info.plist "MiddleFlickOS" com.rolledhand.MiddleFlickOS`
   - This sets CFBundleName/DisplayName, CFBundleIdentifier, and LSUIElement=1 (menu-bar-only app).
   - In Xcode, also rename the Target to "MiddleFlickOS" (Project Navigator → select target → Rename).
   - When prompted, let Xcode rename the Scheme as well.
   - Verify the Bundle Identifier now shows `com.rolledhand.MiddleFlickOS` in target settings (General tab).
4. App icon
   - Generate a minimalist icon: `scripts/generate_app_icon.swift ./MiddleFlickOS_1024.png`
   - Build the app icon set: `scripts/build_appiconset.sh ./MiddleFlickOS_1024.png ./Assets.xcassets/AppIcon.appiconset`
   - In Xcode target settings, set the App Icon to the AppIcon asset.
5. Archive
   - Product -> Archive with destination "Any Mac (Apple Silicon, Intel)".
6. Notarize via Xcode
   - Organizer -> Distribute App -> Developer ID -> Upload.
   - Wait for success. Xcode will sign and notarize.
7. Export the app
   - From Organizer, Export the notarized .app to a folder.
8. Create DMG
   - Use the provided `scripts/make_dmg.sh "/path/to/Exported/MiddleFlickOS.app"`.
9. Test the DMG
   - Mount the DMG, drag app to /Applications, launch.
   - Grant Accessibility in System Settings -> Privacy & Security -> Accessibility.
   - Confirm the menu shows "Running" and functionality works.
10. Publish
   - Upload DMG to your website or GitHub Releases.
   - Provide SHA-256 checksum and release notes.
