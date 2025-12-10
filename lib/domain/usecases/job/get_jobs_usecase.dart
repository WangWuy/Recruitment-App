import '../../entities/job.dart';
import '../../repositories/job_repository.dart';

class GetJobsUseCase {
  final JobRepository _repository;

  GetJobsUseCase(this._repository);

  Future<List<Job>> call({
    String? keyword,
    int? categoryId,
    int? minSalary,
    String? location,
  }) async {
    return await _repository.getJobs(
      keyword: keyword,
      categoryId: categoryId,
      minSalary: minSalary,
      location: location,
    );
  }
}
