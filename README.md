# ConnectCall

> Connect with anyone, anywhere.

A production-quality Flutter 1-to-1 audio/video calling application built with clean architecture, designed for seamless future backend integration.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Dart](https://img.shields.io/badge/Dart-3.x-blue)
![GetX](https://img.shields.io/badge/State-GetX-purple)
![Status](https://img.shields.io/badge/Phase-Mock%20Services-green)

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
Mock Implementation  <-->  Future: Firebase / Supabase / LiveKit
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

The current version uses mock services. Firebase, Supabase and LiveKit integration will be added in the backend integration phase.

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

## Future Backend Integration

| Service | Mock | Future |
|---------|------|--------|
| Authentication | MockAuthService | FirebaseAuthService |
| Users | MockUserService | SupabaseUserService |
| Calling | MockCallingService | LiveKitCallingService |
| Storage | MockStorageService | SupabaseStorageService |

Integration requires only swapping service registrations in InitialBinding. No UI changes needed.

## Known Limitations

- No real audio/video streaming (mock placeholders)
- No push notifications
- No real backend connectivity
- Mock permission grants (always granted)
- No persistent storage (in-memory only)

These will be addressed in the backend integration phase.
