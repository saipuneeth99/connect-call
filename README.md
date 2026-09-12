# ConnectCall

> Connect with anyone, anywhere.

A production-quality Flutter 1-to-1 audio/video calling application built with clean architecture, designed for seamless future backend integration.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Dart](https://img.shields.io/badge/Dart-3.x-blue)
![GetX](https://img.shields.io/badge/State-GetX-purple)
![Status](https://img.shields.io/badge/Phase-Backend%20Integrated-green)

## Features

### Core
- Authentication (Login / Register)
- Contacts and User Search
- Audio Calling UI
- Video Calling UI
- Incoming Call Screen
- Outgoing Call Screen
- Call Controls (Mute, Speaker, Camera, Switch Camera)
- Call Duration Timer
- Call History (All / Missed)
- User Profile and Edit Profile

### UI/UX
- Light and Dark Mode (System / Manual)
- Platform-Adaptive UI (iOS and Android conventions)
- Skeleton Loading States
- Empty States
- Error States with Retry
- Offline Banner
- Permission Request UI
- Semantic Color System
- Consistent Spacing System
- Accessibility (semantic labels, touch targets, contrast)

## Architecture

```
UI (Views)
    |
GetX Controller
    |
Repository
    |
Service Interface (abstract class)
    |
    Mock Implementation  <-->  Firebase / Supabase / LiveKit
```

**Key principle:** The UI never touches backend logic. Swapping MockAuthService to FirebaseAuthService requires zero UI changes.

## Project Structure

```
lib/
  main.dart
  app/
    app.dart
    routes/
      app_routes.dart
      app_pages.dart
    bindings/
      initial_binding.dart
  core/
    config/
    constants/
    errors/
    theme/
    utils/
  data/
    models/
    repositories/
    services/
  mock/
  modules/
    splash/
    auth/
    home/
    contacts/
    profile/
    calling/
    history/
  widgets/
```

## State Management

GetX with disciplined usage:
- GetxController per feature
- Rx variables for reactive state
- Obx for reactive UI
- Get.lazyPut / Get.put through Bindings
- Named routes with Get.toNamed

Controllers: AuthController, HomeController, ContactsController, ProfileController, CallController, CallHistoryController, SplashController

## Mock Services

The test suite keeps mock services for deterministic tests. The runtime binding
uses Firebase, Supabase, and LiveKit when those services are initialized.

### Demo Account
- Email: demo@connectcall.app
- Password: password123

### Mock Call Flow
The MockCallingService simulates: idle to calling to ringing to connecting to connected to ended

## How to Run

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

### Requirements
- Flutter 3.x (stable)
- Dart 3.x

## Dependencies

| Package | Purpose |
|---------|---------|
| get | State management, DI, routing |
| intl | Date/time formatting |

## Backend Integration

| Service | Test double | Production |
|---------|------|--------|
| Authentication | MockAuthService | FirebaseAuthService |
| Users | MockUserService | SupabaseUserService |
| Calling | MockCallingService | LiveKitCallingService |
| Storage | MockStorageService | SupabaseStorageService |

The production binding uses Firebase Auth, Supabase, and LiveKit. Run
`supabase_full_schema.sql` in Supabase before testing real calls. The schema
also stores `fcm_token` and `voip_token` for background call delivery.

### Background and locked-screen calls

- Android uses the native foreground listener and full-screen call notification
  while the app is backgrounded or the phone is locked. Android 13+ notification
  permission and Android 14+ full-screen intent permission must be allowed.
- iOS uses PushKit and CallKit. Realtime channels can handle calls while the app
  is alive, but they cannot wake a terminated iPhone. Your call backend must send
  a real APNs VoIP push to the saved `voip_token` with `callId`, `callerId`,
  `callerName`, and `callType` (`audio` or `video`).
- Android can use the saved `fcm_token` for a data-only FCM fallback. The data
  payload uses the same fields. The app displays the native call surface first;
  the Flutter call screen opens after Answer.

To enable Android wake-up delivery, deploy the included edge function and add
the Firebase service-account JSON as a Supabase secret:

```bash
supabase functions deploy send-call-notification --no-verify-jwt
supabase secrets set FIREBASE_PROJECT_ID=intern-636c3 \
  FIREBASE_SERVICE_ACCOUNT_JSON='<firebase-service-account-json>'
```

Without this deployment, the app can only receive calls through Realtime or the
native polling fallback, neither of which is guaranteed after Android suspends
or kills the app.

## Remaining deployment requirements

- Configure APNs VoIP capability and a server-side APNs provider for iOS.
- Configure Firebase Cloud Messaging server delivery if Android FCM fallback is
  desired.
- Test locked-screen behavior on physical devices; iOS simulators do not model
  real PushKit delivery or the lock screen.
