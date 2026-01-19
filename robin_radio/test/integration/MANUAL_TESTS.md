# Manual Test Checklist

This document contains manual test scenarios that cannot be fully automated
due to platform-specific behavior or hardware dependencies.

## Background and Lock Screen Playback (US5)

### Prerequisites
- App installed on physical device or emulator
- Music catalog loaded with at least 3 tracks
- Device has lock screen functionality

### Test Cases

#### T076: iOS Lock Screen Controls
**Environment**: iPhone or iOS Simulator

1. [ ] Start playing a track in the app
2. [ ] Lock the phone (press power button)
3. [ ] Verify: Audio continues playing
4. [ ] Wake the phone (don't unlock)
5. [ ] Verify: Lock screen shows Now Playing widget with:
   - [ ] Track title
   - [ ] Artist name
   - [ ] Album artwork
   - [ ] Play/Pause button
   - [ ] Skip Forward button
   - [ ] Skip Back button
   - [ ] Progress bar
6. [ ] Tap Pause on lock screen
7. [ ] Verify: Audio pauses
8. [ ] Tap Play on lock screen
9. [ ] Verify: Audio resumes
10. [ ] Tap Skip Forward
11. [ ] Verify: Next track starts playing
12. [ ] Verify: Lock screen updates with new track info
13. [ ] Swipe the Now Playing widget away (if applicable)
14. [ ] Pull down from top to access Control Center
15. [ ] Verify: Music controls work from Control Center

#### T077: Android Lock Screen Controls
**Environment**: Android phone or Emulator (API 26+)

1. [ ] Start playing a track in the app
2. [ ] Lock the phone (press power button)
3. [ ] Verify: Audio continues playing
4. [ ] Wake the phone (don't unlock)
5. [ ] Verify: Lock screen shows notification with:
   - [ ] Track title
   - [ ] Artist name
   - [ ] Album artwork thumbnail
   - [ ] Play/Pause button
   - [ ] Skip Forward button
   - [ ] Skip Back button
6. [ ] Tap Pause on notification
7. [ ] Verify: Audio pauses
8. [ ] Tap Play on notification
9. [ ] Verify: Audio resumes
10. [ ] Tap Skip Forward
11. [ ] Verify: Next track starts playing
12. [ ] Verify: Notification updates with new track info
13. [ ] Pull down notification shade
14. [ ] Verify: Expanded media notification is visible
15. [ ] Verify: Controls work from notification shade

#### T078: Headphone Button Events
**Environment**: Physical device with wired headphones or Bluetooth headset

1. [ ] Connect headphones to device
2. [ ] Start playing a track in the app
3. [ ] Press headphone button once
4. [ ] Verify: Audio pauses
5. [ ] Press headphone button once
6. [ ] Verify: Audio resumes
7. [ ] Double-press headphone button (if supported)
8. [ ] Verify: Skip to next track (on supported devices)

### Background Audio Persistence

#### Background While Multitasking
1. [ ] Start playing a track
2. [ ] Press Home button (go to home screen)
3. [ ] Verify: Audio continues playing
4. [ ] Open another app (e.g., browser)
5. [ ] Verify: Audio continues playing
6. [ ] Return to Robin Radio
7. [ ] Verify: UI shows correct playback state

#### Background During Calls (iOS/Android)
1. [ ] Start playing a track
2. [ ] Receive or make a phone call
3. [ ] Verify: Audio pauses automatically
4. [ ] End the call
5. [ ] Verify: Audio resumes automatically (or stays paused, which is acceptable)

#### Background During Other Audio
1. [ ] Start playing a track
2. [ ] Play a YouTube video in another app
3. [ ] Verify: Robin Radio audio pauses or mixes (platform dependent)
4. [ ] Stop the YouTube video
5. [ ] Verify: Can resume Robin Radio from lock screen/notification

### Audio Session Interruption Recovery

1. [ ] Start playing a track
2. [ ] Trigger Siri/Google Assistant
3. [ ] Verify: Audio pauses during assistant
4. [ ] Cancel assistant request
5. [ ] Verify: Audio can be resumed

## Test Results Template

| Test Case | Date | Tester | Device | OS Version | Pass/Fail | Notes |
|-----------|------|--------|--------|------------|-----------|-------|
| T076 iOS  |      |        |        |            |           |       |
| T077 Android |   |        |        |            |           |       |
| T078 Headphones | |       |        |            |           |       |

## Known Issues / Limitations

-
