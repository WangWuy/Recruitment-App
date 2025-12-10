import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_auth_provider.dart';
import '../widgets/error_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'candidate';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    
    try {
      await authProvider.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
      );
      
      if (mounted) {
        // Navigate based on user role
        switch (_selectedRole) {
          case 'candidate':
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 'employer':
            Navigator.pushReplacementNamed(context, '/employer');
            break;
          case 'admin':
            Navigator.pushReplacementNamed(context, '/admin');
            break;
          default:
            Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
        
        // Kiểm tra các loại lỗi cụ thể
        if (e.toString().contains('Email đã tồn tại') || 
            e.toString().contains('Email already exists')) {
          errorMessage = 'Email này đã được sử dụng. Vui lòng chọn email khác.';
        } else if (e.toString().contains('timeout') || 
                   e.toString().contains('SocketException')) {
          errorMessage = 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.';
        } else if (e.toString().contains('Connection refused')) {
          errorMessage = 'Không thể kết nối đến server. Vui lòng kiểm tra XAMPP.';
        } else if (e.toString().contains('400') || e.toString().contains('Bad Request')) {
          errorMessage = 'Thông tin không hợp lệ. Vui lòng kiểm tra lại.';
        } else if (e.toString().contains('500') || e.toString().contains('Server error')) {
          errorMessage = 'Lỗi server. Vui lòng thử lại sau.';
        }
        
        ErrorDialog.show(context, errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 30),
                // Logo và thương hiệu
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.white, Color(0xFFf093fb)],
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.person_add_outlined,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'DT - TOP CV',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const Text(
                              'Tham gia cộng đồng tuyển dụng',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                // Form đăng ký
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Tạo tài khoản mới',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3748),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 28),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Họ và tên',
                                    prefixIcon: const Icon(Icons.person_outline),
                                    hintText: 'Nhập họ và tên của bạn',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập họ và tên';
                                    }
                                    if (value.length < 2) {
                                      return 'Họ và tên phải có ít nhất 2 ký tự';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    hintText: 'Nhập email của bạn',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Email không hợp lệ';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Mật khẩu',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    hintText: 'Nhập mật khẩu của bạn',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập mật khẩu';
                                    }
                                    if (value.length < 6) {
                                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'Xác nhận mật khẩu',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    hintText: 'Nhập lại mật khẩu',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  obscureText: _obscureConfirmPassword,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng xác nhận mật khẩu';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Mật khẩu không khớp';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedRole,
                                  decoration: InputDecoration(
                                    labelText: 'Vai trò',
                                    prefixIcon: const Icon(Icons.work_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'candidate',
                                      child: Text('Ứng viên'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'employer',
                                      child: Text('Nhà tuyển dụng'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole = value ?? 'candidate';
                                    });
                                  },
                                ),
                                const SizedBox(height: 24),
                                Consumer<SimpleAuthProvider>(
                                  builder: (context, authProvider, child) {
                                    return Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF667eea).withOpacity(0.3),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: authProvider.loading ? null : _register,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: authProvider.loading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text(
                                                'Đăng ký',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Đã có tài khoản? ',
                                      style: TextStyle(
                                        color: Color(0xFF718096),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        'Đăng nhập ngay',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF667eea),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}