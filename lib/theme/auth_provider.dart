import 'package:flutter/material.dart';
import '../models/user.dart';
import '../utils/error_handler.dart';

/// Authentication state management. Similar to ThemeProvider, this provides
/// global authentication state that can be accessed from anywhere in the app
/// using Provider.
class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  /// Simulates login with email and password.
  /// In a real app, this would call an authentication API.
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Simple validation for demo
      if (email.isEmpty || password.isEmpty) {
        throw 'Please enter both email and password';
      }

      if (!email.contains('@')) {
        throw 'Please enter a valid email address';
      }

      if (password.length < 6) {
        throw 'Password must be at least 6 characters';
      }

      // Simulate successful login
      _user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: email.split('@')[0],
        isEmailVerified: true, // Simplified for demo
      );

      return true;
    } catch (e) {
      String friendlyMessage;
      if (e is String) {
        friendlyMessage = e;
      } else {
        friendlyMessage = ErrorHandler.getUserFriendlyErrorMessage(e, isAuthContext: true);
      }
      _setError(friendlyMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Simulates registration with email, password, and display name.
  /// In a real app, this would call an authentication API.
  Future<bool> register(String email, String password, String displayName) async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Simple validation for demo
      if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
        throw 'Please fill in all fields';
      }

      if (!email.contains('@')) {
        throw 'Please enter a valid email address';
      }

      if (password.length < 6) {
        throw 'Password must be at least 6 characters';
      }

      if (displayName.length < 2) {
        throw 'Display name must be at least 2 characters';
      }

      // Simulate successful registration
      _user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: displayName,
        isEmailVerified: false, // Would need email verification in real app
      );

      return true;
    } catch (e) {
      String friendlyMessage;
      if (e is String) {
        friendlyMessage = e;
      } else {
        friendlyMessage = ErrorHandler.getUserFriendlyErrorMessage(e, isAuthContext: true);
      }
      _setError(friendlyMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logs out the current user.
  Future<void> logout() async {
    _setLoading(true);
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      _user = null;
    } finally {
      _setLoading(false);
    }
  }

  /// Simulates sending a password reset email.
  /// In a real app, this would call an authentication API to send a reset link.
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Simple validation for demo
      if (email.isEmpty) {
        throw 'Please enter your email';
      }

      if (!email.contains('@')) {
        throw 'Please enter a valid email address';
      }

      // Simulate successful email sending
      // In a real app, this would actually send an email
      return true;
    } catch (e) {
      String friendlyMessage;
      if (e is String) {
        friendlyMessage = e;
      } else {
        friendlyMessage = ErrorHandler.getUserFriendlyErrorMessage(e, isAuthContext: true);
      }
      _setError(friendlyMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clears the current user and resets state.
  void clear() {
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }
}