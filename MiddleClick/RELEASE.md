// Release checklist for MiddleClick

1. Bump version/build in Xcode
   - Target -> General -> Version (Marketing Version) and Build.
2. Ensure signing for Release
   - Signing Certificate: Developer ID Application.
   - Team: your developer team.
   - Hardened Runtime: enabled.
   - App Sandbox: disabled.
3. Verify Info.plist
   - LSUIElement = 1 (Application is agent) for a menu bar app experience.
4. Archive
   - Product -> Archive with destination "Any Mac (Apple Silicon, Intel)".
5. Notarize via Xcode
   - Organizer -> Distribute App -> Developer ID -> Upload.
   - Wait for success. Xcode will sign and notarize.
6. Export the app
   - From Organizer, Export the notarized .app to a folder.
7. Create DMG
   - Use the provided `scripts/make_dmg.sh` or your own tool.
8. Test the DMG
   - Mount the DMG, drag app to /Applications, launch.
   - Grant Accessibility in System Settings -> Privacy & Security -> Accessibility.
   - Confirm the app shows "Running" in the menu and middle-click works.
9. Publish
   - Upload DMG to your website or GitHub Releases.
   - Provide SHA-256 checksum and release notes.
