# Speech To Text Local — iOS

Private, **on-device** voice-to-text for iPhone & iPad. Tap the mic, speak, and your
words are transcribed locally using Apple's Speech framework — no cloud, no API keys.
A pluggable clean-up step removes filler words and stutters, fixes capitalisation and
spacing, and you can copy the result anywhere.

## Stack
- Swift + SwiftUI (iOS 17+)
- Speech framework with `requiresOnDeviceRecognition` (offline-capable)
- AVAudioEngine for microphone capture
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) for project generation

## Requirements
- macOS with Xcode 15 or newer
- An iPhone/iPad (on-device speech works best on a real device)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Build & run
```bash
# 1. Generate the Xcode project from project.yml
xcodegen generate

# 2. Open it
open SpeechToTextLocal.xcodeproj

# 3. In Xcode: select your Team under Signing & Capabilities,
#    choose your device, and press Cmd-R.
```

Prefer the command line?
```bash
xcodegen generate
xcodebuild -scheme SpeechToTextLocal -destination 'generic/platform=iOS' build
```

## Permissions
On first use the app requests **Microphone** and **Speech Recognition** access. The
usage strings live in `project.yml` as `INFOPLIST_KEY_*` build settings.

## Project layout
```
SpeechToTextLocal/
├── App/            SwiftUI entry point
├── Models/         DictationModel — speech, audio and stats
├── Enhance/        TextEnhancer protocol + RuleBasedTextEnhancer
├── Views/          ContentView, MicButton
└── Resources/      Asset catalogue (accent colour, app icon slot)
Tests/              Unit tests for the text enhancer
project.yml         XcodeGen spec (source of truth)
```

## Tests
```bash
xcodegen generate
xcodebuild test -scheme SpeechToTextLocal \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Roadmap
- On-device LLM enhancer (Apple Intelligence / Foundation Models) for smart
  formatting, list detection and "speak to edit"
- Multi-language switching
- A system-wide custom keyboard extension

---
Part of the **Speech To Text Local** family: iOS · macOS · Android.
