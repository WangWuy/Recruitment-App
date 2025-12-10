import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<User> call({
    required String name,
    required String email,
    required String password,
    String role = 'candidate',
    String? phone,
  }) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      throw ArgumentError('Name, email and password cannot be empty');
    }
    
    if (password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters');
    }
    
    return await _repository.register(
      name: name,
      email: email,
      password: password,
      role: role,
      phone: phone,
    );
  }
}
