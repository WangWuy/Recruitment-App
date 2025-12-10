import 'package:flutter/material.dart';
import '../services/job_service.dart';

class JobProvider extends ChangeNotifier {
  final _jobService = JobService();
  
  List<Map<String, dynamic>> _jobs = [];
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> get jobs => _jobs;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchMore({
    String? keyword,
    int? categoryId,
    int? minSalary,
    int? maxSalary,
    String? location,
    String? employmentType,
    String? experienceLevel,
    int page = 1,
    int limit = 10,
  }) async {
    // Delay để tránh setState during build
    await Future.delayed(Duration.zero);
    _error = null;
    
    try {
      final newJobs = await _jobService.fetchJobs(
        keyword: keyword,
        categoryId: categoryId,
        minSalary: minSalary,
        maxSalary: maxSalary,
        location: location,
        employmentType: employmentType,
        experienceLevel: experienceLevel,
        page: page,
        limit: limit,
      );
      
      // Append new jobs to existing list
      _jobs.addAll(newJobs);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> fetch({
    String? keyword,
    int? categoryId,
    int? minSalary,
    int? maxSalary,
    String? location,
    String? employmentType,
    String? experienceLevel,
    int page = 1,
    int limit = 10,
  }) async {
    // Delay để tránh setState during build
    await Future.delayed(Duration.zero);
    _setLoading(true);
    _error = null;
    
    try {
      final jobs = await _jobService.fetchJobs(
        keyword: keyword,
        categoryId: categoryId,
        minSalary: minSalary,
        maxSalary: maxSalary,
        location: location,
        employmentType: employmentType,
        experienceLevel: experienceLevel,
        page: page,
        limit: limit,
      );
      
      _jobs = jobs;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> getJobById(int jobId) async {
    try {
      return await _jobService.getJobById(jobId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> applyForJob(String token, {
    required int jobId,
    String? coverLetter,
    int? expectedSalary,
    String? availableFrom,
  }) async {
    try {
      await _jobService.applyForJob(
        token,
        jobId: jobId,
        coverLetter: coverLetter,
        expectedSalary: expectedSalary,
        availableFrom: availableFrom,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> toggleSaveJob(String token, int jobId) async {
    try {
      final result = await _jobService.toggleSaveJob(token, jobId);
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSavedJobs(String token) async {
    try {
      return await _jobService.getSavedJobs(token);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getApplications(String token) async {
    try {
      return await _jobService.getApplications(token);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<int> createJob(String token, Map<String, dynamic> jobData) async {
    try {
      final jobId = await _jobService.createJob(token, jobData);
      // Refresh jobs list after creating
      await fetch();
      return jobId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Method để load lại jobs (alias của fetch)
  Future<void> loadJobs() async {
    await fetch();
  }

  // Update job status
  Future<void> updateJobStatus(String token, int jobId, String status) async {
    try {
      await _jobService.updateJobStatus(token, jobId, status);
      // Refresh jobs list after updating
      await fetch();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void _setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}