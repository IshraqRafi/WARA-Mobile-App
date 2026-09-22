# 🚀 wara.io — Digital Footprint & Development Log

> This document serves as the official everyday progress journal and architectural chronicle for **wara.io (WARA Mobile App)**, tracking the technical evolution, design decisions, and milestones achieved throughout development.

---

## 📅 Chronological Milestone Log

```mermaid
timeline
    title wara.io Evolution & Development Milestones
    2026-07-24 : Project Scaffold & Clean Architecture : Flutter 3.x, Riverpod 2.x, GoRouter
    2026-08-10 : Firebase Backend & Dual Auth : Firestore Rules, Manager & Editor Roles
    2026-08-11 : Marketplace & Workflow Deck : Project Claim/Locking, Pipeline Management
    2026-09-22 : Profile Engine & Navigation Polish : Initials Avatar, Tab Persistence Fix
    2026-09-22 : Celestial Fluid Theme Engine : ThemeExtension lerp, Physics Sun/Moon Toggle
    2026-09-22 : Multi-Tenant Agency Workspaces : Open Manager Sign-up, Room Isolation, Join Keys
```

---

### 🔹 Milestone 1: Architectural Foundation & Project Scaffolding
- **Objective:** Establish an enterprise-ready, scalable Flutter foundation with feature-first modular architecture.
- **Key Deliverables:**
  - Initialized Flutter mobile application with support for Android and iOS targets.
  - Adopted **Feature-First Clean Architecture** dividing the codebase into `core/`, `features/`, and `shared/`.
  - Configured **Flutter Riverpod 2.x** for declarative state management, reactive streaming, and dependency injection.
  - Setup **GoRouter** for declarative URL-driven routing, route guards, and shell navigation.
  - Defined initial typography, spacing tokens, and base theme palette.

---

### 🔹 Milestone 2: Cloud Firestore Backend & Role-Based Authentication
- **Objective:** Enable secure user authentication and synchronize data in real-time across devices.
- **Key Deliverables:**
  - Integrated **Firebase Core** and **Cloud Firestore** with native Android and iOS configurations.
  - Formulated secure `firestore.rules` separating access permissions between **Managers** and **Editors**.
  - Built `AuthProvider` managing session state, credentials, and user role identification.
  - Designed the unified **Authentication Portal** with custom animated forms and role-based redirect guards.
  - Created Firestore user synchronization ensuring profiles, roles, and timestamps stay updated.

---

### 🔹 Milestone 3: Editor Marketplace & Real-Time Locking Engine
- **Objective:** Eliminate video project contention and provide editors with an intuitive self-serve job pool.
- **Key Deliverables:**
  - **Available Project Pool:** Stream of open video editing offers with real-time status indicators.
  - **Atomic Project Locking:** Guaranteed single-editor claim mechanism to prevent race conditions when multiple editors attempt to accept the same video project simultaneously.
  - **Project Metadata:** Payout counters (\$), real-time deadline countdowns, client niche tags, and asset cloud links.
  - **Active Editor Workspace:** Dedicated workspace view tracking claimed projects through in-progress editing, rendering, and submission states.
  - **Delivery Pipeline:** Integrated submission modal allowing editors to submit deliverables and cloud drive links directly to agency managers.

---

### 🔹 Milestone 4: Manager Agency OS & Financial Dashboard
- **Objective:** Empower creative directors and agency leads to manage high-volume video pipelines effortlessly.
- **Key Deliverables:**
  - **Global Agency Workflow Deck:** High-altitude visual kanban of all agency projects categorized by state (*Available*, *Claimed*, *In Review*, *Revision*, *Completed*).
  - **One-Click Project Dispatch:** Streamlined modal for managers to draft new video projects, set deadlines, attach reference links, and broadcast to the editor pool.
  - **Pending Submission Review Queue:** Review deck displaying editor submissions with side-by-side notes, asset links, and one-tap **Approve** or **Request Revision** actions.
  - **Financial Metrics & Ledger:** Agency financial oversight tab displaying gross revenue, pending editor payouts, completed earnings, and profit margins.

---

### 🔹 Milestone 5: Identity System & Router State Preservation
- **Objective:** Polish user identity, customize profile management, and resolve tab state navigation glitches.
- **Key Deliverables:**
  - **Navigation Tab Bug Fix:** Resolved a critical bug where updating profile information caused GoRouter to reset the active tab back to the initial "Available Pool". Migrated to state-preserving shell navigation.
  - **Unified "Profile" Space:** Rebranded the settings tab to **Profile**, bringing profile details, software proficiencies, bandwidth, and app settings into a unified screen.
  - **Smart Avatar Engine (`WaraAvatar`):**
    - Built a robust, app-wide avatar widget supporting network images with smooth fallback.
    - Implemented smart initials algorithm: extracts the first letter of the **Surname** followed by the first letter of the **First Name** (e.g., *Ishraq Rafi* $\rightarrow$ **RI**).
  - **Profile Editing Modal:** Interactive bottom sheet allowing editors and managers to update their display names and photo URLs in real-time with instant Firestore persistence.

---

### 🔹 Milestone 6: Celestial Theme Engine & Fluid Physics Toggle
- **Objective:** Deliver a visually stunning, high-contrast Dark/Light theme mode with organic, physics-based transitions.
- **Key Deliverables:**
  - **Dynamic Theme Extension (`AppColors`):**
    - Extended Flutter's `ThemeExtension<AppColors>` to enable full frame-by-frame color interpolation via `lerp()`.
    - Defined dual high-contrast palettes: **Midnight Slate** (`#0B0E14`) and **Pure Daylight** (`#F8FAFC`).
  - **Zero-Flash Transition (`AnimatedTheme`):**
    - Wrapped the application root in `AnimatedTheme` with a 400ms cubic bezier curve, ensuring background, surface, text, and card tones glide smoothly without abrupt flashes.
  - **Physics-Based Toggle Switch (`WaraThemeToggle`):**
    - **Liquid / Squish Physics:** Dynamic horizontal pill expansion (`math.sin(t * math.pi) * 8px`) that stretches the thumb from 30px to 38px during transit and snaps cleanly into a circle on arrival.
    - **Celestial Icon Dynamics:**
      - **Sun:** 180° rotation (`t * math.pi`), scale boost to `1.08x`, warm amber aura glow (`#F59E0B`).
      - **Moon:** -45° orbital tilt, scale boost to `1.08x`, luminescent silver-indigo aura (`#818CF8`).
    - **Atmospheric Details:** Twinkling night stars with staggered opacities and subtle daytime morning gradient.
  - **Universal Dark Logo Badge (`WaraLogo`):**
    - Engineered `WaraLogo` to enforce the iconic dark/black (`#141414`) background badge with crisp border and subtle elevation across both light and dark themes.
    - Eliminates washout of the white eye line-art emblem when viewing the app in high-brightness Sun (Light) mode.
  - **Persistent Theme Preferences:** Backed by `SharedPreferences` to preserve the user's theme selection across app restarts.

---

### 🔹 Milestone 7: Multi-Tenant Agency Rooms & Security Join Key Architecture
- **Objective:** Enable open registration for any Agency Manager to create private agency rooms/servers, and mandate unique security join keys for creative editors to enter the room.
- **Key Deliverables:**
  - **Open Manager Self-Registration:**
    - Removed hardcoded email whitelist restrictions. Any creative director or studio owner can register directly via email/password or Google Sign-In.
    - Dynamically prompts for Full Name and Agency / Studio Name during manager sign-up.
  - **Dynamic Agency Room Auto-Provisioning:**
    - Upon manager registration, automatically generates a unique `agencies` document in Cloud Firestore containing the manager's UID, agency branding, and an auto-generated unique Join Key.
    - Added readable key generation logic (`e.g. WARA-7742`, `APEX-9123`) combining prefix uppercase initials and a pseudo-random hash.
  - **Mandatory Editor Join Key Validation:**
    - Updated `EditorProfileSetupScreen` with an **Agency Room Join Key** input field.
    - Verifies the provided key against Firestore `agencies` collection. If invalid, shows user-friendly error guidance; if valid, binds editor to the manager's agency room.
  - **Manager Control Deck & Key Management:**
    - Added an **Agency Workspace & Room Key** card to `ManagerSettingsScreen` displaying the active agency name, join key badge, one-tap clipboard copy, and a confirmation modal to regenerate keys on demand.
    - Team seats modal automatically filters to show only live editors connected to this manager's agency room via `streamEditors(agencyId)`.
  - **Scoped Workspace Project Pipelines:**
    - Updated `project_provider.dart` to scope real-time Firestore listeners by `agencyId`.
    - Newly created projects by managers are automatically stamped with the manager's `agencyId`, ensuring zero data leakage between different agencies.
    - Preserved seamless demo accounts (`manager@gmail.com` / `manager` and `editor@gmail.com` / `editor`) pre-linked to demo agency (`agency_demo_wara`) for instant testing.

---

## 🛠️ Technical Problem Solving Highlights

| Problem Encountered | Root Cause | Engineering Solution |
| :--- | :--- | :--- |
| Hardcoded single manager email constraint | Legacy hardcoded email checks prevented any new manager from registering | Built dynamic manager registration with Firestore-backed agency workspaces and join keys. |
| Cross-agency project and team leakage | Single flat Firestore queries returned all data globally | Added `agencyId` indexing and scoped real-time query filtering across projects and editor seats. |
| Unverified editor onboarding | Anyone could join without organization permission | Implemented mandatory Agency Join Key validation before onboarding completion. |
| Tab reset on profile update | Provider re-evaluation caused navigation rebuild to index 0 | Preserved shell navigation state and decoupled tab index from profile stream triggers. |
| Abrupt screen flashing on theme change | Hardcoded color swaps without interpolation | Implemented Flutter `ThemeExtension<AppColors>` with custom `lerp()` and root `AnimatedTheme`. |
| WARA eye logo invisible in light mode | White line art logo blended into dynamic white surface container | Created universal `WaraLogo` badge preserving iconic dark background and subtle drop shadow in both themes. |
| Race conditions on video claiming | Concurrent editor taps on the same post | Atomically locked project records in Firestore using transaction rules. |
| Inflexible avatar rendering | Hardcoded asset paths scattered across screens | Created universal `WaraAvatar` with network caching, error boundaries, and smart initials generation. |

---

## 📈 Future Milestones & Roadmap
- [ ] Push Notifications for new video offers via Firebase Cloud Messaging (FCM).
- [ ] In-app video preview player with timecode-accurate feedback markers.
- [ ] Automated PDF invoice generation for agency clients and editor payout stubs.
- [ ] Offline caching support for workspace reviews and project briefs.
