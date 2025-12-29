# Video Loading Debug Guide

## Issues Fixed

### 1. **Comprehensive Logging**
The video initialization now includes detailed debug output at each step:
- **Step 1**: VideoPlayerController creation
- **Step 2**: 500ms system preparation delay
- **Step 3**: initialize() call
- **Step 4**: Completion check
- **Step 5**: Video properties validation (duration, size, has error)
- **Step 6**: Set looping
- **Step 7**: Start playback
- **SUCCESS/ERROR**: Final status

### 2. **Debug Info Toggle**
- Tap the **bug icon** (🐛) next to the "Example" title to show/hide debug info
- Shows:
  - Current status message
  - Training type selected
  - Form type selected
  - Video initialization state
  - Video duration and size (when available)

### 3. **Console Logging**
When running on a physical device, check the Dart console output (via `flutter run`):
```
[SessionDemo] ========================================
[SessionDemo] VIDEO INITIALIZATION START
[SessionDemo] Platform: android (or ios)
[SessionDemo] Video Path: assets/squat_correct.mp4
[SessionDemo] ========================================
[SessionDemo] Step 1: VideoPlayerController created
[SessionDemo] Step 2: Waited 500ms
[SessionDemo] Step 3: Calling initialize()...
[SessionDemo] Step 4: initialize() completed
[SessionDemo] Step 5: Checking video properties
[SessionDemo]   - isInitialized: true
[SessionDemo]   - duration: 0:00:XX
[SessionDemo]   - size: Size(1280.0, 720.0)
[SessionDemo]   - hasError: false
[SessionDemo] Step 6: Setting looping...
[SessionDemo] Step 7: Starting playback...
[SessionDemo] ✅ SUCCESS - Video initialized and playing
```

## Testing on Physical Android Device

### Prerequisites
1. Connect physical Android phone via USB
2. Enable USB debugging on the phone
3. Ensure the device is properly recognized: `flutter devices`

### Run the App
```bash
flutter clean
flutter pub get
flutter run
```

### Troubleshooting Steps

#### If videos don't appear:

1. **Check Console Logs**
   - Look for `[SessionDemo]` messages in the terminal
   - If you see `❌ ERROR` or `❌ TIMEOUT`, note the error message

2. **Toggle Debug Info**
   - Tap the bug icon (🐛) next to "Example"
   - Check the "Status" field for error messages

3. **Try the Retry Button**
   - The error state shows a "Retry" button
   - Tap it to reload the video

4. **Check Device Storage**
   - Ensure device has at least 100MB free storage
   - Videos are ~10MB each

5. **Verify Asset Bundling**
   - The APK should include: `squat_correct.mp4` and `squat_incorrect.mp4`
   - These are declared in `pubspec.yaml` under `assets:`

6. **Restart the App**
   - Sometimes the first load fails, second attempt works
   - Use Retry button or close/reopen app

7. **Check Video Format**
   - Videos must be: MP4 format with H.264 codec
   - Current files: `squat_correct.mp4`, `squat_incorrect.mp4`

## What Was Changed

### File: `lib/screens/patient/session_demo_screen.dart`

**State Variables Added:**
```dart
String _statusMessage = 'Ready to load video';
bool _showDebugInfo = false;
```

**Video Initialization Enhanced:**
- Added 500ms delay before initialization (system preparation)
- Extended timeout to 15 seconds (was 10)
- Added detailed logging at each step
- Added video property validation (duration, size, error status)
- Show error messages to user via snackbar

**UI Improvements:**
- Added debug info toggle (bug icon)
- Shows video status, training type, form, initialization state
- Displays video properties when available
- "Retry" button to reload video
- Troubleshooting hints in error state

## Video File Locations

### Actual Location
```
g:\Flutter\tamren_tech\assets\
  ├── squat_correct.mp4 ✓
  ├── squat_incorrect.mp4 ✓
  ├── Background_app.png
  └── runner_logo.png
```

### In APK
The videos are included in the built APK because they are declared in `pubspec.yaml`:
```yaml
assets:
  - assets/squat_correct.mp4
  - assets/squat_incorrect.mp4
```

### Asset Path in Code
```dart
'assets/squat_correct.mp4' // correct
'assets/squat_incorrect.mp4' // incorrect
```

## Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| "File not found" error | Videos are missing from APK - run `flutter clean` then `flutter run` |
| 15-second timeout | Video file may be corrupted or codec not supported |
| Video initialized but won't play | Try tapping the play button or retry button |
| Different error on different devices | Device codec support varies - check error message |
| Videos appeared on emulator but not device | Physical device may need app restart or storage check |

## Device-Specific Notes

### Android Devices
- **Minimum SDK**: 21 (Android 5.0)
- **Video Codec**: H.264 (supported on all Android 5.0+)
- **Format**: MP4 container
- **Storage Required**: ~50MB free space for app + 20MB for videos

### Performance
- Videos play at ~30fps on most modern phones
- Loop continuously (repeats when finished)
- Play/Pause button available during playback

## Next Steps If Still Not Working

1. **Check the console output carefully** - Each step tells you where it's failing
2. **Enable verbose logging**: `flutter run -v`
3. **Share the full error message** from the debug console
4. **Check device codec support**:
   - Older Android 5.0 devices might have issues
   - Try on Android 8.0+ device if available
5. **Verify APK includes videos**:
   ```bash
   unzip -l build/app/outputs/flutter-apk/app-release.apk | grep squat
   ```

## Architecture

The demo screen now follows this initialization flow:

```
User selects training type or form
    ↓
_initializeVideo() called
    ↓
Dispose old controller
    ↓
Create VideoPlayerController with asset path
    ↓
Wait 500ms for system preparation
    ↓
Call initialize() with 15-second timeout
    ↓
Check if mounted (widget still exists)
    ↓
Validate video properties
    ↓
Set looping and play
    ↓
Update UI (_isVideoInitialized = true)
    ↓
Display video to user
    ↓
On error: Show error message + retry button
```

## Future Improvements

1. **Network video support**: Could load videos from cloud storage
2. **Caching**: Could pre-download videos on app startup
3. **Format conversion**: Could auto-convert unsupported formats
4. **Device detection**: Could use device-specific optimizations
5. **Analytics**: Could track which videos fail to load and why
