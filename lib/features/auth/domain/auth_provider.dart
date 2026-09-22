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
      agencyName: agencyName,
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

  /// Designated agency manager email list. Only these emails can hold Manager privileges.
  static const List<String> kAuthorizedManagerEmails = [
    'abdullahishraqrafi@gmail.com',
    'manager@gmail.com',
  ];

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

  bool isManagerEmail(String email) {
    return kAuthorizedManagerEmails.contains(email.trim().toLowerCase());
  }

  UserSession _buildSessionForRole(
    UserRole role, {
    String? email,
    String? name,
    String? uid,
    String? photoUrl,
    String? specialization,
    String? portfolioLink,
    List<String>? skills,
    int? hoursPerWeek,
    List<String>? activeDays,
    bool isProfileComplete = true,
  }) {
    final cleanEmail = email?.trim().toLowerCase() ?? '';
    final defaultManagerName = (cleanEmail == 'abdullahishraqrafi@gmail.com') ? 'Ishraq Rafi' : 'Walid Islam';

    if (role == UserRole.manager) {
      return UserSession(
        id: uid ?? 'manager_1',
        email: email ?? 'manager@gmail.com',
        name: name ?? defaultManagerName,
        role: UserRole.manager,
        agencyName: 'Wara Media Group',
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
        name: name ?? 'Walid Islam',
        role: UserRole.editor,
        agencyName: 'Wara Media Group',
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

    // Role Enforcement check for Manager selection
    if (selectedRole == UserRole.manager && !isManagerEmail(cleanEmail)) {
      return (
        success: false,
        error: 'Access denied: This account does not have agency manager privileges. Please sign in under Editor Portal.',
      );
    }

    // 1. Check Demo Accounts First for instant pairing
    if (cleanEmail == 'manager@gmail.com' && cleanPassword == 'manager') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserRole, 'manager');
      state = AuthState(isAuthenticated: true, user: _buildSessionForRole(UserRole.manager, isProfileComplete: true));
      return (success: true, error: null);
    } else if (cleanEmail == 'editor@gmail.com' && cleanPassword == 'editor') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserRole, 'editor');
      state = AuthState(isAuthenticated: true, user: _buildSessionForRole(UserRole.editor, isProfileComplete: true));
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
        final UserRole userRole = isManagerEmail(cleanEmail) ? UserRole.manager : UserRole.editor;
        final profile = await _firestoreService.getUserProfile(fbUser.uid);

        String userName = fbUser.displayName ?? cleanEmail.split('@').first;
        bool profileComplete = userRole == UserRole.manager; // Managers always complete
        String? spec;
        String? port;
        String? photo = fbUser.photoURL;
        List<String>? userSkills;
        int? userHours;
        List<String>? userDays;

        if (profile != null) {
          userName = profile['name'] as String? ?? userName;
          photo = (profile['photoUrl'] as String?) ?? photo;
          profileComplete = profile['isProfileComplete'] == true || userRole == UserRole.manager;
          spec = profile['specialization'] as String?;
          port = profile['portfolioLink'] as String?;
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

        final session = _buildSessionForRole(
          userRole,
          email: cleanEmail,
          name: (cleanEmail == 'abdullahishraqrafi@gmail.com') ? 'Ishraq Rafi' : userName,
          uid: fbUser.uid,
          photoUrl: photo,
          specialization: spec,
          portfolioLink: port,
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
        return (success: false, error: 'Account not found. Please click "Create Account" to sign up as an Editor.');
      }
      return (success: false, error: e.message ?? 'Authentication failed.');
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
        _firestoreService.saveUserProfile(
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

  /// Google Sign-In Authentication: auto-detects existing vs new editors
  Future<({bool success, String? error})> signInWithGoogle(UserRole selectedRole) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return (success: false, error: 'Google sign-in was cancelled.');
      }

      final cleanEmail = googleUser.email.trim().toLowerCase();

      // Check if user selected Manager Access tab but their Google email is NOT an authorized manager
      if (selectedRole == UserRole.manager && !isManagerEmail(cleanEmail)) {
        await _googleSignIn.signOut();
        return (
          success: false,
          error: 'Access denied: This account does not have agency manager privileges. Please select Editor Portal to sign in.',
        );
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCred = await _auth.signInWithCredential(credential);
      final User? fbUser = userCred.user;

      if (fbUser != null) {
        final UserRole userRole = isManagerEmail(cleanEmail) ? UserRole.manager : UserRole.editor;

        // Check if user profile already exists in Firestore
        final profile = await _firestoreService.getUserProfile(fbUser.uid);
        bool profileComplete = userRole == UserRole.manager; // Managers always complete
        String userName = fbUser.displayName ?? '';
        String? spec;
        String? port;
        String? photo = fbUser.photoURL;
        List<String>? userSkills;
        int? userHours;
        List<String>? userDays;

        if (profile != null) {
          // Account already exists!
          userName = profile['name'] as String? ?? userName;
          photo = (profile['photoUrl'] as String?) ?? photo;
          profileComplete = profile['isProfileComplete'] == true || userRole == UserRole.manager;
          spec = profile['specialization'] as String?;
          port = profile['portfolioLink'] as String?;
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
          // New Account: If Manager -> complete, if Editor -> requires Profile Setup!
          _firestoreService.saveUserProfile(
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
          );
        }

        final session = _buildSessionForRole(
          userRole,
          email: cleanEmail,
          name: (cleanEmail == 'abdullahishraqrafi@gmail.com') ? 'Ishraq Rafi' : userName,
          uid: fbUser.uid,
          photoUrl: photo,
          specialization: spec,
          portfolioLink: port,
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

  /// Complete Editor Profile Setup
  Future<void> completeProfile({
    required String name,
    required String specialization,
    required List<String> skills,
    required int hoursPerWeek,
    required List<String> activeDays,
    required String portfolioLink,
    String? photoUrl,
  }) async {
    if (state.user != null) {
      final photo = photoUrl ?? state.user!.photoUrl;
      await _firestoreService.completeEditorProfile(
        uid: state.user!.id,
        name: name,
        specialization: specialization,
        skills: skills,
        hoursPerWeek: hoursPerWeek,
        activeDays: activeDays,
        portfolioLink: portfolioLink,
        photoUrl: photo,
      );

      state = AuthState(
        isAuthenticated: true,
        user: state.user!.copyWith(
          name: name,
          specialization: specialization,
          skills: skills,
          hoursPerWeek: hoursPerWeek,
          activeDays: activeDays,
          portfolioLink: portfolioLink,
          photoUrl: photo,
          isProfileComplete: true,
        ),
      );
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
