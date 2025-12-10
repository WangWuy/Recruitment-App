import 'package:flutter/foundation.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();
  
  Map<String, dynamic>? _stats;
  List<dynamic> _users = [];
  List<dynamic> _jobs = [];
  bool _loading = false;
  String? _lastError;

  Map<String, dynamic>? get stats => _stats;
  List<dynamic> get users => _users;
  List<dynamic> get jobs => _jobs;
  bool get loading => _loading;
  String? get lastError => _lastError;

  Future<void> loadStats(String? token) async {
    if (token == null) return;
    _loading = true;
    notifyListeners();
    try {
      final response = await _adminService.getStats(token);
      if (response['data'] != null) {
        _stats = response['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading admin stats: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers(String? token, {String? role}) async {
    if (token == null) return;
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      final response = await _adminService.getAllUsers(token, role: role);
      if (response['data'] != null) {
        _users = response['data'] as List<dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      _lastError = e.toString();
      _users = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser(String? token, int userId, Map<String, dynamic> data) async {
    if (token == null) return false;
    try {
      await _adminService.updateUser(token, userId, data);
      await loadUsers(token);
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> deleteUser(String? token, int userId) async {
    if (token == null) return false;
    try {
      await _adminService.deleteUser(token, userId);
      await loadUsers(token);
      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> createUser(String? token, Map<String, dynamic> data) async {
    if (token == null) return false;
    try {
      await _adminService.createUser(token, data);
      await loadUsers(token);
      return true;
    } catch (e) {
      debugPrint('Error creating user: $e');
      _lastError = e.toString();
      return false;
    }
  }

  Future<void> loadJobs(String? token, {String? status}) async {
    if (token == null) return;
    _loading = true;
    notifyListeners();
    try {
      final response = await _adminService.getAllJobs(token, status: status);
      if (response['data'] != null) {
        _jobs = response['data'] as List<dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading jobs: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateJob(String? token, int jobId, Map<String, dynamic> data) async {
    if (token == null) return false;
    try {
      await _adminService.updateJob(token, jobId, data);
      await loadJobs(token);
      return true;
    } catch (e) {
      debugPrint('Error updating job: $e');
      return false;
    }
  }

  Future<bool> deleteJob(String? token, int jobId) async {
    if (token == null) return false;
    try {
      await _adminService.deleteJob(token, jobId);
      await loadJobs(token);
      return true;
    } catch (e) {
      debugPrint('Error deleting job: $e');
      return false;
    }
  }

  Future<bool> moderateJob(String? token, int jobId, String action) async {
    if (token == null) return false;
    try {
      final res = await _adminService.moderateJob(token, jobId, action);
      // Không tự reload ở đây; màn hình sẽ reload theo filter đang chọn
      final newStatus = res['status'] as String?;
      return newStatus == 'active' || newStatus == 'rejected';
    } catch (e) {
      debugPrint('Error moderating job: $e');
      return false;
    }
  }
}

