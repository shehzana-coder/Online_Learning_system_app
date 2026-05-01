# Firebase Setup Guide for TeachUp

## Current Status

✅ **Firebase is already configured** in your app with project ID: `finalproject-7f04b`

The configuration files are in place:
- `lib/firebase_options.dart` - Contains API keys for all platforms
- `android/app/google-services.json` - Android configuration
- `firebase.json` - FlutterFire configuration
- Android Gradle files have Firebase plugins enabled

## Why Registration Might Be Failing

If registration is failing, it's likely due to one of these issues in the **Firebase Console**:

### 1. Email/Password Authentication Not Enabled

**To Fix:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **finalproject-7f04b**
3. Click **Authentication** in the left sidebar
4. Click the **Sign-in method** tab
5. Find **Email/Password** in the list
6. Click on it and **Enable** it
7. Click **Save**

### 2. Firestore Database Not Created or Wrong Security Rules

**To Fix:**
1. In Firebase Console, click **Firestore Database** in the left sidebar
2. If you see "Create database", click it and choose:
   - **Start in test mode** (for development)
   - Select a location (closest to you)
3. If database exists, click the **Rules** tab
4. Replace the rules with this (for development):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read all teachers
    match /teachers/{teacherId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == teacherId;
    }
    
    // Allow authenticated users to manage enrollments
    match /enrollments/{enrollmentId} {
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to send/receive messages
    match /messages/{messageId} {
      allow read: if request.auth != null && 
        (resource.data.senderId == request.auth.uid || 
         resource.data.receiverId == request.auth.uid);
      allow create: if request.auth != null && 
        request.resource.data.senderId == request.auth.uid;
    }
  }
}
```

5. Click **Publish**

### 3. Firebase Storage Not Set Up (for future features)

**To Fix:**
1. In Firebase Console, click **Storage** in the left sidebar
2. Click **Get Started**
3. Choose **Start in test mode**
4. Select a location
5. Click **Done**

### 4. Network/Internet Connection Issue

Make sure you have an active internet connection when running the app.

## How to Test Registration

1. **Run the app:**
   ```bash
   flutter run -d chrome
   ```

2. **Try to register with:**
   - Username: testuser
   - Email: test@example.com
   - Password: Test1234 (must be 8+ chars with letters and numbers)
   - Confirm Password: Test1234

3. **Check for error messages:**
   - The app now shows detailed error codes
   - Look at the red SnackBar at the bottom of the screen
   - Common errors:
     - `operation-not-allowed` → Email/Password auth not enabled
     - `network-request-failed` → No internet connection
     - `permission-denied` → Firestore rules issue

## Verify Firebase Connection

Run this command to check if Firebase is properly initialized:

```bash
flutter run -d chrome --verbose
```

Look for these lines in the output:
- `[firebase_core] Initialized Firebase`
- `[firebase_auth] Successfully signed in`

## Firebase Console Quick Links

- **Project Console**: https://console.firebase.google.com/project/finalproject-7f04b
- **Authentication**: https://console.firebase.google.com/project/finalproject-7f04b/authentication
- **Firestore**: https://console.firebase.google.com/project/finalproject-7f04b/firestore
- **Storage**: https://console.firebase.google.com/project/finalproject-7f04b/storage

## Collections Your App Uses

Your app creates these Firestore collections:

1. **users** - Student/user profiles
   - Fields: username, email, name, phone, gender, role, createdAt

2. **teachers** - Teacher profiles
   - Fields: name, qualification, courseOfDegree, experience, teachingMode, location, teachingCourses

3. **enrollments** - Student-teacher enrollments
   - Fields: studentId, teacherId, teacherName, enrolledAt

4. **messages** - Messages between students and teachers
   - Fields: senderId, receiverId, receiverName, message, sentAt, isRead

## Testing Checklist

- [ ] Firebase Authentication enabled (Email/Password)
- [ ] Firestore Database created
- [ ] Firestore Security Rules updated
- [ ] Internet connection active
- [ ] App runs without errors: `flutter run -d chrome`
- [ ] Registration form validates correctly
- [ ] Error messages appear if registration fails

## Still Having Issues?

1. **Check Flutter Doctor:**
   ```bash
   flutter doctor -v
   ```

2. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run -d chrome
   ```

3. **Check Firebase Console logs:**
   - Go to Firebase Console → Authentication → Users
   - See if any users were created
   - Check Firestore → Data to see if collections exist

4. **Enable debug logging:**
   Add this to `lib/main.dart` before `runApp()`:
   ```dart
   FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
   ```

## Contact

If you continue to have issues, the error message will now show the exact Firebase error code, which will help diagnose the problem.
