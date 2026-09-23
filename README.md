# ⚡ wara.io — Media Agency OS & Post-Production Workspace

<p align="center">
  <img src="assets/branding/app_logo.png" alt="wara.io Logo" width="120" onerror="this.style.display='none'"/>
</p>

<p align="center">
  <strong>The high-velocity operating system engineered for video agencies, creative directors, and post-production editors.</strong>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"></a>
  <a href="https://riverpod.dev"><img src="https://img.shields.io/badge/Riverpod-2.x-3C4858?style=for-the-badge&logo=flutter&logoColor=white" alt="Riverpod"></a>
  <a href="https://firebase.google.com"><img src="https://img.shields.io/badge/Firebase-Firestore-FFA611?style=for-the-badge&logo=firebase&logoColor=white" alt="Firebase"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License"></a>
</p>

---

## 📖 Overview

**wara.io** is a cutting-edge mobile workspace platform designed specifically for fast-paced video production and editing agencies. In modern content agencies, communication bottlenecks between creative managers and remote video editors lead to duplicated work, missed deadlines, and chaotic review loops.

**wara.io** solves this through a unified, dual-role architecture that seamlessly balances creative project dispatching with real-time editor self-service.

---

## ✨ Key Feature Suites

### 🎬 1. Editor Workspace & Marketplace
- **Available Project Pool:** Real-time stream of video editing gigs dispatched by agency managers.
- **Atomic Project Claiming:** Instant project locking prevents conflicting claims between editors.
- **Full Project Transparency:** Clear payout amounts (\$), deadline countdown timers, video format tags, and raw asset cloud links.
- **Active Workspace:** In-flight dashboard tracking claimed videos from editing to draft submission.
- **Direct Deliverable Hand-off:** In-app cloud link and revision notes submission directly to reviewing managers.

### 👑 2. Manager Agency OS
- **Global Workflow Deck:** Visual agency-wide pipeline tracking every video from draft to client delivery.
- **One-Click Offer Dispatch:** Create, set deadlines, and broadcast high-priority video tasks to the editor roster.
- **Pending Review Queue:** Dedicated review terminal to preview editor submissions with instant **Approve** or **Request Revision** feedback modals.
- **Financial Intelligence:** Real-time agency revenue dashboards, pending editor liabilities, completed disbursements, and profitability analytics.

### 👤 3. Identity & Profile System
- **Unified Profile Center:** Centralized hub for managing credentials, editing proficiencies (Premiere, After Effects, DaVinci), and weekly bandwidth.
- **Smart Avatar Engine (`WaraAvatar`):**
  - High-performance network image caching with smooth fallback.
  - **Dynamic Initials Algorithm:** Automatically generates a two-letter monogram from the user's **Surname** initial followed by the **First Name** initial (e.g., *Ishraq Rafi* $\rightarrow$ **RI**).
- **Persistent State:** Deep navigation state preservation prevents tab-reset glitches during profile updates.

### 🌓 4. Celestial Theme Engine & Physics Toggle
- **Fluid Dual Themes:**
  - 🌙 **Midnight Slate (Dark Mode):** Deep `#0B0E14` palette with soft purple neon accents for night editing sessions.
  - ☀️ **Pure Daylight (Light Mode):** Clean, high-contrast `#F8FAFC` daylight surface for bright environments.
- **Physics-Based Sun & Moon Toggle (`WaraThemeToggle`):**
  - **Liquid / Squish Physics:** Elastic horizontal stretching (`math.sin(t * math.pi) * 8px`) mid-transit with organic snap-back.
  - **180° Sun Spin & Aura:** Rotating golden amber glow (`#F59E0B`).
  - **-45° Moon Orbital Tilt:** Crescent tilt with luminescent silver-indigo aura (`#818CF8`).
  - **Atmospheric Details:** Twinkling night stars and soft morning gradients.
- **Zero-Flash Transitions:** Full-app continuous color interpolation powered by Flutter's `ThemeExtension<AppColors>` and `AnimatedTheme`.

---

## 🏗️ Architecture & Tech Stack

The application adheres to **Clean Architecture** principles with strict feature-first modularity:

```
lib/
├── core/                       # Core system utilities & configuration
│   ├── constants/              # Global application tokens & configurations
│   ├── router/                 # GoRouter route declarations & shell navigation
│   ├── services/               # Firebase & Cloud Firestore service layer
│   ├── theme/                  # AppTheme, AppColors (ThemeExtension), & ThemeNotifier
│   └── utils/                  # Helper formatters, date parsers, & validators
├── features/                   # Feature-driven domain & presentation modules
│   ├── auth/                   # Authentication & role-based portals
│   ├── editor/                 # Marketplace, active workspace, & editor profile
│   ├── manager/                # Agency workflow, reviews, & finances
│   └── profile/                # User profile models & setup screens
├── shared/                     # Reusable design system widgets & providers
│   ├── widgets/
│   │   ├── wara_avatar.dart    # Smart initials & photo avatar widget
│   │   ├── wara_theme_toggle.dart # Physics-based celestial switch
│   │   └── wara_toast.dart     # Custom themed snackbars & notifications
│   └── providers/              # Shared application state providers
├── firebase_options.dart.example # Sanitized template for platform Firebase configuration
└── main.dart                   # Application entry point with AnimatedTheme wrapper
```

### Tech Stack

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Framework** | [Flutter 3.x](https://flutter.dev) | High-performance multi-platform UI framework |
| **Language** | [Dart 3.x](https://dart.dev) | Sound null-safe modern object-oriented language |
| **State Management** | [Flutter Riverpod 2.x](https://riverpod.dev) | Compile-safe, reactive state & dependency injection |
| **Routing** | [GoRouter](https://pub.dev/packages/go_router) | Declarative routing with stateful nested shell support |
| **Backend** | [Firebase & Cloud Firestore](https://firebase.google.com) | Real-time NoSQL database with atomic rules |
| **Local Storage** | [SharedPreferences](https://pub.dev/packages/shared_preferences) | Persistent device configuration & theme caching |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.3.0`)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / Xcode with emulator or physical device configured
- Firebase CLI (`firebase-tools`) & FlutterFire CLI

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/IshraqRafi/WARA-Mobile-App.git
   cd WARA-Mobile-App
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   - Copy `lib/firebase_options.dart.example` to `lib/firebase_options.dart` and enter your Firebase credentials (or run `flutterfire configure`).
   - Place your `android/app/google-services.json` (for Android) and `ios/Runner/GoogleService-Info.plist` (for iOS) in their respective platform directories.
   *(Note: Platform secrets and `firebase_options.dart` are excluded via `.gitignore` to prevent credential exposure.)*

4. **Verify code quality:**
   ```bash
   flutter analyze
   ```

5. **Run the application:**
   ```bash
   flutter run
   ```

6. **Build release APK:**
   ```bash
   flutter build apk --release
   ```

---

## 📜 Digital Footprint & Development Log

To view the complete step-by-step development journey, problem-solving chronicles, and everyday milestone records, please refer to:
👉 **[PROGRESS.md](PROGRESS.md)**

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Crafted with passion by <a href="https://github.com/IshraqRafi">Ishraq Rafi</a> &amp; the <strong>WARA Studio</strong> team.
</p>
