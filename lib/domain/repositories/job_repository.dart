import '../entities/job.dart';

abstract class JobRepository {
  Future<List<Job>> getJobs({
    String? keyword,
    int? categoryId,
    int? minSalary,
    String? location,
  });
  Future<Job> getJobById(int id);
  Future<int> createJob({
    required int companyId,
    required String title,
    String? description,
    String? requirements,
    String? location,
    int salaryMin = 0,
    int salaryMax = 0,
    int? categoryId,
  });
  Future<void> updateJob(int id, Map<String, dynamic> data);
  Future<void> deleteJob(int id);
}
