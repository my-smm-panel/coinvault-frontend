import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/app_models.dart';
import '../services/app_repository.dart';

/// Auth service handling Firebase Google Sign-In and user session
class AuthService {
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
      }
    } catch (_) {
      // Create default user model if backend unavailable
      _userModel = UserModel(
        uid: firebaseUser.uid,
        displayName: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email,
        photoUrl: firebaseUser.photoURL,
      );
      await _cacheUserModel();
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

  /// Sign in with Google - with fallback for missing Firebase config
  Future<UserModel?> signInWithGoogle() async {
    try {
      final googleProvider = firebase_auth.GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      final credential = await _auth.signInWithProvider(googleProvider);
      if (credential.user != null) {
        await _loadUserModel(credential.user!);
        return _userModel;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In error: ${e.code} - ${e.message}');
      // Fallback: Firebase not configured (dummy apiKey / missing google-services.json)
      // Create demo user so app can be tested without blocking
      if (e.code == 'operation-not-allowed' || 
          e.code == 'invalid-credential' || 
          e.code == 'api-key-not-valid' ||
          e.code == 'invalid-api-key' ||
          e.message?.contains('API key') == true ||
          e.message?.contains('not valid') == true) {
        debugPrint('Firebase auth not configured - using demo mode');
        return await _createDemoUser();
      }
      rethrow;
    } catch (e) {
      debugPrint('Google Sign-In generic error: $e');
      // If Firebase completely unavailable, allow demo login
      if (e.toString().contains('API key') || e.toString().contains('not valid') || e.toString().contains('Firebase')) {
        return await _createDemoUser();
      }
      rethrow;
    }
    return null;
  }

  Future<UserModel> _createDemoUser() async {
    const demoUid = 'demo_user_001';
    _userModel = UserModel(
      uid: demoUid,
      displayName: 'Demo User',
      email: 'demo@coinvault.app',
      photoUrl: null,
      coins: 500,
    );
    await _cacheUserModel();
    return _userModel!;
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    _userModel = null;
  }

  /// Update user coins (local + backend sync)
  Future<void> addCoins(int amount) async {
    if (_userModel == null) return;
    _userModel = _userModel!.copyWith(coins: _userModel!.coins + amount);
    await _cacheUserModel();
    await _syncToBackend();
  }

  Future<void> deductCoins(int amount) async {
    if (_userModel == null) return;
    _userModel = _userModel!.copyWith(coins: (_userModel!.coins - amount).clamp(0, 999999));
    await _cacheUserModel();
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
    await _syncToBackend();
  }

  /// Update withdraw info
  Future<void> updateWithdrawInfo({String? upiId, String? bankDetails}) async {
    if (_userModel == null) return;
    _userModel = _userModel!.copyWith(upiId: upiId, bankDetails: bankDetails);
    await _cacheUserModel();
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