# Firebase Setup Checklist for Tamren Tech

## ✅ Configuration Done

- [x] Firebase dependencies added to `pubspec.yaml`
- [x] Android build files updated with Google Services plugin
- [x] Minimum SDK set to 24 (Android 7.0)
- [x] Internet permissions added to AndroidManifest
- [x] MultiDex enabled
- [x] SHA-1 and SHA-256 fingerprints generated

---

## 📱 Firebase Console Setup (Do These Steps)

### Your App Information
- **Package Name:** `com.example.tamren_tech`
- **SHA-1:** `A4:59:C8:D5:91:1B:E5:53:A1:7E:89:1B:AE:39:AB:7C:68:7F:7F:94`
- **SHA-256:** `8D:B4:D4:7E:E5:46:C2:38:B9:21:34:D7:F3:86:37:24:F3:98:86:BB:B5:B2:EA:94:D0:67:45:E1:B8:E0:C1:28`

### Step 1: Create Firebase Project
1. Go to https://console.firebase.google.com/
2. Click **"Add project"**
3. Project name: `Tamren Tech`
4. Continue and create

### Step 2: Add Android App
1. Click ⚙️ → **Project settings** → **Your apps** → Click **Android icon**
2. Fill in:
   - Android package name: `com.example.tamren_tech`
   - App nickname: `Tamren Tech`
   - Debug signing SHA-1: `A4:59:C8:D5:91:1B:E5:53:A1:7E:89:1B:AE:39:AB:7C:68:7F:7F:94`
   - Click "Add SHA certificate fingerprint" and add SHA-256: `8D:B4:D4:7E:E5:46:C2:38:B9:21:34:D7:F3:86:37:24:F3:98:86:BB:B5:B2:EA:94:D0:67:45:E1:B8:E0:C1:28`
3. **Download `google-services.json`**
4. **Place it in:** `android/app/google-services.json` ⚠️ CRITICAL!

### Step 3: Enable Phone Authentication
1. Firebase Console → **Build** → **Authentication** → **Get started**
2. **Sign-in method** tab → Click **Phone**
3. Toggle **Enable** → **Save**

### Step 4: Create Firestore Database
1. Firebase Console → **Build** → **Firestore Database** → **Create database**
2. Choose **"Start in test mode"**
3. Select region (e.g., `us-central1` or closest to you)
4. Click **Enable**
5. Go to **Rules** tab and replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
6. Click **Publish**

### Step 5: Enable Cloud Storage
1. Firebase Console → **Build** → **Storage** → **Get started**
2. Choose **"Start in test mode"** → **Next** → **Done**
3. Go to **Rules** tab and replace with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /doctorCertificates/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
4. Click **Publish**

---

## 🧪 Testing Phone Authentication

1. **Add test phone numbers** (optional, for development without SMS costs):
   - Firebase Console → **Authentication** → **Sign-in method** → **Phone** → scroll to "Phone numbers for testing"
   - Add: Phone: `+1234567890`, Code: `123456`

2. **Test on real device with real phone number:**
   - Phone auth requires a physical device (doesn't work on emulators without extra setup)
   - Enter phone number with country code (e.g., `+201234567890` for Egypt)
   - Verify OTP code sent via SMS

---

## 🚀 Build and Run

```powershell
# Clean build
flutter clean
flutter pub get

# Run on connected Android device
flutter run
```

---

## 📋 Quick Checklist Before First Run

- [ ] `google-services.json` exists in `android/app/`
- [ ] Phone authentication enabled in Firebase Console
- [ ] Firestore database created with rules set
- [ ] Storage enabled with rules set
- [ ] Testing with real Android device (phone auth won't work on emulator)
- [ ] Internet connection available

---

## 🐛 Common Issues

**Issue:** "google-services.json not found"
- **Fix:** Download from Firebase Console and place in `android/app/`

**Issue:** "Phone authentication failed"
- **Fix:** Verify SHA-1/SHA-256 added to Firebase Console
- **Fix:** Use real device (emulator needs extra config)
- **Fix:** Ensure phone number includes country code (e.g., `+20...`)

**Issue:** "Build fails with DexArchiveMergerException"
- **Fix:** Already handled by `multiDexEnabled = true`

**Issue:** "FirebaseApp is not initialized"
- **Fix:** `google-services.json` must be in correct location
- **Fix:** Clean and rebuild: `flutter clean && flutter pub get`

---

## 📞 Phone Number Format

Always include country code:
- Egypt: `+201234567890`
- USA: `+11234567890`
- UK: `+441234567890`

---

## 🔐 Production Security Rules (Update Later)

Before launching to production, update Firestore and Storage rules to be more restrictive:

**Firestore (Production):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
      allow delete: if false;  // Prevent deletions
    }
  }
}
```

**Storage (Production):**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /doctorCertificates/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
                   && request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024  // 5MB limit
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```
