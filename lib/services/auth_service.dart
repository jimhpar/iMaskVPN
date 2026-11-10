import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/plan_request_model.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  GoogleSignIn? _googleSignIn;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  UserModel? _userProfile;
  UserModel? get userProfile => _userProfile;

  StreamSubscription<DocumentSnapshot>? _profileSubscription;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AuthService() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _subscribeToProfile(user.uid);
      } else {
        _profileSubscription?.cancel();
        _userProfile = null;
        notifyListeners();
      }
    });
  }

  void _subscribeToProfile(String uid) {
    _profileSubscription?.cancel();
    _profileSubscription = _firestore.collection('users').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        _userProfile = UserModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
      } else {
        // Fallback default profile if document doesn't exist yet
        final current = _auth.currentUser;
        final email = current?.email ?? '';
        final isSuper = email.toLowerCase() == 'su@imask.com';
        final role = isSuper
            ? 'superadmin'
            : ((email.toLowerCase().contains('admin') || email.toLowerCase() == 'jimhpar@gmail.com')
                ? 'admin'
                : 'user');
        final plan = isSuper ? 'ultra' : 'free';

        _userProfile = UserModel(
          uid: uid,
          email: email,
          displayName: isSuper ? 'Super Admin' : (current?.displayName ?? 'iMask Member'),
          plan: plan,
          role: role,
        );
        _firestore.collection('users').doc(uid).set(_userProfile!.toMap(), SetOptions(merge: true));
      }
      notifyListeners();
    }, onError: (e) {
      debugPrint('Profile stream error: $e');
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Sign in with Email & Password (with special auto-provision for su@imask.com)
  Future<bool> signInWithEmail(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPass = password.trim();

    try {
      _setLoading(true);
      _errorMessage = null;

      // Special provision for su@imask.com
      if (cleanEmail.toLowerCase() == 'su@imask.com' && cleanPass == 'admin#3663') {
        try {
          UserCredential credential = await _auth.signInWithEmailAndPassword(
            email: cleanEmail,
            password: cleanPass,
          );
          if (credential.user != null) {
            await _ensureSuperAdminData(credential.user!);
          }
          _setLoading(false);
          return true;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
            // Auto-create superadmin account if not already in Firebase Auth
            UserCredential credential = await _auth.createUserWithEmailAndPassword(
              email: cleanEmail,
              password: cleanPass,
            );
            if (credential.user != null) {
              await credential.user!.updateDisplayName('Super Admin');
              await _ensureSuperAdminData(credential.user!);
            }
            _setLoading(false);
            return true;
          } else {
            rethrow;
          }
        }
      }

      // Normal sign-in
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPass,
      );
      if (credential.user != null) {
        await _updateUserData(credential.user!);
      }
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseAuthError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<void> _ensureSuperAdminData(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': 'su@imask.com',
        'displayName': 'Super Admin',
        'plan': 'ultra',
        'role': 'superadmin',
        'weeklyMinutesUsed': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Superadmin setup error: $e');
    }
  }

  // Sign up with Email & Password
  Future<bool> signUpWithEmail(String email, String password, String name) async {
    try {
      _setLoading(true);
      _errorMessage = null;
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name.trim());
        await _createInitialUserData(credential.user!, name.trim());
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseAuthError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
      _setLoading(false);
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        if (userCredential.user != null) {
          await _updateUserData(userCredential.user!);
        }
        _setLoading(false);
        return true;
      } else {
        _googleSignIn ??= GoogleSignIn();
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) {
          _setLoading(false);
          return false;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(credential);
        if (userCredential.user != null) {
          await _updateUserData(userCredential.user!);
        }

        _setLoading(false);
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseAuthError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Google sign-in error: $e';
      _setLoading(false);
      return false;
    }
  }

  // Update Display Name
  Future<bool> updateDisplayName(String newName) async {
    try {
      if (currentUser == null) return false;
      await currentUser!.updateDisplayName(newName.trim());
      await _firestore.collection('users').doc(currentUser!.uid).set({
        'displayName': newName.trim(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Update name error: $e');
      return false;
    }
  }

  // Change Password
  Future<bool> changePassword(String newPassword) async {
    try {
      if (currentUser == null) return false;
      await currentUser!.updatePassword(newPassword.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseAuthError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update password: $e';
      notifyListeners();
      return false;
    }
  }

  // Send Password Reset Email
  Future<bool> sendPasswordResetEmail([String? email]) async {
    try {
      final targetEmail = email ?? currentUser?.email;
      if (targetEmail == null || targetEmail.isEmpty) return false;
      await _auth.sendPasswordResetEmail(email: targetEmail.trim());
      return true;
    } catch (e) {
      _errorMessage = 'Could not send reset email: $e';
      notifyListeners();
      return false;
    }
  }

  // Directly Apply Plan (Only for Admin / Superadmin or Free)
  Future<bool> applyPlan(String newPlan) async {
    try {
      if (currentUser == null) return false;
      await _firestore.collection('users').doc(currentUser!.uid).set({
        'plan': newPlan.toLowerCase(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Error updating plan: $e');
      return false;
    }
  }

  // Submit Plan Request (For regular users applying for Pro / Ultra)
  Future<bool> submitPlanRequest(String requestedPlan) async {
    try {
      if (currentUser == null) return false;
      final profile = _userProfile;
      final price = requestedPlan.toLowerCase() == 'ultra' ? 499 : 99;

      final docRef = _firestore.collection('plan_requests').doc();
      final request = PlanRequestModel(
        id: docRef.id,
        uid: currentUser!.uid,
        userName: profile?.displayName ?? currentUser!.displayName ?? 'iMask Member',
        userEmail: currentUser!.email ?? '',
        currentPlan: profile?.plan ?? 'free',
        requestedPlan: requestedPlan.toLowerCase(),
        priceBDT: price,
        status: 'pending',
        requestedAt: DateTime.now(),
      );

      await docRef.set(request.toMap());
      return true;
    } catch (e) {
      debugPrint('Error submitting plan request: $e');
      return false;
    }
  }

  // Stream Plan Requests (For Admin Review Requests)
  Stream<List<PlanRequestModel>> streamPlanRequests({bool pendingOnly = true}) {
    Query query = _firestore.collection('plan_requests').orderBy('requestedAt', descending: true);
    if (pendingOnly) {
      query = query.where('status', isEqualTo: 'pending');
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PlanRequestModel.fromFirestore(doc)).toList();
    });
  }

  // Stream Pending Requests Count
  Stream<int> streamPendingRequestsCount() {
    return _firestore
        .collection('plan_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Admin Approve Plan Request
  Future<bool> approvePlanRequest(PlanRequestModel request) async {
    try {
      // 1. Update request status to approved
      await _firestore.collection('plan_requests').doc(request.id).update({
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update user plan in Firestore
      await _firestore.collection('users').doc(request.uid).set({
        'plan': request.requestedPlan.toLowerCase(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('Error approving plan request: $e');
      return false;
    }
  }

  // Admin Reject Plan Request
  Future<bool> rejectPlanRequest(String requestId) async {
    try {
      await _firestore.collection('plan_requests').doc(requestId).update({
        'status': 'rejected',
        'processedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error rejecting plan request: $e');
      return false;
    }
  }

  // Record VPN Usage in Minutes
  Future<void> recordUsage(int minutes) async {
    try {
      if (currentUser == null || minutes <= 0) return;
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'weeklyMinutesUsed': FieldValue.increment(minutes),
      });
    } catch (e) {
      debugPrint('Error recording usage: $e');
    }
  }

  // --- ADMIN METHODS ---

  // Stream All Users from Firestore
  Stream<List<UserModel>> streamAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Admin: Update User Plan & Role
  Future<bool> adminUpdateUser({
    required String uid,
    required String plan,
    required String role,
    String? name,
  }) async {
    try {
      final data = <String, dynamic>{
        'plan': plan.toLowerCase(),
        'role': role.toLowerCase(),
      };
      if (name != null && name.isNotEmpty) {
        data['displayName'] = name.trim();
      }
      await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Admin update user error: $e');
      return false;
    }
  }

  // Admin: Add / Create New User Record in Firestore
  Future<bool> adminCreateUser({
    required String email,
    required String password,
    required String name,
    required String plan,
    required String role,
  }) async {
    try {
      _setLoading(true);
      final customUid = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await _firestore.collection('users').doc(customUid).set({
        'uid': customUid,
        'email': email.trim(),
        'displayName': name.trim(),
        'plan': plan.toLowerCase(),
        'role': role.toLowerCase(),
        'weeklyMinutesUsed': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'initialPassword': password.trim(),
      });
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Admin create user failed: $e';
      _setLoading(false);
      return false;
    }
  }

  // Admin: Delete User
  Future<bool> adminDeleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      return true;
    } catch (e) {
      debugPrint('Admin delete user error: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn?.signOut();
    } catch (_) {}
    _profileSubscription?.cancel();
    _userProfile = null;
    await _auth.signOut();
    notifyListeners();
  }

  Future<void> _createInitialUserData(User user, String displayName) async {
    try {
      final email = user.email ?? '';
      final isSuper = email.toLowerCase() == 'su@imask.com';
      final role = isSuper
          ? 'superadmin'
          : ((email.toLowerCase().contains('admin') || email.toLowerCase() == 'jimhpar@gmail.com')
              ? 'admin'
              : 'user');
      final plan = isSuper ? 'ultra' : 'free';

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'displayName': isSuper ? 'Super Admin' : displayName,
        'plan': plan,
        'role': role,
        'weeklyMinutesUsed': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore write error: $e');
    }
  }

  Future<void> _updateUserData(User user) async {
    try {
      final email = user.email ?? '';
      final docRef = _firestore.collection('users').doc(user.uid);
      final docSnap = await docRef.get();

      final isSuper = email.toLowerCase() == 'su@imask.com';
      final role = isSuper
          ? 'superadmin'
          : ((email.toLowerCase().contains('admin') || email.toLowerCase() == 'jimhpar@gmail.com')
              ? 'admin'
              : (docSnap.data()?['role'] ?? 'user'));
      final plan = isSuper ? 'ultra' : (docSnap.data()?['plan'] ?? 'free');

      await docRef.set({
        'lastLogin': FieldValue.serverTimestamp(),
        'email': email,
        if (!docSnap.exists) ...{
          'uid': user.uid,
          'displayName': isSuper ? 'Super Admin' : (user.displayName ?? 'iMask Member'),
          'plan': plan,
          'role': role,
          'weeklyMinutesUsed': 0,
          'createdAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore update error: $e');
    }
  }

  String _parseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password or email.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in.';
      case 'weak-password':
        return 'Password is too weak. Must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'popup-closed-by-user':
        return 'Google sign-in popup was closed.';
      default:
        return 'Authentication error: $code';
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}
