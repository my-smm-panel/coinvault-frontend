import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

import '../models/app_models.dart';
import '../services/app_repository.dart';
import 'api_client.dart';
import 'balance_stream.dart';

/// Auth service handling Firebase Google Sign-In and user session.
/// Extends ChangeNotifier so wallet/balance UI updates instantly (no restart).
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  firebase_auth.User? _currentUser;
  UserModel? _userModel;
  bool _backendReady = false;
  bool _loadingBackendSession = false;
  String? _loadingUid;
  int _sessionGeneration = 0;

  firebase_auth.User? get firebaseUser => _currentUser;
  UserModel? get userModel => _userModel;
  bool get isLoggedIn => _currentUser != null && _userModel != null;
  bool get backendReady => _backendReady && ApiClient.instance.token != null;

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
    final previousUid = _currentUser?.uid;
    _currentUser = user;
    if (user != null) {
      if (previousUid != user.uid) {
        _sessionGeneration++;
        _backendReady = false;
        _loadingBackendSession = false;
        _loadingUid = null;
        _userModel = null;
        ApiClient.instance.token = null;
        BalanceStream.instance.clear();
      }
      unawaited(_loadUserModel(user));
    } else {
      _sessionGeneration++;
      _backendReady = false;
      _loadingBackendSession = false;
      _loadingUid = null;
      _userModel = null;
      ApiClient.instance.token = null;
      BalanceStream.instance.clear();
      notifyListeners();
    }
  }

  Future<void> _loadUserModel(firebase_auth.User firebaseUser) async {
    if (_loadingBackendSession && _loadingUid == firebaseUser.uid) return;
    _loadingBackendSession = true;
    _loadingUid = firebaseUser.uid;
    final generation = ++_sessionGeneration;
    final previousUid = _currentUser?.uid;
    _currentUser = firebaseUser;
    _backendReady = false;
    if (previousUid != firebaseUser.uid) BalanceStream.instance.clear();

    try {
      // Cached fields are only for non-financial profile text. The wallet
      // balance and spin/reward state are never restored from device storage.
      final prefs = await SharedPreferences.getInstance();
      if (!_isCurrentSession(firebaseUser, generation)) return;
      final cached = prefs.getString('user_${firebaseUser.uid}');
      if (cached != null) {
        try {
          final data = json.decode(cached);
          if (data is Map<String, dynamic>) {
            _userModel = UserModel.fromFirebase(data, firebaseUser.uid);
          }
        } catch (_) {}
      }
      _userModel ??= UserModel(
        uid: firebaseUser.uid,
        displayName: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email,
        photoUrl: firebaseUser.photoURL,
      );
      final cachedModel = _userModel;
      await _cacheUserModel(cachedModel);
      if (!_isCurrentSession(firebaseUser, generation)) return;
      notifyListeners();

      // Exchange the Firebase identity token first. Protected profile/wallet
      // reads must never race ahead of backend authentication.
      final authenticated = await _loginToBackend(firebaseUser, generation);
      if (!_isCurrentSession(firebaseUser, generation)) return;
      if (!authenticated) return;

      // A valid backend JWT makes the session ready. Wallet data is fetched
      // separately; a wallet endpoint failure must not strand the user at login.
      _backendReady = true;
      notifyListeners();
      await _refreshProfileFromBackend(firebaseUser, generation);
      if (!_isCurrentSession(firebaseUser, generation)) return;
      await AppRepository.instance.fetchWalletBalance();
      if (!_isCurrentSession(firebaseUser, generation)) return;
    } catch (e) {
      debugPrint('Backend session initialization failed: $e');
      _backendReady = false;
      notifyListeners();
    } finally {
      if (generation == _sessionGeneration) {
        _loadingBackendSession = false;
        _loadingUid = null;
      }
    }
  }

  bool _isCurrentSession(firebase_auth.User firebaseUser, int generation) =>
      generation == _sessionGeneration &&
      _currentUser?.uid == firebaseUser.uid;

  /// Fetch backend profile and merge (keeps Firebase name/photo).
  Future<void> _refreshProfileFromBackend(
      firebase_auth.User firebaseUser, int generation) async {
    try {
      final repo = AppRepository.instance;
      final userData = await repo.fetchUserProfile(firebaseUser.uid);
      if (userData == null || !_isCurrentSession(firebaseUser, generation)) return;
      final norm = Map<String, dynamic>.from(userData);
      norm['displayName'] ??= norm['name'];
      norm['photoUrl'] ??= norm['avatar'];
      final fresh = UserModel.fromFirebase(norm, firebaseUser.uid);
      final merged = fresh.copyWith(
        displayName: firebaseUser.displayName?.isNotEmpty == true
            ? firebaseUser.displayName!
            : fresh.displayName,
        photoUrl: firebaseUser.photoURL ?? fresh.photoUrl,
        email: firebaseUser.email ?? fresh.email,
      );
      if (!_isCurrentSession(firebaseUser, generation)) return;
      _userModel = merged;
      await _cacheUserModel(merged);
      if (!_isCurrentSession(firebaseUser, generation)) return;
      notifyListeners();
    } catch (_) {
      // Offline: cached/Firebase profile stays.
    }
  }

  /// Exchange Firebase idToken for backend JWT without allowing a late
  /// response from a previous account to replace the active session token.
  Future<bool> _loginToBackend(
    firebase_auth.User firebaseUser,
    int generation,
  ) async {
    try {
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null ||
          idToken.isEmpty ||
          !_isCurrentSession(firebaseUser, generation)) {
        return false;
      }
      final res = await ApiClient.instance.post(
        '/api/auth/google',
        {'idToken': idToken},
        auth: false,
      );
      if (!_isCurrentSession(firebaseUser, generation)) return false;
      if (res is Map && res['success'] == true && res['data'] is Map) {
        final data = res['data'] as Map;
        final access = data['accessToken'] ?? data['access_token'] ?? data['token'];
        final refresh = data['refreshToken'] ?? data['refresh_token'];
        if (access is String && access.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          if (!_isCurrentSession(firebaseUser, generation)) return false;
          ApiClient.instance.token = access;
          await prefs.setString('backend_token', access);
          if (refresh is String && refresh.isNotEmpty) {
            await prefs.setString('backend_refresh_token', refresh);
          }
          if (!_isCurrentSession(firebaseUser, generation)) {
            if (ApiClient.instance.token == access) {
              ApiClient.instance.token = null;
            }
            if (prefs.getString('backend_token') == access) {
              await prefs.remove('backend_token');
            }
            if (refresh is String &&
                prefs.getString('backend_refresh_token') == refresh) {
              await prefs.remove('backend_refresh_token');
            }
            return false;
          }
          debugPrint('Backend login ok');
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Backend login failed: $e');
      return false;
    }
  }

  Future<void> _cacheUserModel([UserModel? model]) async {
    final snapshot = model ?? _userModel;
    if (snapshot == null) return;
    final key = 'user_${snapshot.uid}';
    final encoded = json.encode(snapshot.toFirestore());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, encoded);
  }

  /// Sign in with Google - PRODUCTION (no demo fallback)
  Future<UserModel?> signInWithGoogle() async {
    // Native Google account picker (reliable on Android). No browser
    // fallback — signInWithProvider hangs on Android and leaves the UI
    // stuck in a loading state.
    try {
      final googleUser = await GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: '839337325039-8mao9qj110cfsvol4qcn7dsogickv9hg.apps.googleusercontent.com',
      ).signIn().timeout(
        const Duration(seconds: 90),
        onTimeout: () => null, // picker never returned — treat as cancel
      );
      if (googleUser == null) {
        debugPrint('GoogleSignIn: user dismissed account picker');
        return null; // real cancel - let UI show it
      }
      final googleAuth = await googleUser.authentication.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Google authentication timed out'),
      );
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Firebase sign-in timed out'),
      );
      // Credential is in: kick off the user load (fast — no backend await)
      // and return. The auth_screen listener routes to Home the instant the
      // user model is ready.
      if (userCred.user != null) {
        final signedInUser = userCred.user!;
        unawaited(_loadUserModel(signedInUser));
        return UserModel(
          uid: signedInUser.uid,
          displayName: signedInUser.displayName ?? 'User',
          email: signedInUser.email,
          photoUrl: signedInUser.photoURL,
        );
      }
      return null;
    } on firebase_auth.FirebaseAuthException {
      rethrow; // production: surface real error, no demo mask
    } catch (e) {
      debugPrint('Native Google Sign-In error: $e');
      rethrow; // surface so the button unlocks + user sees the message
    }
  }


  /// Wait for an authenticated backend JWT before showing protected screens.
  /// The wallet itself is loaded separately and is never a locally sourced value.
  Future<bool> ensureBackendReady({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (backendReady) return true;
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    _currentUser = currentUser;
    if (!_loadingBackendSession) {
      unawaited(_loadUserModel(currentUser));
    }
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (backendReady) return true;
      if (_currentUser == null) return false;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return backendReady;
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
    _backendReady = false;
    _sessionGeneration++;
    BalanceStream.instance.clear();
    notifyListeners();
    ApiClient.instance.token = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('backend_token');
      await prefs.remove('backend_refresh_token');
    } catch (_) {}
  }

}