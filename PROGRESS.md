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
    2026-09-23 : In-App Agency Messenger : Group Room & DMs, Team Presence, Media Link Sharing
    2026-09-23 : Session Persistence & UI Polish : Instant Auto-Login, Ghost Data Purge, 6 Fresh Posts, Icon-Only Dock
    2026-09-23 : Security Hardening & Secret Governance : Gitignore Policy, Untracked Credentials, Template Scaffold
    2026-09-23 : Custom Minimal Navigation Dock : WaraBottomBar, Pure Icon Pill Aesthetics, Zero Text Clutter
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

### 🔹 Milestone 8: Full In-App Agency Messenger & Direct Messaging System
- **Objective:** Eliminate communication silos and replace external apps (WhatsApp/Slack) with a native, real-time messenger tab connecting the entire agency in group discussions and private 1-on-1 DMs.
- **Key Deliverables:**
  - **Dedicated Navigation Branch for Both Roles:**
    - **Editor Shell** expanded from 3 to **4 Tabs**: `Available Pool` | `My Workspace` | **`Messenger`** | `Profile`.
    - **Manager Shell** expanded from 4 to **5 Tabs**: `Global Workflow` | `Pending` | `Finance` | **`Messenger`** | `Agency OS`.
  - **Agency Room Channel (`# agency-room`):**
    - High-altitude agency broadcast and discussion channel automatically provisioned for every agency workspace.
    - All verified managers and creative editors within the agency share a single room for drop alerts, timeline discussions, and creative banter.
  - **1-on-1 Direct Messages (DMs):**
    - Private messaging between any two members of the agency (Manager $\leftrightarrow$ Editor, Editor $\leftrightarrow$ Editor).
    - Deterministic ID formula (`dm_${[uid1, uid2]..sort().join('_')}`) guarantees both users always share the exact same thread without duplicates or race conditions.
  - **Team Presence & Quick DM Strip (`ChatMemberStrip`):**
    - Horizontal avatar strip displaying all active team members in the agency room with live online green dot indicators.
    - 1-tap on any avatar opens or provisions a private 1-on-1 chat room instantly.
  - **Interactive Chat Room Experience (`ChatRoomScreen` & `ChatBubble`):**
    - Theme-adaptive chat bubbles with smooth rounded corners, right-aligned for current user, left-aligned for others with sender role tags (`DIRECTOR` vs `EDITOR`).
    - Smart asset link detection: automatically detects Google Drive, Dropbox, Vimeo, and Frame.io URLs and renders an interactive cloud asset pill with 1-tap copy.
    - Floating link attachment sheet for quick asset dispatch with notes.
  - **Multi-Tenant Firestore Backend:**
    - All conversations and messages are stored under `agencies/{agencyId}/conversations/{convoId}/messages`, scoped strictly to the user's agency.
    - Pre-seeded realistic agency welcome communications in demo mode (`agency_demo_wara`) for instant hands-on testing.

---

### 🔹 Milestone 9: Persistent Session Engine, Ghost Data Purge & Minimal Navigation Dock
- **Objective:** Eliminate repetitive sign-in requirements upon app launch, purge all placeholder/dummy profiles and ghost-assigned works, seed 6 fresh unassigned marketplace opportunities, and create an uncluttered, icon-only navigation dock.
- **Key Deliverables:**
  - **Instant Local Auto-Login (`AuthProvider`):**
    - Stored serialized `UserSession` in `SharedPreferences` (`wara_auth_user_session_json`, `_keyIsLoggedIn`, `_keyUserRole`).
    - Overhauled `_loadInitialState()` to restore cached session immediately on startup without network roundtrips or forcing users back to the auth screen.
    - Updated authentication workflows (`login`, `registerManager`, `registerEditor`, `signInWithGoogle`, `updateProfile`) to keep local storage in sync, and `logout` to thoroughly wipe cached credentials.
  - **Purge of Dummy Profiles & Fallbacks:**
    - Cleaned `ChatMemberStrip` to remove hardcoded demo users (`Walid Islam`, `Alex Chen`, etc.), streaming only verified Firestore team members.
    - Updated `ManagerSettingsScreen` to eliminate static editor placeholders, showing an intuitive empty state when no team members have joined yet.
  - **Marketplace Reset & 6 Fresh Video Projects:**
    - Purged outdated and ghost-assigned video projects from database collections.
    - Seeded 6 fresh, diverse, high-value commercial video projects (`p_fresh_1` through `p_fresh_6`) into `kInitialProjectsData` and Cloud Firestore via `resetAndSeedFreshProjects()`.
    - All 6 projects are completely open, unassigned, and claimable by editors.
  - **Minimalist Icon-Only Bottom Navigation Dock:**
    - Configured `labelBehavior: NavigationDestinationLabelBehavior.alwaysHide` on navigation bars across both Manager and Editor shells.
    - Removed text labels for a clean, distraction-free aesthetic with 60px height and responsive indicator pills.

---

### 🔹 Milestone 10: Security Hardening & Secret Governance
- **Objective:** Secure Firebase platform configurations, resolve GitHub secret scanning warnings, and prevent accidental credential exposure in public repositories.
- **Key Deliverables:**
  - **Comprehensive `.gitignore` Hardening:**
    - Added `lib/firebase_options.dart` to `.gitignore`.
    - Added Apple platform configuration paths: `**/ios/Runner/GoogleService-Info.plist` and `**/macos/Runner/GoogleService-Info.plist`.
    - Expanded environment file ignoring with `.env.*` and `*.env` wildcards.
  - **Sanitized Firebase Options Template:**
    - Authored `lib/firebase_options.dart.example` containing clean placeholder variables (`YOUR_FIREBASE_API_KEY_HERE`, `YOUR_APP_ID`, etc.).
    - Enables new team members and CI/CD pipelines to bootstrap configurations safely without leaking live project secrets.
  - **Git Cache Untracking:**
    - Executed `git rm --cached lib/firebase_options.dart` to purge live credentials from future commits and GitHub tree representation while preserving the physical file on local development environments.
  - **Developer Onboarding Documentation:**
    - Updated `README.md` file tree and installation guide with step-by-step instructions on bootstrapping Firebase credentials.

---

### 🔹 Milestone 11: Dedicated Minimalist Navigation Dock (`WaraBottomBar`)
- **Objective:** Eliminate all bottom menu text labels across Manager and Editor shells, creating a custom, high-end icon-only navigation dock.
- **Key Deliverables:**
  - **Engineered Custom `WaraBottomBar` Widget:**
    - Authored `lib/shared/widgets/wara_bottom_bar.dart` replacing Flutter's rigid Material 3 `NavigationBar`.
    - Pure icon layout with zero text, zero tooltips, and zero label spacing artifacts.
  - **Fluid Active Pill Highlights:**
    - High-contrast animated capsule (`240ms`, `Curves.easeOutCubic`) highlighting the active destination with `colors.primary.withValues(alpha: 0.14)` and a subtle `0.28` border stroke.
    - Active icon renders in solid `colors.primary`, while inactive icons sit in calm, muted tones (`colors.muted.withValues(alpha: 0.8)`).
  - **Ergonomics & Multi-Platform Safe Area:**
    - Standardized dock height to 62px with wrapped `SafeArea(top: false)`.
    - Integrated touch feedback (`InkResponse`) with non-intrusive splash radiuses.
  - **Complete Shell Unification:**
    - Connected `WaraBottomBar` to `_EditorShell` (4 tabs: Marketplace, Workspace, Messenger, Profile) and `_ManagerShell` (5 tabs: Workflow, Pending, Finance, Messenger, Agency OS) via GoRouter's `shell.goBranch`.

---

### 🔹 Milestone 12: Real-Time Alerts Center, Editor Rating Engine & Agency Creative Leaderboard
- **Objective:** Build an end-to-end performance tracking and alerting ecosystem comprising real-time in-app notifications, manager-driven editor ratings per project, and a live agency creative leaderboard.
- **Key Deliverables:**
  - **In-App Notification Center & Quick Alerts (`NotificationBellButton` & `showNotificationCenter`):**
    - Created `lib/features/notifications/domain/notification_models.dart` & `notification_provider.dart` streaming real-time alerts (`AppNotification`) with unread badge counters.
    - Built draggable notification sheet with categorized event icons (project drops, claim alerts, submission reviews, ratings), relative timestamps, and 1-tap "Mark all as read".
    - Embedded `NotificationBellButton` across Manager Workflow, Manager Pending, and Editor Available headers.
  - **Manager-Driven Editor Rating Engine (`showRateEditorSheet` & `rateEditor`):**
    - Added atomic cumulative rating calculations (`rating`, `ratingCount`, `totalStars`, `completedProjects`) in Firestore.
    - Designed interactive 1-5 star selector with animated scale feedback, quick review tags (*Flawless Cut*, *Fast Turnaround*, *Superb Color*, etc.), and review notes.
    - Integrated rating prompt directly into "Approve & Pay" actions in Manager Workflow and Manager Pending screens, automatically alerting editors upon approval.
  - **Agency Creative Leaderboard (`AgencyLeaderboardCard` & `showAgencyLeaderboardModal`):**
    - Built live performance leaderboard ordered by star rating and completed deliverables.
    - Designed distinctive podium badges: 🥇 #1 Gold Leader, 🥈 #2 Silver Top, 🥉 #3 Bronze Rising, plus rank indicators for all active editors.
    - Highlighted current user with an accent outline and `YOU` badge.
    - Embedded personal standing summary card directly into the Editor's Profile screen and accessible from Manager Agency OS settings.
  - **Messenger & Database Refinements:**
    - Purged theme toggle from Messenger header (retaining theme switching strictly in Profile tabs).
    - Redesigned search bar with 46px pill aesthetics, live Firestore member querying, and 1-tap direct messaging.
    - Resolved "No editors in this room yet" seat bug by incorporating display name fallback to email handles for fresh Gmail signups.
    - Added `resetAgencyRoom()` ensuring `# agency-room` initializes with an official director welcome post.

---

### 🔹 Milestone 13: Numerical Notification Badges, Messenger Direct Messages Overhaul, Floating Action Button & Team Card Redesign
- **Objective:** Refine notification counter aesthetics with numerical badges, overhaul Direct Messages into an automatic single-profile stream with cleaner headers, fix search bar visual artifacts, relieve Manager header crowding with a floating action button, and redesign Editor/Staff team cards with zero horizontal overflows.
- **Key Deliverables:**
  - **Exact Numerical Notification Badges:**
    - Upgraded `NotificationBellButton` with an outer Stack badge positioned at `top: -4, right: -4`.
    - Renders high-contrast red pill with `1, 2, 3...` or `9+` count, bold white typography, and protective `colors.bg` border stroke.
  - **Messenger Direct Messages Clean Overhaul:**
    - Purged legacy `"Direct message started with..."` placeholder message generation upon starting direct chats.
    - Direct Messages tab now automatically streams all verified agency team members, listing each profile **exactly once**.
    - Removed cluttered top banner texts (`"TEAM DIRECT MESSAGES"` and `"Tap member to chat"`).
    - Displays actual latest conversation message preview if one exists; otherwise falls back gracefully to specialization (*e.g., Video Editor / Agency Director*) and `'Active'`.
  - **Glitched Search Bar Resolution:**
    - Replaced nested container/theme decoration collision with a single 24px `OutlineInputBorder` directly on the `TextField`, producing a smooth, unified, glitch-free search pill.
  - **Manager Floating Action Button:**
    - Removed crowded "Post Offer" button from the Manager Workflow header, giving branding and title ample room to breathe.
    - Introduced a sleek floating action button (`FloatingActionButton` with 16px rounded corners and `+` icon) positioned at the bottom right corner right above the footer dock.
  - **Zero-Overflow Team Seats Card Redesign:**
    - Completely overhauled `_EditorCard` in `ManagerSettingsScreen` with a modern, spacious card layout.
    - Replaced rigid horizontal spans with responsive `Wrap` widgets for metrics (⭐ rating pill, 🎬 completed cuts count, ⏱️ weekly availability, and active working day chips).
    - Guaranteed zero RenderFlex overflow warnings regardless of mobile viewport width.
    - Added full-width "Rate & Review Editor" action button.

---

### 🔹 Milestone 14: Header Streamlining, Footer Gap Elimination, Messenger Auto-Top & Instant Rating Reordering
- **Objective:** Streamline Manager Home & Pending headers and layouts, eliminate the black bar gap above footer dock on Home and Pending screens, implement real-time Messenger unread and recent activity sorting bringing active threads to the top for both sender and receiver, add high-contrast receiver border highlight with `NEW` badge, and implement direct database rating instances with instant real-time list reordering.
- **Key Deliverables:**
  - **Header & Subheader Streamlining:**
    - Removed `'Overseeing all agency projects & editor allocations'` on Manager Home.
    - Positioned `'Manager Control'` badge directly below `'wara.io'` in a balanced vertical stack.
    - Removed `'Tap card to inspect / edit'`; retained solely `'All agency projects'` as the clean section header.
  - **Footer Black Bar Gap Elimination (Home & Pending):**
    - Configured `SafeArea(bottom: false)` on both `ManagerWorkflowScreen` and `ManagerPendingScreen`.
    - Localized screen padding to the top static header content, extending the `ListView.builder` viewport all the way down to the top edge of `WaraBottomBar`.
    - Completely eliminated the clipped black gap; cards now scroll smoothly right into the bottom navigation bar.
  - **Real-Time Messenger Auto-Top Sorting:**
    - Engineered dynamic multi-tier sorting for Direct Messages:
      1. Unread incoming conversations for the current user come to the very top.
      2. Active conversations sorted by `lastMessageTime` descending, bringing threads to the top for **both sender and receiver**.
      3. Inactive profiles without messages sorted alphabetically.
  - **Receiver Border Highlight & NEW Badge:**
    - Added `lastSenderId` and `readBy` user ID tracking to `ChatConversation` in Firestore.
    - Highlighted the receiver's unread conversation tile with a 1.8px primary border, subtle background tint, and a high-contrast `NEW` badge.
    - Integrated `markAsRead` calls upon tile tap and `ChatRoomScreen` mount to automatically clear the highlight once read.
  - **Instant Rating Instance & Real-Time Reorder:**
    - Updated `rateEditor` in `FirestoreService` to apply the manager's assigned rating directly to the editor's profile in Firestore (e.g. 1 star sets `rating: 1.0` directly rather than averaging with historic scores).
    - Enhanced `streamEditors` to ensure `data['id'] = data['id'] ?? doc.id` and fallback to `doc.id` for robust user document referencing.
    - Because `streamEditors` is a live Firestore snapshot listener, any rating change immediately re-sorts the list in real time, automatically dropping a 1-star editor to the bottom across both Team Seats and Leaderboards.

### Milestone 15: Google Profile Unification, Self-Exclusion in DMs, Synthetic Director Removal & In-App Chat Notification Counter
- **Self-Profile Exclusion in Direct Messages:**
  - Resolved manager/editor self-visibility bug by extracting logged-in user Google account email (`FirebaseAuth.instance.currentUser?.email` & `user?.email`, lowercased) and auth UIDs (`FirebaseAuth.instance.currentUser?.uid` & `user?.id`).
  - Filtered out any profile whose email or ID matches the current user, guaranteeing users NEVER see their own profile in Direct Messages regardless of multi-role test accounts.
  - Deduplicated team member list by Google email, unifying multiple historical Firestore records (e.g. editor + manager logins) into a single direct message profile.
- **Removed Synthetic "WARA Media Group Director":**
  - Completely purged the synthetic `'manager_director'` dictionary from `ChatInboxScreen`.
  - Created `streamAgencyTeamMembers({String? agencyId})` in `FirestoreService` to stream all real, authentic agency members (both managers and editors) directly from the Firestore `users` collection.
- **Wired Messenger to In-App Notification Center:**
  - Added optional `senderId` to `AppNotification` to differentiate event initiators from event receivers.
  - Updated `FirestoreService.sendChatMessage` to dispatch an `AppNotification` (`NotificationType.chatMessage`):
    - For Direct Messages: accurately targeted to recipient UID (`userId: recipientId`, `senderId: sender.id`), dynamically incrementing the recipient's notification bell counter (`1, 2, 3...`).
    - For Channel Messages: broadcast to agency (`userId: null`, `senderId: sender.id`), notifying all team members while excluding the sender from receiving their own alert.
  - Updated `streamNotifications` to filter out self-notifications (`senderId != userId`).
  - Wired `ChatRoomScreen` to pass `recipientId: widget.otherUserId` upon message and asset link transmission.
  - Enhanced `NotificationCenterSheet` to navigate directly to the conversation room when a chat notification tile is tapped.
- **System Pop-Up (Push) Notifications Architecture Blueprint:**
  - Authored comprehensive production plan for native OS heads-up banners on Android & iOS using Firebase Cloud Messaging (FCM) and `flutter_local_notifications`.

---

## 🛠️ Technical Problem Solving Highlights

| Problem Encountered | Root Cause | Engineering Solution |
| :--- | :--- | :--- |
| Manager seeing own profile in Direct Messages | Case sensitivity, mismatch between Firestore user ID and Google Auth UID, and separate editor records created during role testing | Extracted both Google Auth email and user session email into lowercased lookup sets and excluded any profile matching email or UID. |
| Synthetic "WARA Media group director" in messenger | Hardcoded dummy map was added to simulate managers when `streamEditors` only returned editor roles | Removed synthetic map and implemented `streamAgencyTeamMembers` to stream real managers and editors from Firestore. |
| Chat messages not incrementing notification counter | `sendChatMessage` only wrote to conversation messages subcollection without creating an `AppNotification` | Wired `sendChatMessage` to dispatch real-time `AppNotification` (`NotificationType.chatMessage`) targeted to recipient UID with `senderId` exclusion. |
| :--- | :--- | :--- |
| GitHub Secret Scanning alert on Google API key | `lib/firebase_options.dart` was tracked in git with hardcoded Firebase credentials | Untracked file via `git rm --cached`, hardened `.gitignore`, provided sanitized template `firebase_options.dart.example`. |
| Forced re-login on every app cold start | `_loadInitialState()` always reset state to unauthenticated | Added local session serialization in `SharedPreferences` for instant ~2ms restoration on launch. |
| Cluttered bottom navigation with crowded text | Navigation bar labels occupied excessive vertical space | Configured `labelBehavior: NavigationDestinationLabelBehavior.alwaysHide` for a clean icon-only dock. |
| Ghost editor assignments & dummy chat members | Fallback mock arrays persisted in chat strips and settings | Purged hardcoded lists; wired screens exclusively to live, verified Firestore streams. |
| Outdated marketplace with pre-assigned projects | Test database contained legacy posts assigned to nonexistent editors | Built `resetAndSeedFreshProjects()` to clear old data and seed 6 brand-new unassigned jobs. |
| External communication silos (WhatsApp/Discord) | Project discussions and asset sharing occurred outside the app | Built native in-app Messenger tab with Agency Group Channel (`# agency-room`) and 1-on-1 Direct Messages. |
| Duplicate DM thread race conditions | Uncoordinated thread creation when two users message concurrently | Implemented deterministic conversation IDs (`dm_uid1_uid2`) using alphabetically sorted participant UIDs. |
| Cumbersome asset link copying in chat | Plain text URLs easily get lost in chat streams | Created regex-driven `hasAssetLink` detector rendering interactive cloud asset pills with 1-tap clipboard copy. |
| Hardcoded single manager email constraint | Legacy hardcoded email checks prevented any new manager from registering | Built dynamic manager registration with Firestore-backed agency workspaces and join keys. |
| Cross-agency project and team leakage | Single flat Firestore queries returned all data globally | Added `agencyId` indexing and scoped real-time query filtering across projects and editor seats. |
| Unverified editor onboarding | Anyone could join without organization permission | Implemented mandatory Agency Join Key validation before onboarding completion. |
| Tab reset on profile update | Provider re-evaluation caused navigation rebuild to index 0 | Preserved shell navigation state and decoupled tab index from profile stream triggers. |
| Abrupt screen flashing on theme change | Hardcoded color swaps without interpolation | Implemented Flutter `ThemeExtension<AppColors>` with custom `lerp()` and root `AnimatedTheme`. |
| WARA eye logo invisible in light mode | White line art logo blended into dynamic white surface container | Created universal `WaraLogo` badge preserving iconic dark background and subtle drop shadow in both themes. |
| Race conditions on video claiming | Concurrent editor taps on the same post | Atomically locked project records in Firestore using transaction rules. |
| Inflexible avatar rendering | Hardcoded asset paths scattered across screens | Created universal `WaraAvatar` with network caching, error boundaries, and smart initials generation. |
| "No editors in this room yet" despite registered editors | Null name fields on Gmail registrations and overly strict agencyId filters silently excluded valid accounts | Relaxed stream matching to include unassigned editors, auto-fallback blank names to email prefixes, defaulted initial ratings to 5.0. |
| Untracked editor performance and lack of merit rankings | Agency managers had no mechanism to rate delivered projects or recognize top creative talent | Built atomic rating calculations (`rateEditor`), interactive 5-star review modal upon approval, and live Agency Creative Leaderboard. |
| Glitched rectangular box inside rounded search pill | Theme `inputDecorationTheme` had 16px radius conflicting with parent Container 24px border radius | Applied 24px `OutlineInputBorder` directly across all states in `TextField.decoration`. |
| Cluttered Manager workflow header | Header row crammed logo, title, and "Post Offer" button into narrow screen space | Removed header button and introduced floating action button above footer navigation dock. |
| RenderFlex horizontal overflow on team seats cards | Rigid `Row` with multiple fixed-width metrics and labels exceeded mobile screen widths | Implemented responsive `Wrap` metric chips and text ellipsis for names and portfolio links. |
| Ugly black bar gap above footer menu on Home and Pending | Outer `Padding(all: 20)` and default `SafeArea(bottom: true)` clipped `ListView` viewport 20px+ above `WaraBottomBar` | Configured `SafeArea(bottom: false)`, scoped padding to static header, and extended `ListView` viewport directly to bottom bar. |
| Messenger messages not bubbling to top | `filteredMembers` did not sort members by conversation activity or unread status | Implemented dynamic sorting by unread status, `lastMessageTime` descending, and alphabetical order. |
| Lack of unread conversation indicator on Messenger | Incoming messages looked identical to inactive conversation tiles | Added `lastSenderId`/`readBy` tracking, 1.8px primary border highlight, background tint, and `NEW` badge for receivers. |
| Editor ratings dampened by historic average preventing real-time rank drops | `(totalStars + rating) / (ratingCount + 1)` calculation prevented 1-star ratings from immediately dropping 5-star editors | Made manager rating a direct database instance (`rating = newRating`) triggering real-time `streamEditors` reordering. |

---

## 📈 Future Milestones & Roadmap
- [ ] Push Notifications for new video offers via Firebase Cloud Messaging (FCM).
- [ ] In-app video preview player with timecode-accurate feedback markers.
- [ ] Automated PDF invoice generation for agency clients and editor payout stubs.
- [ ] Offline caching support for workspace reviews and project briefs.
