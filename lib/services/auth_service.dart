import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/app_models.dart';
import '../services/app_repository.dart';
import 'api_client.dart';
import 'firebase_stats.dart';

/// Auth service handling Firebase Google Sign-In and user session.
/// Extends ChangeNotifier so wallet/balance UI updates instantly (no restart).
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  firebase_auth.User? _currentUser;
  UserModel? _userModel;

  firebase_auth.User? get firebaseUser => _currentUser;
  UserModel? get userModel => _userModel;
  bool get isLoggedIn => _currentUser != null && _userModel != null;

  /// Initialize Firebase and check for existing session
  Future<void> initialize() async {
    // Firebase already initialized in main.dart - do not re-init
    try {
      // Restore backend JWT (Render API) from previous login
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('backend_token');
      if (savedToken != null && savedToken.isNotEmpty) {
        ApiClient.instance.token = savedToken;
      }
      // Check for existing auth state
      _auth.authStateChanges().listen(_onAuthStateChanged);

      // Try to restore user from local storage if already signed in
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _loadUserModel(currentUser);
      }
    } catch (e) {
      debugPrint('AuthService initialize error: $e');
    }
  }

  void _onAuthStateChanged(firebase_auth.User? user) {
    _currentUser = user;
    if (user != null) {
      _loadUserModel(user);
    } else {
      _userModel = null;
      notifyListeners();
    }
  }

  Future<void> _loadUserModel(firebase_auth.User firebaseUser) async {
    // Try to load from local cache first
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('user_${firebaseUser.uid}');
    if (cached != null) {
      try {
        final data = json.decode(cached);
        _userModel = UserModel.fromFirebase(data, firebaseUser.uid);
        notifyListeners();
        return;
      } catch (_) {}
    }
    
    // Fetch from backend
    try {
      final repo = AppRepository.instance;
      final userData = await repo.fetchUserProfile(firebaseUser.uid);
      if (userData != null) {
        _userModel = UserModel.fromFirebase(userData, firebaseUser.uid);
        await _cacheUserModel();
        return;
      }
    } catch (_) {
      // fall through to local profile below
    }
    // Backend unavailable or unknown user: build from Firebase profile
    // (never leave _userModel null for a signed-in user)
    _userModel = UserModel(
      uid: firebaseUser.uid,
      displayName: firebaseUser.displayName ?? 'User',
      email: firebaseUser.email,
      photoUrl: firebaseUser.photoURL,
    );
    await _cacheUserModel();
    notifyListeners();
    // Mirror to Firebase RTDB (fast counter, fire-and-forget)
    FirebaseStats.syncUser(_userModel!);
    // Login to backend (Render API) to get JWT for spin/withdraw calls.
    // Never blocks the app - local session works even if backend is down.
    _loginToBackend(firebaseUser);
  }

  /// Exchange Firebase idToken for backend JWT (fire-and-forget).
  Future<void> _loginToBackend(firebase_auth.User firebaseUser) async {
    try {
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) return;
      final res = await ApiClient.instance.post(
        '/api/auth/google',
        {'idToken': idToken},
        auth: false,
      );
      if (res is Map && res['success'] == true && res['data'] is Map) {
        final data = res['data'] as Map;
        final access = data['accessToken'] ?? data['access_token'] ?? data['token'];
        final refresh = data['refreshToken'] ?? data['refresh_token'];
        if (access is String && access.isNotEmpty) {
          ApiClient.instance.token = access;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('backend_token', access);
          if (refresh is String && refresh.isNotEmpty) {
            await prefs.setString('backend_refresh_token', refresh);
          }
          debugPrint('Backend login ok');
        }
      }
    } catch (e) {
      debugPrint('Backend login skipped: $e');
    }
  }

  Future<void> _cacheUserModel() async {
    if (_userModel == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'user_${_userModel!.uid}',
      json.encode(_userModel!.toFirestore()),
    );
  }

  /// Sign in with Google - PRODUCTION (no demo fallback)
  Future<UserModel?> signInWithGoogle() async {
    // 1. Native Google account picker (reliable on Android)
    try {
      final googleUser = await GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: '839337325039-8mao9qj110cfsvol4qcn7dsogickv9hg.apps.googleusercontent.com',
      ).signIn();
      if (googleUser == null) {
        debugPrint('GoogleSignIn: user dismissed account picker');
        return null; // real cancel - let UI show it
      }
      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential);
      if (userCred.user != null) {
        await _loadUserModel(userCred.user!);
        return _userModel;
      }
      return null;
    } on firebase_auth.FirebaseAuthException {
      rethrow; // production: surface real error, no demo mask
    } catch (e) {
      debugPrint('Native Google Sign-In error: $e');
      // fall through to browser flow
    }

    // 2. Browser fallback (signInWithProvider)
    final googleProvider = firebase_auth.GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');
    final credential = await _auth.signInWithProvider(googleProvider);
    if (credential.user != null) {
      await _loadUserModel(credential.user!);
      return _userModel;
    }
    return null;
  }

  Future<UserModel> _createDemoUser() async {
    // DISABLED for production - throw instead of masking errors
    throw StateError('Demo mode removed for production');
  }

  /// Ensure locally persisted Firebase user has a loaded UserModel.
  /// Returns null if no Firebase session exists.
  Future<UserModel?> ensureUserLoaded() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;
      _currentUser = currentUser;
      if (_userModel == null) {
        await _loadUserModel(currentUser);
      }
      notifyListeners();
      return _userModel;
    } catch (e) {
      debugPrint('ensureUserLoaded error: $e');
      notifyListeners();
      return _userModel;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    _userModel = null;
    notifyListeners();
    ApiClient.instance.token = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('backend_token');
      await prefs.remove('backend_refresh_token');
    } catch (_) {}
  }

  /// Update user coins (local + backend sync + Firebase RTDB mirror)
  Future<void> addCoins(int amount) async {
    if (_userModel == null) return;
    _userModel = _userModel!.copyWith(coins: _userModel!.coins + amount);
    await _cacheUserModel();
    notifyListeners(); // wallet updates instantly, no restart
    FirebaseStats.addCoinsDelta(_userModel!.uid, amount);
    await _syncToBackend();
  }

  Future<void> deductCoins(int amount) async {
    if (_userModel == null) return;
    _userModel = _userModel!.copyWith(coins: (_userModel!.coins - amount).clamp(0, 999999));
    await _cacheUserModel();
    notifyListeners(); // wallet updates instantly, no restart
    FirebaseStats.addCoinsDelta(_userModel!.uid, -amount);
    await _syncToBackend();
  }

  /// Record spin usage
  Future<void> recordSpin() async {
    if (_userModel == null) return;
    final now = DateTime.now();
    _userModel = _userModel!.copyWith(
      dailySpinsUsed: _userModel!.dailySpinsUsed + 1,
      lastSpinDate: now,
    );
    await _cacheUserModel();
    notifyListeners();
    FirebaseStats.recordSpin(_userModel!.uid);
    await _syncToBackend();
  }

  /// Update withdraw info
  Future<void> updateWithdrawInfo({String? upiId, String? bankDetails}) async {
    if (_userModel == null) return;
    _userModel = _userModel!.copyWith(upiId: upiId, bankDetails: bankDetails);
    await _cacheUserModel();
    notifyListeners();
    await _syncToBackend();
  }

  Future<void> _syncToBackend() async {
    if (_userModel == null) return;
    try {
      final repo = AppRepository.instance;
      await repo.updateUserProfile(_userModel!.uid, _userModel!.toFirestore());
    } catch (_) {
      // Silently fail - local cache is source of truth
    }
  }

  /// Get user's remaining spins for today
  int getRemainingSpins() {
    return _userModel?.remainingSpins() ?? 2;
  }

  bool canSpin() {
    return _userModel?.canSpin() ?? true;
  }
}