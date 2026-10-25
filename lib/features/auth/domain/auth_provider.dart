import 'dart:convert';
import '../../../core/constants/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firestore_service.dart';

class UserSession {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String agencyName;
  final String? agencyId;
  final String? agencyJoinKey;
  final List<String> skills;
  final int hoursPerWeek;
  final List<String> activeDays;
  final String? photoUrl;
  final String? specialization;
  final String? portfolioLink;
  final bool isProfileComplete;

  const UserSession({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.agencyName,
    this.agencyId,
    this.agencyJoinKey,
    required this.skills,
    required this.hoursPerWeek,
    required this.activeDays,
    this.photoUrl,
    this.specialization,
    this.portfolioLink,
    this.isProfileComplete = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'agencyName': agencyName,
      if (agencyId != null) 'agencyId': agencyId,
      if (agencyJoinKey != null) 'agencyJoinKey': agencyJoinKey,
      'skills': skills,
      'hoursPerWeek': hoursPerWeek,
      'activeDays': activeDays,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (specialization != null) 'specialization': specialization,
      if (portfolioLink != null) 'portfolioLink': portfolioLink,
      'isProfileComplete': isProfileComplete,
    };
  }

  factory UserSession.fromMap(Map<String, dynamic> map) {
    return UserSession(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: map['role'] == 'manager' ? UserRole.manager : UserRole.editor,
      agencyName: map['agencyName'] as String? ?? '',
      agencyId: map['agencyId'] as String?,
      agencyJoinKey: map['agencyJoinKey'] as String?,
      skills: List<String>.from(map['skills'] ?? []),
      hoursPerWeek: (map['hoursPerWeek'] as num?)?.toInt() ?? 35,
      activeDays: List<String>.from(map['activeDays'] ?? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']),
      photoUrl: map['photoUrl'] as String?,
      specialization: map['specialization'] as String?,
      portfolioLink: map['portfolioLink'] as String?,
      isProfileComplete: map['isProfileComplete'] as bool? ?? true,
    );
  }

  UserSession copyWith({
    String? name,
    String? agencyName,
    String? agencyId,
    String? agencyJoinKey,
    List<String>? skills,
    int? hoursPerWeek,
    List<String>? activeDays,
    String? photoUrl,
    bool clearPhotoUrl = false,
    String? specialization,
    String? portfolioLink,
    bool? isProfileComplete,
  }) {
    return UserSession(
      id: id,
      email: email,
      name: name ?? this.name,
      role: role,
      agencyName: agencyName ?? this.agencyName,
      agencyId: agencyId ?? this.agencyId,
      agencyJoinKey: agencyJoinKey ?? this.agencyJoinKey,
      skills: skills ?? this.skills,
      hoursPerWeek: hoursPerWeek ?? this.hoursPerWeek,
      activeDays: activeDays ?? this.activeDays,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      specialization: specialization ?? this.specialization,
      portfolioLink: portfolioLink ?? this.portfolioLink,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }
}

/// A Google account that signed in but has no wara.io profile yet. The user
/// picks a path on the welcome screen: create an agency or join as an editor.
class PendingGoogleUser {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;

  /// Role chosen on the login screen. A new account is created with it.
  final UserRole role;

  const PendingGoogleUser({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    this.role = UserRole.editor,
  });
}

class AuthState {
  final bool isAuthenticated;
  final UserSession? user;
  final PendingGoogleUser? pendingUser;

  /// Set when the signed-in user's profile could not be read (offline,
  /// timeout, permission). Onboarding shows a retry instead of the form so
  /// an existing account is never treated as new.
  final String? loadError;

  const AuthState({
    required this.isAuthenticated,
    this.user,
    this.pendingUser,
    this.loadError,
  });

  bool get needsOnboarding => !isAuthenticated && pendingUser != null;
}

typedef AuthResult = ({bool success, String? error});

/// Result of a Google sign-in. [roleMismatch] holds the stored role when it
/// differs from the role selected on the login screen (the stored one wins).
typedef SignInResult = ({bool success, String? error, UserRole? roleMismatch});

class AuthNotifier extends StateNotifier<AuthState> {
  static const _keyIsLoggedIn = 'wara_auth_is_logged_in';
  static const _keyUserRole = 'wara_auth_user_role';
  static const _keyUserSessionJson = 'wara_auth_user_session_json';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: AppConfig.googleServerClientId,
  );
  final FirestoreService _firestoreService = FirestoreService();

  AuthNotifier() : super(const AuthState(isAuthenticated: false)) {
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    try {
      final fbUser = _auth.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      final sessionJson = prefs.getString(_keyUserSessionJson);

      // 1. Instant restore of the cached session, only if it belongs to the
      //    Firebase user that is still signed in.
      if (fbUser != null && isLoggedIn && sessionJson != null && sessionJson.isNotEmpty) {
        final session = UserSession.fromMap(jsonDecode(sessionJson) as Map<String, dynamic>);
        if (session.id == fbUser.uid) {
          state = AuthState(isAuthenticated: true, user: session);
          if (session.role == UserRole.manager && (session.agencyId ?? '').isNotEmpty) {
            _firestoreService.ensureJoinKeyIndex(session.agencyId!, session.agencyJoinKey ?? '', session.agencyName);
          }
          return;
        }
      }

      // 2. Rebuild from Firestore for the signed-in Firebase user.
      if (fbUser != null) {
        await _resolveSignedInUser(fbUser);
        return;
      }
    } catch (e) {
      debugPrint('Auth restore failed: $e');
    }

    state = const AuthState(isAuthenticated: false);
  }

  Future<void> _persistSession(UserSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserRole, session.role.name);
      await prefs.setString(_keyUserSessionJson, jsonEncode(session.toMap()));
    } catch (_) {}
  }

  Future<void> _setSession(UserSession session) async {
    await _persistSession(session);
    state = AuthState(isAuthenticated: true, user: session);
  }

  PendingGoogleUser _pendingFrom(User fbUser, {UserRole role = UserRole.editor}) {
    final email = (fbUser.email ?? '').trim().toLowerCase();
    final display = (fbUser.displayName ?? '').trim();
    return PendingGoogleUser(
      uid: fbUser.uid,
      email: email,
      name: display.isNotEmpty ? display : email.split('@').first,
      photoUrl: fbUser.photoURL,
      role: role,
    );
  }

  /// Loads the profile for [fbUser]. Users without a profile (or a manager
  /// without an agency) are sent to onboarding instead of getting defaults.
  /// [requestedRole] only applies to accounts without a stored role; an
  /// existing profile always keeps its role. Returns the resolved role.
  Future<UserRole?> _resolveSignedInUser(User fbUser, {UserRole? requestedRole}) async {
    final Map<String, dynamic>? profile;
    try {
      profile = await _firestoreService.getUserProfile(fbUser.uid);
    } catch (e) {
      debugPrint('Profile read failed: $e');
      state = AuthState(
        isAuthenticated: false,
        pendingUser: _pendingFrom(fbUser, role: requestedRole ?? UserRole.editor),
        loadError: "Couldn't load your account. Check your connection and try again.",
      );
      return null;
    }
    if (profile == null || profile['role'] == null) {
      state = AuthState(
        isAuthenticated: false,
        pendingUser: _pendingFrom(fbUser, role: requestedRole ?? UserRole.editor),
      );
      return null;
    }

    final role = profile['role'] == 'manager' ? UserRole.manager : UserRole.editor;
    String? agencyId = profile['agencyId'] as String?;
    String? agencyName = profile['agencyName'] as String?;
    String? agencyJoinKey = profile['agencyJoinKey'] as String?;

    if (role == UserRole.manager) {
      if (agencyId == null || agencyId.isEmpty) {
        state = AuthState(isAuthenticated: false, pendingUser: _pendingFrom(fbUser, role: UserRole.manager));
        return role;
      }
      // Keep the manager's copy of the join key in sync with the agency doc.
      final agency = await _firestoreService.getAgencyById(agencyId);
      if (agency != null) {
        agencyName = agency.name;
        agencyJoinKey = agency.joinKey;
        _firestoreService.ensureJoinKeyIndex(agency.id, agency.joinKey, agency.name);
      }
    }

    final pending = _pendingFrom(fbUser);
    final profileName = (profile['name'] as String? ?? '').trim();
    final session = UserSession(
      id: fbUser.uid,
      email: (profile['email'] as String?) ?? pending.email,
      name: profileName.isNotEmpty ? profileName : (role == UserRole.manager ? pending.name : ''),
      role: role,
      agencyName: agencyName ?? '',
      agencyId: agencyId,
      agencyJoinKey: agencyJoinKey,
      skills: List<String>.from(profile['skills'] ?? const <String>[]),
      hoursPerWeek: (profile['hoursPerWeek'] as num?)?.toInt() ?? 35,
      activeDays: List<String>.from(profile['activeDays'] ?? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']),
      photoUrl: (profile['photoUrl'] as String?) ?? fbUser.photoURL,
      specialization: profile['specialization'] as String?,
      portfolioLink: profile['portfolioLink'] as String?,
      isProfileComplete: role == UserRole.manager || profile['isProfileComplete'] == true,
    );
    await _setSession(session);
    return role;
  }

  /// Editor without a working agency joins one by key from Settings.
  /// Returns null on success or a terse error.
  Future<String?> joinAgencyWithKey(String key) async {
    final user = state.user;
    if (user == null) return 'Sign in again';
    try {
      final agency = await _firestoreService.validateAndGetAgencyByKey(key);
      if (agency == null) return 'Invalid key';
      await _firestoreService.joinAgency(user.id, agency.id, agency.name, agency.joinKey);
      final updated = user.copyWith(agencyId: agency.id, agencyName: agency.name, agencyJoinKey: agency.joinKey);
      await _setSession(updated);
      return null;
    } on FirebaseException catch (e) {
      debugPrint('joinAgencyWithKey failed: ${e.code}');
      return e.code == 'permission-denied' ? 'Already in an agency' : 'Could not join';
    } catch (e) {
      debugPrint('joinAgencyWithKey failed: $e');
      return 'Could not join';
    }
  }

  /// Retry after a failed profile read (see [AuthState.loadError]).
  Future<void> retryProfileLoad() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) {
      state = const AuthState(isAuthenticated: false);
      return;
    }
    await _resolveSignedInUser(fbUser, requestedRole: state.pendingUser?.role);
  }

  /// Google is the only sign-in method. [role] is the role selected on the
  /// login screen; it is used for new accounts only.
  Future<SignInResult> signInWithGoogle({UserRole role = UserRole.editor}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return (success: false, error: null, roleMismatch: null); // cancelled by the user
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final fbUser = userCred.user;
      if (fbUser == null) {
        return (success: false, error: 'Google sign-in failed. Try again.', roleMismatch: null);
      }
      final stored = await _resolveSignedInUser(fbUser, requestedRole: role);
      return (success: true, error: null, roleMismatch: (stored != null && stored != role) ? stored : null);
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign-in FirebaseAuthException: ${e.code}');
      return (success: false, error: 'Google sign-in failed (${e.code}).', roleMismatch: null);
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      return (success: false, error: 'Google sign-in failed. Check your connection.', roleMismatch: null);
    }
  }

  /// Onboarding: the pending Google user creates a new agency and becomes its manager.
  Future<AuthResult> createAgencyAsManager(String agencyName) async {
    final pending = state.pendingUser;
    if (pending == null) return (success: false, error: 'Please sign in again.');
    final cleanAgency = agencyName.trim();
    if (cleanAgency.length < 2) {
      return (success: false, error: 'Please enter your agency name.');
    }

    // Re-check the stored profile first: an account that already has a
    // role or agency must never get a second agency (the rules lock
    // agencyId and role once set, which is what made this fail before).
    try {
      final existing = await _firestoreService.getUserProfile(pending.uid);
      if (existing != null && existing['role'] != null) {
        final fbUser = _auth.currentUser;
        if (fbUser != null) await _resolveSignedInUser(fbUser);
        if (state.isAuthenticated) return (success: true, error: null);
        if (existing['role'] != 'manager') {
          return (success: false, error: 'This account is registered as an editor.');
        }
        if ((existing['agencyId'] as String? ?? '').isNotEmpty) {
          return (success: false, error: "Couldn't load your agency. Please try again.");
        }
      }
    } catch (e) {
      debugPrint('createAgencyAsManager profile check failed: $e');
      return (success: false, error: "Couldn't reach the server. Check your connection and try again.");
    }

    try {
      final agency = await _firestoreService.createAgency(
        name: cleanAgency,
        managerUid: pending.uid,
        managerName: pending.name,
      );
      await _firestoreService.saveUserProfile(
        uid: pending.uid,
        email: pending.email,
        name: pending.name,
        role: UserRole.manager,
        skills: const [],
        hoursPerWeek: 40,
        activeDays: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        isProfileComplete: true,
        agencyId: agency.id,
        agencyName: agency.name,
        agencyJoinKey: agency.joinKey,
        photoUrl: pending.photoUrl,
      );
      await _setSession(UserSession(
        id: pending.uid,
        email: pending.email,
        name: pending.name,
        role: UserRole.manager,
        agencyName: agency.name,
        agencyId: agency.id,
        agencyJoinKey: agency.joinKey,
        skills: const [],
        hoursPerWeek: 40,
        activeDays: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        photoUrl: pending.photoUrl,
        isProfileComplete: true,
      ));
      return (success: true, error: null);
    } catch (e) {
      debugPrint('createAgencyAsManager failed: $e');
      return (success: false, error: 'Could not create your agency. Please try again.');
    }
  }

  /// Onboarding: the pending Google user continues as an editor. They finish
  /// their profile (including the agency join key) on the profile setup screen.
  Future<AuthResult> continueAsEditor() async {
    final pending = state.pendingUser;
    if (pending == null) return (success: false, error: 'Please sign in again.');

    try {
      await _firestoreService.saveUserProfile(
        uid: pending.uid,
        email: pending.email,
        name: pending.name,
        role: UserRole.editor,
        skills: const [],
        hoursPerWeek: 35,
        activeDays: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        isProfileComplete: false,
        photoUrl: pending.photoUrl,
      );
      await _setSession(UserSession(
        id: pending.uid,
        email: pending.email,
        name: pending.name,
        role: UserRole.editor,
        agencyName: '',
        skills: const [],
        hoursPerWeek: 35,
        activeDays: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        photoUrl: pending.photoUrl,
        isProfileComplete: false,
      ));
      return (success: true, error: null);
    } catch (e) {
      debugPrint('continueAsEditor failed: $e');
      return (success: false, error: 'Could not set up your account. Please try again.');
    }
  }

  /// Complete Editor Profile Setup with Agency Join Key validation
  Future<void> completeProfile({
    required String name,
    required String specialization,
    required List<String> skills,
    required int hoursPerWeek,
    required List<String> activeDays,
    required String portfolioLink,
    String? photoUrl,
    String? agencyJoinKey,
  }) async {
    if (state.user != null) {
      final current = state.user!;
      String? agencyId = current.agencyId;
      String agencyName = current.agencyName;
      String? validJoinKey = current.agencyJoinKey;

      if (agencyJoinKey != null && agencyJoinKey.trim().isNotEmpty) {
        final agency = await _firestoreService.validateAndGetAgencyByKey(agencyJoinKey.trim());
        if (agency == null) {
          throw Exception('Agency Join Key "$agencyJoinKey" was not found. Please verify the code with your Agency Manager.');
        }
        agencyId = agency.id;
        agencyName = agency.name;
        validJoinKey = agency.joinKey;
      }
      if (agencyId == null || agencyId.isEmpty) {
        throw Exception('Enter the agency join key your manager shared with you.');
      }

      final photo = photoUrl ?? current.photoUrl;
      await _firestoreService.completeEditorProfile(
        uid: current.id,
        name: name,
        specialization: specialization,
        skills: skills,
        hoursPerWeek: hoursPerWeek,
        activeDays: activeDays,
        portfolioLink: portfolioLink,
        photoUrl: photo,
        agencyId: agencyId,
        agencyName: agencyName,
        agencyJoinKey: validJoinKey,
      );

      final updated = current.copyWith(
        name: name,
        specialization: specialization,
        skills: skills,
        hoursPerWeek: hoursPerWeek,
        activeDays: activeDays,
        portfolioLink: portfolioLink,
        photoUrl: photo,
        agencyId: agencyId,
        agencyName: agencyName,
        agencyJoinKey: validJoinKey,
        isProfileComplete: true,
      );

      await _persistSession(updated);
      state = AuthState(
        isAuthenticated: true,
        user: updated,
      );
    }
  }

  /// Regenerate agency join key (Manager only)
  Future<String?> regenerateAgencyKey() async {
    final user = state.user;
    if (user == null || user.agencyId == null) return null;

    try {
      final newKey = await _firestoreService.regenerateAgencyKey(
        user.agencyId!,
        user.agencyName,
        oldKey: user.agencyJoinKey,
      );
      final updated = user.copyWith(agencyJoinKey: newKey);
      await _persistSession(updated);
      state = AuthState(
        isAuthenticated: true,
        user: updated,
      );
      await _firestoreService.updateUserProfile(user.id, {'agencyJoinKey': newKey});
      return newKey;
    } catch (_) {
      return null;
    }
  }

  /// Rename the agency (manager only). Returns false on failure.
  Future<bool> renameAgency(String name) async {
    final user = state.user;
    final clean = name.trim();
    if (user == null || user.role != UserRole.manager || user.agencyId == null || clean.length < 2) return false;
    try {
      await _firestoreService.renameAgency(user.agencyId!, user.agencyJoinKey ?? '', clean);
      final updated = user.copyWith(agencyName: clean);
      await _persistSession(updated);
      state = AuthState(isAuthenticated: true, user: updated);
      await _firestoreService.updateUserProfile(user.id, {'agencyName': clean});
      return true;
    } catch (_) {
      return false;
    }
  }

  void updateEditorSkills(List<String> newSkills) {
    if (state.user != null) {
      final updated = state.user!.copyWith(skills: newSkills);
      _persistSession(updated);
      state = AuthState(
        isAuthenticated: true,
        user: updated,
      );
      _firestoreService.updateUserProfile(state.user!.id, {'skills': newSkills});
    }
  }

  void updateEditorSchedule(int hours, List<String> days) {
    if (state.user != null) {
      final updated = state.user!.copyWith(hoursPerWeek: hours, activeDays: days);
      _persistSession(updated);
      state = AuthState(
        isAuthenticated: true,
        user: updated,
      );
      _firestoreService.updateUserProfile(state.user!.id, {'hoursPerWeek': hours, 'activeDays': days});
    }
  }

  Future<void> updateProfile({String? name, String? photoUrl}) async {
    if (state.user != null) {
      final updatedName = (name != null && name.trim().isNotEmpty) ? name.trim() : state.user!.name;
      final shouldClearPhoto = photoUrl != null && photoUrl.trim().isEmpty;
      final updatedPhoto = shouldClearPhoto
          ? null
          : (photoUrl != null && photoUrl.trim().isNotEmpty ? photoUrl.trim() : state.user!.photoUrl);

      final updated = state.user!.copyWith(
        name: updatedName,
        photoUrl: updatedPhoto,
        clearPhotoUrl: shouldClearPhoto,
      );

      await _persistSession(updated);
      state = AuthState(
        isAuthenticated: true,
        user: updated,
      );

      await _firestoreService.updateUserProfile(state.user!.id, {
        'name': updatedName,
        'photoUrl': updatedPhoto,
      });
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyUserSessionJson);
    state = const AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
