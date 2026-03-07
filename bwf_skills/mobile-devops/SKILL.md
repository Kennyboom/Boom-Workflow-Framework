---
name: mobile-devops
description: Build, test, and deploy mobile apps to App Store and Play Store. Covers CI/CD pipelines, Fastlane automation, EAS Build/Submit, code signing, beta testing (TestFlight/Firebase), crash reporting, and App Store Optimization (ASO).
---

# Mobile DevOps Expert

Expert guidance for mobile CI/CD, app store deployment, and release management.

## When to Use

- Setting up CI/CD for mobile apps
- Code signing (iOS certificates, Android keystore)
- App Store / Play Store submission
- Fastlane automation
- Beta testing distribution
- Crash reporting and analytics

---

## 1. CI/CD Pipeline (GitHub Actions)

### iOS Build & Deploy
```yaml
name: iOS Release
on:
  push:
    tags: ['v*']

jobs:
  build-ios:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '15.4'

      - name: Install certificates
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.IOS_P12_BASE64 }}
          p12-password: ${{ secrets.IOS_P12_PASSWORD }}

      - name: Install provisioning profile
        uses: apple-actions/download-provisioning-profiles@v2
        with:
          bundle-id: com.company.app
          issuer-id: ${{ secrets.APP_STORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APP_STORE_KEY_ID }}
          api-private-key: ${{ secrets.APP_STORE_PRIVATE_KEY }}

      - name: Build with Fastlane
        run: bundle exec fastlane ios release
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_API_KEY }}

      - name: Upload to TestFlight
        run: bundle exec fastlane ios beta
```

### Android Build & Deploy
```yaml
name: Android Release
on:
  push:
    tags: ['v*']

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Decode keystore
        run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > keystore.jks

      - name: Build release AAB
        run: ./gradlew bundleRelease
        env:
          KEYSTORE_FILE: keystore.jks
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}

      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SA }}
          packageName: com.company.app
          releaseFiles: app/build/outputs/bundle/release/*.aab
          track: internal
```

## 2. Code Signing

### iOS Code Signing
```
Components:
├── Development Certificate    → Local testing on device
├── Distribution Certificate   → App Store / Ad Hoc builds
├── Provisioning Profile       → Links cert + app ID + devices
└── App Store Connect API Key  → CI/CD authentication

Best Practices:
- Use Fastlane Match for team certificate sharing
- Store certificates in private Git repo (encrypted)
- Use App Store Connect API Key (not Apple ID) for CI
- Rotate certificates before expiry (1 year)
```

### Android Code Signing
```
Components:
├── Upload Key (keystore)      → Signs the AAB you upload
├── App Signing Key            → Google manages, signs final APK
└── Google Play Service Account → CI/CD API access

keystore.properties (do NOT commit):
  storeFile=path/to/keystore.jks
  storePassword=***
  keyAlias=release
  keyPassword=***

Best Practices:
- Enroll in Google Play App Signing (recommended)
- Backup upload keystore securely (lose it = new app listing)
- Use CI secrets for keystore, never commit
```

## 3. Fastlane

### iOS Fastfile
```ruby
platform :ios do
  desc "Push to TestFlight"
  lane :beta do
    increment_build_number(xcodeproj: "MyApp.xcodeproj")
    match(type: "appstore", readonly: true)
    build_app(
      scheme: "MyApp",
      export_method: "app-store",
      xcargs: "-allowProvisioningUpdates"
    )
    upload_to_testflight(skip_waiting_for_build_processing: true)
    slack(message: "iOS beta uploaded to TestFlight!")
  end

  desc "Release to App Store"
  lane :release do
    match(type: "appstore", readonly: true)
    build_app(scheme: "MyApp", export_method: "app-store")
    deliver(
      submit_for_review: true,
      automatic_release: false,
      force: true,
      precheck_include_in_app_purchases: false
    )
  end
end
```

### Android Fastfile
```ruby
platform :android do
  desc "Deploy to Play Store internal track"
  lane :beta do
    gradle(task: "clean bundleRelease")
    upload_to_play_store(
      track: "internal",
      aab: "app/build/outputs/bundle/release/app-release.aab",
      json_key: "google-play-sa.json",
      skip_upload_metadata: true,
      skip_upload_changelogs: false
    )
    slack(message: "Android beta uploaded to Play Store!")
  end

  desc "Promote internal to production"
  lane :release do
    upload_to_play_store(
      track: "internal",
      track_promote_to: "production",
      json_key: "google-play-sa.json",
      rollout: "0.1"  # 10% staged rollout
    )
  end
end
```

### Fastlane Match (Certificate Management)
```bash
# Setup (one time)
fastlane match init  # Creates Matchfile
fastlane match appstore  # Creates/downloads certs

# In CI (read-only mode)
fastlane match appstore --readonly

# Matchfile
git_url("https://github.com/company/certificates")
type("appstore")
app_identifier(["com.company.app"])
```

## 4. EAS (Expo Apps)

### Build & Submit
```bash
# Install
npm install -g eas-cli

# Configure
eas build:configure

# Build for stores
eas build --platform ios --profile production
eas build --platform android --profile production

# Submit to stores
eas submit --platform ios --latest
eas submit --platform android --latest

# OTA update (skip store review!)
eas update --branch production --message "Critical fix"
```

### eas.json Configuration
```json
{
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": { "simulator": true }
    },
    "preview": {
      "distribution": "internal",
      "channel": "preview"
    },
    "production": {
      "autoIncrement": true,
      "channel": "production"
    }
  },
  "submit": {
    "production": {
      "ios": {
        "appleId": "you@email.com",
        "ascAppId": "123456789",
        "appleTeamId": "TEAM_ID"
      },
      "android": {
        "serviceAccountKeyPath": "./google-sa.json",
        "track": "internal"
      }
    }
  }
}
```

## 5. Beta Testing

### TestFlight (iOS)
```
Setup:
1. Upload build via Xcode, Fastlane, or EAS
2. Add internal testers (up to 100, instant)
3. Add external testers (up to 10,000, needs review)
4. External review: ~24-48 hours first time

Best Practices:
- Use "What to Test" notes per build
- Create test groups by feature/role
- Auto-distribute to internal testers
- Expire old builds to reduce confusion
```

### Firebase App Distribution (Both Platforms)
```bash
# Install
npm install -g firebase-tools

# Distribute
firebase appdistribution:distribute app-release.apk \
  --app YOUR_APP_ID \
  --groups "qa-team, beta-testers" \
  --release-notes "Bug fixes and improvements"
```

## 6. Crash Reporting & Analytics

### Sentry (Recommended)
```typescript
// React Native
import * as Sentry from '@sentry/react-native';

Sentry.init({
  dsn: 'https://key@sentry.io/project',
  tracesSampleRate: 0.2,
  profilesSampleRate: 0.1,
  enableAutoSessionTracking: true,
});
```

### Firebase Crashlytics
```kotlin
// Android
Firebase.crashlytics.apply {
    setCustomKey("user_id", userId)
    setCustomKey("screen", currentScreen)
    log("User performed action X")
    recordException(exception)
}
```

## 7. App Store Optimization (ASO)

### Key Factors
```
App Store (iOS):
├── App Name (30 chars) — include primary keyword
├── Subtitle (30 chars) — secondary keywords
├── Keywords field (100 chars) — comma-separated, no spaces
├── Screenshots (up to 10) — first 3 most important
├── App Preview Videos (up to 3)
└── Description — first 3 lines visible

Play Store (Android):
├── App Title (30 chars)
├── Short Description (80 chars) — highly weighted
├── Full Description (4000 chars) — keyword-rich
├── Screenshots (up to 8)
├── Feature Graphic (required)
└── Tags/Categories
```

### Screenshot Best Practices
```
- Show real app UI (not mockups)
- Add benefit-driven captions
- First screenshot = most important feature
- Test different orders with A/B testing (Play Store)
- Include device frames for context
- Dark mode screenshots for premium feel
```

## 8. Release Checklist

### Pre-Release
- [ ] All automated tests passing
- [ ] Manual QA on physical devices (iOS + Android)
- [ ] Performance profiling (startup time, memory)
- [ ] Crash-free rate >99.5% on beta
- [ ] Privacy policy URL updated
- [ ] App description and screenshots updated
- [ ] Release notes written (user-friendly)
- [ ] Version/build number incremented

### Post-Release
- [ ] Monitor crash rate (first 24 hours critical)
- [ ] Check user reviews for issues
- [ ] Staged rollout: 10% → 25% → 50% → 100%
- [ ] Tag release in Git
- [ ] Notify team via Slack/Discord
- [ ] Update CHANGELOG.md

## 9. Versioning Strategy

```
Semantic Versioning: MAJOR.MINOR.PATCH
  1.0.0 → Initial release
  1.1.0 → New feature (backward compatible)
  1.1.1 → Bug fix
  2.0.0 → Breaking change / major redesign

Build Number: Auto-increment per build
  iOS: CFBundleVersion (integer, always increasing)
  Android: versionCode (integer, always increasing)

Example:
  Version: 2.3.1
  iOS Build: 145
  Android versionCode: 145
```
