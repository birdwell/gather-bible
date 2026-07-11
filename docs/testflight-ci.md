# Automated TestFlight builds

Every push to `main` (and any manual run of the **TestFlight** workflow from the
Actions tab) archives the app and uploads it straight to TestFlight. The
pipeline lives in `.github/workflows/testflight.yml` and uses plain
`xcodebuild` with Xcode cloud signing — no fastlane, no certificates checked
into the repo, no manual provisioning profiles.

## How it works

1. **Archive** — `xcodebuild archive` builds the `Gather Bible` scheme for
   `generic/platform=iOS`. `-allowProvisioningUpdates` plus the App Store
   Connect API key lets Xcode resolve signing automatically in CI (cloud
   signing), the same way it does locally.
2. **Upload** — `xcodebuild -exportArchive` with
   `.github/ExportOptions.plist` (`method: app-store-connect`,
   `destination: upload`) signs the archive and uploads it directly to App
   Store Connect. Once Apple finishes processing, the build appears in
   TestFlight.
3. **Build numbers** — `manageAppVersionAndBuildNumber` is enabled in the
   export options, so Xcode automatically bumps the build number to be unique
   on App Store Connect. You never need to touch `CURRENT_PROJECT_VERSION`
   for a TestFlight build.
4. **Symbols** — dSYMs are uploaded to App Store Connect (`uploadSymbols`).
   If the optional `SENTRY_AUTH_TOKEN` secret is set, the existing "Upload
   Debug Symbols to Sentry" build phase also uploads them to Sentry.

## One-time setup

### 1. Create an App Store Connect API key

1. Go to [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api).
2. Create a **Team key** with the **Admin** role (Admin is required for cloud
   signing to create/manage certificates and profiles; App Manager works only
   if a cloud-managed Apple Distribution certificate already exists).
3. Download the `.p8` file (you can only download it once) and note the
   **Key ID** and **Issuer ID** shown on that page.

### 2. Add GitHub repository secrets

In the repo: **Settings → Secrets and variables → Actions → New repository
secret**. Add:

| Secret | Value |
| --- | --- |
| `APP_STORE_CONNECT_KEY_ID` | The Key ID (e.g. `ABC123DEFG`) |
| `APP_STORE_CONNECT_ISSUER_ID` | The Issuer ID (a UUID) |
| `APP_STORE_CONNECT_PRIVATE_KEY` | The `.p8` file contents, base64-encoded: `base64 -i AuthKey_ABC123DEFG.p8 \| pbcopy` |
| `SENTRY_AUTH_TOKEN` *(optional)* | A Sentry auth token with `project:releases` scope, for dSYM upload |

### 3. Make sure the app record exists

The app (bundle ID `Josh-Birdwell.Gather-Bible`) must already have an app
record in App Store Connect — the upload creates builds, not apps. Create it
once under **My Apps → +** if it doesn't exist yet.

That's it. Push to `main`, watch the run in the Actions tab, and the build
shows up in TestFlight after Apple's processing (usually 5–15 minutes). The
first build per version still needs export-compliance answered in App Store
Connect unless `ITSAppUsesNonExemptEncryption` is set in the Info.plist.

## Notes

- The Periphery build phase is skipped automatically when
  `/opt/homebrew/bin/periphery` isn't installed (as on CI runners), so it
  doesn't block release builds.
- Docs-only pushes (`docs/**`, `*.md`) don't trigger a build.
- Runs are serialized (`concurrency: testflight`) so two pushes in quick
  succession can't race each other on build numbers.
