# Release Process

## Local Release Checklist

1. Run `./scripts/check.sh`
2. Run `./scripts/package_app.sh`
3. Launch `dist/VoiceDex.app`
4. Verify:
   - HUD appears on `F5`
   - recording stops on second `F5`
   - settings window opens
   - paste vs clipboard fallback behaves correctly

## GitHub Publishing

Recommended repository defaults:

- repository name: `voice-dex`
- default branch: `main`
- visibility: public

## Distribution Work Still Needed

Before broad public release:

- add a production app icon
- add proper Developer ID signing
- notarize the `.app` or `.dmg`
- publish screenshots and a short demo video
- document permissions onboarding
