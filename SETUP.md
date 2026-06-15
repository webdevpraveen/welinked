# WeLinked - Setup & Build Instructions

Follow this step-by-step guide to configure Firebase, wire up the Google Maps API key, deploy rules/functions, and build the APK.

---

## Step 1: Firebase Project Configuration

1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project named **WeLinked**.
2. Upgrade the project to the **Blaze plan**. (Required for deploying Node.js 18 Cloud Functions). The free tier limits are generous and should cost $0.00 for exactly 2 active users.
3. Enable **Email/Password** provider inside **Firebase Authentication** console.
4. Enable **Cloud Firestore** and choose a location close to your physical devices.
5. Create an Android App in your Firebase project settings:
   - Package name: `com.wdp.welinked`
   - Download the generated `google-services.json` file.
6. Move the downloaded `google-services.json` into your local workspace directory:
   - Path: `android/app/google-services.json`

---

## Step 2: Google Maps API Configuration

1. Visit the [Google Cloud Console](https://console.cloud.google.com/).
2. Enable the **Maps SDK for Android** API.
3. Generate an API Key in Credentials.
4. Open [android/app/src/main/AndroidManifest.xml](file:///c:/Users/iampr/welinked/android/app/src/main/AndroidManifest.xml) and locate this tag:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE" />
   ```
5. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual Google Maps API Key.

---

## Step 3: Deploy Firestore Rules and Indexes

Deploy rules using the Firebase CLI or manually copy-paste configurations:

### Option A: Via Firebase CLI
1. Ensure firebase-tools is installed: `npm install -g firebase-tools`
2. Log in: `firebase login`
3. Initialize the project inside the `/firebase` directory of the workspace.
4. Deploy security rules and composite indexes:
   ```bash
   cd firebase
   firebase deploy --only firestore
   ```

### Option B: Manual copy-paste
- Open [firebase/firestore.rules](file:///c:/Users/iampr/welinked/firebase/firestore.rules) and copy the content directly to the Rules editor in the Firebase console.
- Add composite indexes manually in the Indexes tab matching [firebase/firestore.indexes.json](file:///c:/Users/iampr/welinked/firebase/firestore.indexes.json).

---

## Step 4: Deploy Cloud Functions

1. Navigate to the functions directory:
   ```bash
   cd firebase/functions
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Deploy functions to your project:
   ```bash
   firebase deploy --only functions
   ```

---

## Step 5: Audio Asset Verification

Verify that the following 4 files exist in `assets/audio/` before building:
- `red_alert.mp3`
- `green_alert.mp3`
- `blue_alert.mp3`
- `yellow_alert.mp3`

---

## Step 6: Build & Generate APK

Run these commands in the root of your project directory:

1. Retrieve Flutter packages:
   ```bash
   flutter pub get
   ```
2. Run analyzer checks to ensure zero errors:
   ```bash
   flutter analyze
   ```
3. Compile release APK:
   ```bash
   flutter build apk --release
   ```
4. The generated APK will be available in:
   - `build/app/outputs/flutter-apk/app-release.apk`
