import 'package:flutter/foundation.dart';
import '../core/network/auth_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;
  VoidCallback? onLogoutCallback;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get mustChangePassword => _user?['mustChangePassword'] == true;

  /// Completes when initial prefs load is done.
  late final Future<void> ready = _init();

  AuthProvider();

  Future<void> _init() async {
    await _loadUserFromPrefs();
  }

  Future<bool> validateToken() async {
    try {
      final userData = await _authService.getMe();

      _user = userData;
      await _saveUserToPrefs(_user!);
      notifyListeners();
      return true;
    } catch (e) {

      return _user != null;
    }
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(AppConstants.userKey);
    if (userData != null) {
      _user = json.decode(userData);
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _authService.login(email, password);
      _user = result['data']['user'];
      await _saveUserToPrefs(_user!);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _authService.register(userData);
      _user = result['data']['user'];
      await _saveUserToPrefs(_user!);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, String> fields, {dynamic image}) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _authService.updateProfile(fields, profileImage: image);
      _user = result['data']['user'];
      await _saveUserToPrefs(_user!);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    _setLoading(true);
    _error = null;
    try {
      await _authService.changePassword(currentPassword, newPassword, confirmPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> forceChangePassword(String newPassword, String confirmPassword) async {
    _setLoading(true);
    _error = null;
    try {
      await _authService.forceChangePassword(newPassword, confirmPassword);
      // Update local user state to clear the flag
      if (_user != null) {
        _user!['mustChangePassword'] = false;
        await _saveUserToPrefs(_user!);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<String?> forgotPassword(String email) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _authService.forgotPassword(email);
      _setLoading(false);
      return result['message'] as String?;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return null;
    }
  }

  Future<String?> verifyOtp(String email, String otp) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _authService.verifyOtp(email, otp);
      _setLoading(false);
      if (result['data'] != null && result['data']['tempToken'] != null) {
        return result['data']['tempToken'] as String?;
      }
      return null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return null;
    }
  }

  Future<String?> resetPasswordWithOtp(String tempToken, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _authService.resetPasswordWithOtp(tempToken, password);
      _setLoading(false);
      return result['message'] as String?;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return null;
    }
  }

  Future<void> logout() async {
    _user = null;
    await _authService.logout();
    onLogoutCallback?.call();
    notifyListeners();
  }

  Future<void> _saveUserToPrefs(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, json.encode(user));
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
