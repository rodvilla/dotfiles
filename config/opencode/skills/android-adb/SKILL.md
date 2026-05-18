---
name: android-adb
description: Use when controlling Android devices with ADB for app automation, UI hierarchy inspection, screenshots, and scripted touch/key interactions.
---

# Android ADB

Control and automate Android devices using ADB.

## When To Use

- You need to launch or navigate an Android app from the CLI.
- You need tap coordinates from the UI hierarchy.
- You need screenshots for visual verification loops.

## Core Workflows

### Connect Device

USB:

```bash
adb devices
```

Wireless (Android 11+):

```bash
adb pair <ip>:<pairing_port> <pairing_code>
adb connect <ip>:<connection_port>
adb devices
```

### Launch App

```bash
adb shell monkey -p <package_name> -c android.intent.category.LAUNCHER 1
```

### Inspect UI Hierarchy

```bash
adb shell uiautomator dump /sdcard/view.xml && adb pull /sdcard/view.xml ./view.xml
```

Find target bounds in `view.xml`, then tap center coordinates.

### Interact With UI

```bash
adb shell input tap <x> <y>
adb shell input text "<text>"
adb shell input keyevent <keycode>
adb shell input swipe <x1> <y1> <x2> <y2> <duration_ms>
```

Common keycodes: Home `3`, Back `4`, Power `26`, Search `84`, Enter `66`.

### Screenshot Verification Loop

```bash
adb shell screencap -p /sdcard/screen.png && adb pull /sdcard/screen.png ./screen.png
```

Use the screenshot to evaluate spacing, contrast, alignment, and hierarchy; iterate after each code change.

## Tips

- Add short waits between navigation steps when UI updates are async.
- Prefer centered tap coordinates inside bounds for reliability.
