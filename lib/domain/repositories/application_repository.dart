import '../entities/application.dart';

abstract class ApplicationRepository {
  Future<void> applyForJob(int jobId);
  Future<List<Application>> getApplications();
  Future<void> updateApplicationStatus(int applicationId, String status);
}
