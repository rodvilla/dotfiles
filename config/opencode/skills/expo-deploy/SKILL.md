---
name: expo-deploy
description: Use when building and submitting Expo React Native iOS and Android production releases through EAS Build and EAS Submit.
---

# Expo Deploy

Deploy Expo apps to Apple App Store and Google Play with EAS.

## When To Use

- You need a production iOS or Android build.
- You need to submit a built artifact to app stores.
- You are troubleshooting EAS build or submission failures.

## Quick Commands

```bash
# iOS first-time (interactive credentials flow)
npx eas-cli build --platform ios --profile production

# iOS subsequent builds
npx eas-cli build --platform ios --profile production --non-interactive

# Android
npx eas-cli build --platform android --profile production --non-interactive

# Submit existing builds
npx eas-cli submit --platform ios --id <BUILD_ID>
npx eas-cli submit --platform android --id <BUILD_ID>

# Build and auto-submit
npx eas-cli build --platform ios --profile production --auto-submit
```

## Prerequisites

1. Apple Developer Program active.
2. Google Play Console account ready.
3. EAS CLI available: `npx eas-cli --version`.
4. Project `eas.json` and Expo `projectId` configured.

## Common Failures

- Install/dependency failures: move native runtime deps from `devDependencies` to `dependencies`.
- Credential setup errors: run first build interactively (without `--non-interactive`).
- Apple 2FA failures: request a fresh code and retry promptly.
- Duplicate submission message: verify previous submission status before retrying.

## Store Review Checklist

- Verify privacy/support/marketing URLs return HTTP 200.
- Confirm required permission texts are explicit (for example microphone use).
- Ensure offline behavior is acceptable if backend is required.
