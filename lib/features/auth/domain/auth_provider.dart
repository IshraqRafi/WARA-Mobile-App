import 'package:firebase_auth/firebase_auth.dart';
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

class AuthState {
  final bool isAuthenticated;
  final UserSession? user;

  const AuthState({
    required this.isAuthenticated,
    this.user,
  });
}

class AuthNotifier extends StateNotifier<AuthState> {
  static const _keyIsLoggedIn = 'wara_auth_is_logged_in';
  static const _keyUserRole = 'wara_auth_user_role';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '3110629658-0kl05tqd8l7fbqu21nqoifd1i9c9r3dr.apps.googleusercontent.com',
  );
  final FirestoreService _firestoreService = FirestoreService();

  AuthNotifier() : super(const AuthState(isAuthenticated: false)) {
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    // Default to unauthenticated so the app always starts on the Login Page
    state = const AuthState(isAuthenticated: false);
  }

  UserSession _buildSessionForRole(
    UserRole role, {
    String? email,
    String? name,
    String? uid,
    String? photoUrl,
    String? specialization,
    String? portfolioLink,
    String? agencyName,
    String? agencyId,
    String? agencyJoinKey,
    List<String>? skills,
    int? hoursPerWeek,
    List<String>? activeDays,
    bool isProfileComplete = true,
  }) {
    final cleanEmail = email?.trim().toLowerCase() ?? '';
    final defaultManagerName = (cleanEmail == 'abdullahishraqrafi@gmail.com') ? 'Ishraq Rafi' : 'Agency Director';

    if (role == UserRole.manager) {
      return UserSession(
        id: uid ?? 'manager_1',
        email: email ?? 'manager@gmail.com',
        name: name?.isNotEmpty == true ? name! : defaultManagerName,
        role: UserRole.manager,
        agencyName: agencyName?.isNotEmpty == true ? agencyName! : 'Wara Media Group',
        agencyId: agencyId ?? 'agency_demo_wara',
        agencyJoinKey: agencyJoinKey ?? 'WARA-7742',
        skills: skills ?? ['Agency Management', 'Creative Direction', 'Client Relations'],
        hoursPerWeek: hoursPerWeek ?? 40,
        activeDays: activeDays ?? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        photoUrl: photoUrl,
        isProfileComplete: true,
      );
    } else {
      return UserSession(
        id: uid ?? 'editor_1',
        email: email ?? 'editor@gmail.com',
        name: name?.isNotEmpty == true ? name! : 'Editor',
        role: UserRole.editor,
        agencyName: agencyName?.isNotEmpty == true ? agencyName! : 'Wara Media Group',
        agencyId: agencyId ?? 'agency_demo_wara',
        agencyJoinKey: agencyJoinKey ?? 'WARA-7742',
        skills: skills ?? ['Video Editing', 'Color Grading', 'Sound Design', 'Thumbnail Design'],
        hoursPerWeek: hoursPerWeek ?? 35,
        activeDays: activeDays ?? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
        photoUrl: photoUrl,
        specialization: specialization,
        portfolioLink: portfolioLink,
        isProfileComplete: isProfileComplete,
      );
    }
  }

  /// Email / Password login
  Future<({bool success, String? error})> login(
    String email,
    String password, {
    UserRole selectedRole = UserRole.manager,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return (success: false, error: 'Please enter both email and password.');
    }

    // 1. Check Demo Accounts First for instant testing convenience
    if (cleanEmail == 'manager@gmail.com' && cleanPassword == 'manager') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserRole, 'manager');
      state = AuthState(
        isAuthenticated: true,
        user: _buildSessionForRole(
          UserRole.manager,
          agencyName: 'Wara Media Group',
          agencyId: 'agency_demo_wara',
          agencyJoinKey: 'WARA-7742',
          isProfileComplete: true,
        ),
      );
      return (success: true, error: null);
    } else if (cleanEmail == 'editor@gmail.com' && cleanPassword == 'editor') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserRole, 'editor');
      state = AuthState(
        isAuthenticated: true,
        user: _buildSessionForRole(
          UserRole.editor,
          agencyName: 'Wara Media Group',
          agencyId: 'agency_demo_wara',
          agencyJoinKey: 'WARA-7742',
          isProfileComplete: true,
        ),
      );
      return (success: true, error: null);
    }

    // 2. Real Cloud Firebase Auth
    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final fbUser = userCred.user;
      if (fbUser != null) {
        final profile = await _firestoreService.getUserProfile(fbUser.uid);
        final UserRole userRole = profile?['role'] != null
            ? (profile!['role'] == 'manager' ? UserRole.manager : UserRole.editor)
            : selectedRole;

        String userName = fbUser.displayName ?? cleanEmail.split('@').first;
        bool profileComplete = userRole == UserRole.manager;
        String? spec;
        String? port;
        String? photo = fbUser.photoURL;
        String? agencyId;
        String? agencyName;
        String? agencyJoinKey;
        List<String>? userSkills;
        int? userHours;
        List<String>? userDays;

        if (profile != null) {
          userName = profile['name'] as String? ?? userName;
          photo = (profile['photoUrl'] as String?) ?? photo;
          profileComplete = profile['isProfileComplete'] == true || userRole == UserRole.manager;
          spec = profile['specialization'] as String?;
          port = profile['portfolioLink'] as String?;
          agencyId = profile['agencyId'] as String?;
          agencyName = profile['agencyName'] as String?;
          agencyJoinKey = profile['agencyJoinKey'] as String?;
          if (profile['skills'] != null) {
            userSkills = List<String>.from(profile['skills']);
          }
          if (profile['hoursPerWeek'] != null) {
            userHours = (profile['hoursPerWeek'] as num).toInt();
          }
          if (profile['activeDays'] != null) {
            userDays = List<String>.from(profile['activeDays']);
          }
        }

        // If manager has an agency, ensure joinKey is synced
        if (userRole == UserRole.manager) {
          if (agencyId != null && agencyJoinKey == null) {
            final ag = await _firestoreService.getAgencyById(agencyId);
            if (ag != null) {
              agencyJoinKey = ag.joinKey;
              agencyName = ag.name;
            }
          } else if (agencyId == null) {
            // Auto-create agency workspace for manager if not existing
            final newAgency = await _firestoreService.createAgency(
              name: "$userName's Studio",
              managerUid: fbUser.uid,
              managerName: userName,
            );
            agencyId = newAgency.id;
            agencyName = newAgency.name;
            agencyJoinKey = newAgency.joinKey;
            await _firestoreService.updateUserProfile(fbUser.uid, {
              'agencyId': agencyId,
              'agencyName': agencyName,
              'agencyJoinKey': agencyJoinKey,
            });
          }
        }

        final session = _buildSessionForRole(
          userRole,
          email: cleanEmail,
          name: userName,
          uid: fbUser.uid,
          photoUrl: photo,
          specialization: spec,
          portfolioLink: port,
          agencyId: agencyId,
          agencyName: agencyName,
          agencyJoinKey: agencyJoinKey,
          skills: userSkills,
          hoursPerWeek: userHours,
          activeDays: userDays,
          isProfileComplete: profileComplete,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserRole, userRole == UserRole.editor ? 'editor' : 'manager');

        state = AuthState(isAuthenticated: true, user: session);
        return (success: true, error: null);
      }
      return (success: false, error: 'Unable to retrieve user credentials.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        return (
          success: false,
          error: 'Account not found. Please click "Create Account" to register.',
        );
      }
      return (success: false, error: e.message ?? 'Authentication failed.');
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  /// New Manager Registration + Creates Agency Workspace
  Future<({bool success, String? error})> registerManager({
    required String email,
    required String password,
    required String name,
    required String agencyName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();
    final cleanName = name.trim();
    final cleanAgency = agencyName.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty || cleanName.isEmpty || cleanAgency.isEmpty) {
      return (success: false, error: 'Please fill in all fields (Name, Agency Name, Email, Password).');
    }
    if (cleanPassword.length < 6) {
      return (success: false, error: 'Password must be at least 6 characters.');
    }

    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final fbUser = userCred.user;
      if (fbUser != null) {
        await fbUser.updateDisplayName(cleanName);

        // 1. Create the new Agency in Firestore
        final agency = await _firestoreService.createAgency(
          name: cleanAgency,
          managerUid: fbUser.uid,
          managerName: cleanName,
        );

        // 2. Save Manager user profile in Firestore
        await _firestoreService.saveUserProfile(
          uid: fbUser.uid,
          email: cleanEmail,
          name: cleanName,
          role: UserRole.manager,
          skills: ['Agency Management', 'Creative Direction', 'Client Relations'],
          hoursPerWeek: 40,
          activeDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
          isProfileComplete: true,
          agencyId: agency.id,
          agencyName: agency.name,
          agencyJoinKey: agency.joinKey,
        );

        final session = _buildSessionForRole(
          UserRole.manager,
          email: cleanEmail,
          name: cleanName,
          uid: fbUser.uid,
          agencyId: agency.id,
          agencyName: agency.name,
          agencyJoinKey: agency.joinKey,
          isProfileComplete: true,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserRole, 'manager');

        state = AuthState(isAuthenticated: true, user: session);
        return (success: true, error: null);
      }
      return (success: false, error: 'Registration failed.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return (success: false, error: 'This email is already registered. Please click "Sign In".');
      }
      return (success: false, error: e.message ?? 'Registration failed.');
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  /// New Editor Email/Password Registration
  Future<({bool success, String? error})> registerEditor(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return (success: false, error: 'Please enter both email and password.');
    }
    if (cleanPassword.length < 6) {
      return (success: false, error: 'Password must be at least 6 characters.');
    }

    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final fbUser = userCred.user;
      if (fbUser != null) {
        // Create initial Firestore doc with isProfileComplete = false
        await _firestoreService.saveUserProfile(
          uid: fbUser.uid,
          email: cleanEmail,
          name: '',
          role: UserRole.editor,
          skills: [],
          hoursPerWeek: 35,
          activeDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
          isProfileComplete: false,
        );

        final session = _buildSessionForRole(
          UserRole.editor,
          email: cleanEmail,
          name: '',
          uid: fbUser.uid,
          isProfileComplete: false, // Triggers Profile Setup!
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserRole, 'editor');

        state = AuthState(isAuthenticated: true, user: session);
        return (success: true, error: null);
      }
      return (success: false, error: 'Registration failed.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return (success: false, error: 'This email is already registered. Please click "Sign In".');
      }
      return (success: false, error: e.message ?? 'Registration failed.');
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  /// Google Sign-In Authentication: supports both Manager & Editor
  Future<({bool success, String? error})> signInWithGoogle(UserRole selectedRole) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return (success: false, error: 'Google sign-in was cancelled.');
      }

      final cleanEmail = googleUser.email.trim().toLowerCase();
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCred = await _auth.signInWithCredential(credential);
      final User? fbUser = userCred.user;

      if (fbUser != null) {
        final profile = await _firestoreService.getUserProfile(fbUser.uid);
        final UserRole userRole = profile?['role'] != null
            ? (profile!['role'] == 'manager' ? UserRole.manager : UserRole.editor)
            : selectedRole;

        bool profileComplete = userRole == UserRole.manager;
        String userName = fbUser.displayName ?? '';
        String? spec;
        String? port;
        String? photo = fbUser.photoURL;
        String? agencyId;
        String? agencyName;
        String? agencyJoinKey;
        List<String>? userSkills;
        int? userHours;
        List<String>? userDays;

        if (profile != null) {
          userName = profile['name'] as String? ?? userName;
          photo = (profile['photoUrl'] as String?) ?? photo;
          profileComplete = profile['isProfileComplete'] == true || userRole == UserRole.manager;
          spec = profile['specialization'] as String?;
          port = profile['portfolioLink'] as String?;
          agencyId = profile['agencyId'] as String?;
          agencyName = profile['agencyName'] as String?;
          agencyJoinKey = profile['agencyJoinKey'] as String?;
          if (profile['skills'] != null) {
            userSkills = List<String>.from(profile['skills']);
          }
          if (profile['hoursPerWeek'] != null) {
            userHours = (profile['hoursPerWeek'] as num).toInt();
          }
          if (profile['activeDays'] != null) {
            userDays = List<String>.from(profile['activeDays']);
          }
        } else {
          // Brand new user from Google
          if (userRole == UserRole.manager) {
            final newAgency = await _firestoreService.createAgency(
              name: "$userName's Studio",
              managerUid: fbUser.uid,
              managerName: userName,
            );
            agencyId = newAgency.id;
            agencyName = newAgency.name;
            agencyJoinKey = newAgency.joinKey;
          }

          await _firestoreService.saveUserProfile(
            uid: fbUser.uid,
            email: cleanEmail,
            name: userName,
            role: userRole,
            skills: userRole == UserRole.manager
                ? ['Agency Management', 'Creative Direction', 'Client Relations']
                : [],
            hoursPerWeek: 35,
            activeDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
            isProfileComplete: profileComplete,
            agencyId: agencyId,
            agencyName: agencyName,
            agencyJoinKey: agencyJoinKey,
          );
        }

        final session = _buildSessionForRole(
          userRole,
          email: cleanEmail,
          name: userName,
          uid: fbUser.uid,
          photoUrl: photo,
          specialization: spec,
          portfolioLink: port,
          agencyId: agencyId,
          agencyName: agencyName,
          agencyJoinKey: agencyJoinKey,
          skills: userSkills,
          hoursPerWeek: userHours,
          activeDays: userDays,
          isProfileComplete: profileComplete,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserRole, userRole == UserRole.editor ? 'editor' : 'manager');

        state = AuthState(isAuthenticated: true, user: session);
        return (success: true, error: null);
      }
      return (success: false, error: 'Google authentication failed.');
    } catch (e) {
      return (success: false, error: e.toString());
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

      state = AuthState(
        isAuthenticated: true,
        user: current.copyWith(
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
        ),
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
      );
      state = AuthState(
        isAuthenticated: true,
        user: user.copyWith(agencyJoinKey: newKey),
      );
      await _firestoreService.updateUserProfile(user.id, {'agencyJoinKey': newKey});
      return newKey;
    } catch (_) {
      return null;
    }
  }

  void updateEditorSkills(List<String> newSkills) {
    if (state.user != null) {
      state = AuthState(
        isAuthenticated: true,
        user: state.user!.copyWith(skills: newSkills),
      );
      _firestoreService.updateUserProfile(state.user!.id, {'skills': newSkills});
    }
  }

  void updateEditorSchedule(int hours, List<String> days) {
    if (state.user != null) {
      state = AuthState(
        isAuthenticated: true,
        user: state.user!.copyWith(hoursPerWeek: hours, activeDays: days),
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

      state = AuthState(
        isAuthenticated: true,
        user: state.user!.copyWith(
          name: updatedName,
          photoUrl: updatedPhoto,
          clearPhotoUrl: shouldClearPhoto,
        ),
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
    await prefs.setBool(_keyIsLoggedIn, false);
    state = const AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
