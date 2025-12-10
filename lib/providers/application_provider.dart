import '../services/application_service.dart';

class ApplicationProvider {
  final ApplicationService _applicationService = ApplicationService();
  ApplicationService get applicationService => _applicationService;
  
  List<Map<String, dynamic>> _applications = [];
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> get applications => _applications;
  bool get loading => _loading;
  String? get error => _error;

  // Apply for a job
  Future<bool> applyForJob(String token, int jobId, String coverLetter) async {
    _setLoading(true);
    _error = null;
    
    try {
      await _applicationService.applyForJob(token, jobId, coverLetter);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cancel application
  Future<bool> cancelApplication(String token, int applicationId) async {
    _setLoading(true);
    _error = null;
    
    try {
      await _applicationService.cancelApplication(token, applicationId);
      // Remove from local list
      _applications.removeWhere((app) => app['id'] == applicationId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load user applications
  Future<void> loadUserApplications(String token) async {
    _setLoading(true);
    _error = null;
    
    try {
      _applications = await _applicationService.getUserApplications(token);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Check if user has applied for a job
  Future<bool> hasAppliedForJob(String token, int jobId) async {
    try {
      return await _applicationService.hasAppliedForJob(token, jobId);
    } catch (e) {
      return false;
    }
  }

  // Update application status (for employers)
  Future<bool> updateApplicationStatus(
    String token, 
    int applicationId, 
    String status, 
    String? feedback
  ) async {
    _setLoading(true);
    _error = null;
    
    try {
      await _applicationService.updateApplicationStatus(token, applicationId, status, feedback);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load job applications (for employers)
  Future<void> loadJobApplications(String token, int jobId) async {
    _setLoading(true);
    _error = null;
    
    try {
      _applications = await _applicationService.getJobApplications(token, jobId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _loading = loading;
  }

  void clearError() {
    _error = null;
  }
}
