import 'package:flutter/material.dart';
import 'dart:io';
import '../core/network/vendor_service.dart';

class VendorProvider with ChangeNotifier {
  final VendorService _vendorService = VendorService();
  
  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get analytics => _analytics;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _vendorService.getAnalytics();
      _analytics = result['data'];
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _vendorService.getProfile();
      _profile = result['data']['vendor'];
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, String> fields, {File? image}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _vendorService.updateProfile(fields, profileImage: image);
      _profile = result['data']['vendor'];
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
