# GitHub Actions Workflows

## Build iOS App (SFI)

This workflow builds the SFI (sing-box for iOS) application and produces an unsigned IPA file.

### Workflow File
`.github/workflows/build-ios.yml`

### Triggers

The workflow runs automatically on:
- Push to `main` or `dev` branches
- Pull requests to `main` branch
- Manual trigger via GitHub Actions UI (workflow_dispatch)

### What It Does

1. **Checkout**: Clones the repository with all submodules
2. **Setup Xcode**: Installs the latest stable version of Xcode
3. **Archive**: Creates an archive of the SFI app for iOS
4. **Export**: Exports an unsigned IPA from the archive
5. **Upload Artifacts**: 
   - Unsigned IPA file (retained for 30 days)
   - xcarchive file (retained for 7 days)

### Build Configuration

- **Scheme**: SFI
- **Configuration**: Release
- **Platform**: iOS (generic/platform=iOS)
- **Code Signing**: Disabled - produces unsigned IPA

### Using the Artifacts

After the workflow completes:

1. Go to the workflow run in GitHub Actions
2. Scroll down to the "Artifacts" section
3. Download `SFI-unsigned-ipa` - contains the unsigned IPA file
4. Sign the IPA with your own certificate and provisioning profile
5. Install on your iOS device

### Manual Signing

To sign the IPA manually, you can:

1. Download the `SFI-xcarchive` artifact (contains the xcarchive)
2. Use Xcode's Organizer to export and sign the archive with your own provisioning profile
3. Or use command-line tools like `codesign` and `xcrun` to sign the IPA

### Notes

- The IPA is built using the "debugging" export method (as configured in `SFI/Export.plist`)
- No code signing is performed during the build process
- The artifacts are stored in GitHub Actions and can be downloaded for 30 days (IPA) or 7 days (archive)
