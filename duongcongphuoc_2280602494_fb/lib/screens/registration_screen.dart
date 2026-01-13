import 'package:flutter/material.dart';
import '../utils/auth.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _initialsController = TextEditingController();
  String _selectedRole = 'User';
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _roles = ['User', 'Staff', 'Admin'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _otpSent = false;
  int _countdown = 0;

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _initialsController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số điện thoại')));
      return;
    }

    setState(() => _isLoading = true);

    final result = await Auth.sendOTP(_phoneController.text.trim());

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() {
        _otpSent = true;
        _countdown = 60;
      });
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP đã được gửi thành công!'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Không thể gửi OTP'), backgroundColor: Colors.red));
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0) {
        setState(() {
          _countdown--;
        });
        _startCountdown();
      } else if (mounted) {
        setState(() {
          // _otpSent = false; // Optional: Force resend after timeout? Or just let them hit resend if implemented.
        });
      }
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_otpSent || _otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập và gửi OTP trước')));
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> result = await Auth.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      initials: _initialsController.text.trim(),
      role: _selectedRole,
      phone: _phoneController.text.trim(),
      otp: _otpController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Wait a bit or navigate immediately
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Đăng ký thất bại', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tạo Tài Khoản Mới', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
           // Background subtle pattern or gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.pink[50]!],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.pink.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                          ],
                        ),
                        child: Icon(Icons.person_add_alt_1_rounded, size: 48, color: Colors.pink[400]),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Tham gia ngay',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Điền thông tin bên dưới để đăng ký',
                        style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 32),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextField(_usernameController, 'Tên đăng nhập', Icons.person_outline),
                            const SizedBox(height: 16),
                            _buildTextField(_emailController, 'Địa chỉ Email', Icons.email_outlined),
                            const SizedBox(height: 16),
                            _buildTextField(_passwordController, 'Mật khẩu', Icons.lock_outline, isPassword: true),
                            const SizedBox(height: 16),
                            
                            // Phone and OTP Section
                            _buildTextField(_phoneController, 'Số điện thoại', Icons.phone_android_rounded),
                            const SizedBox(height: 16),
                            Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(_otpController, 'Mã OTP', Icons.security_rounded),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _isLoading || _countdown > 0 ? null : _sendOTP,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Match height roughly
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                                    ),
                                    child: _countdown > 0
                                        ? Text('$_countdown s')
                                        : const Text('Gửi OTP'),
                                  ),
                                ],
                              ),
                             const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(child: _buildTextField(_initialsController, 'Tên viết tắt (VD: TD)', Icons.badge_outlined)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedRole,
                                    decoration: InputDecoration(
                                      labelText: 'Vai trò',
                                      prefixIcon: Icon(Icons.admin_panel_settings_outlined, color: Colors.pink[300]),
                                      filled: true,
                                      fillColor: Colors.white,
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.pink[300]!)),
                                    ),
                                    items: _roles.map((role) {
                                      return DropdownMenuItem<String>(value: role, child: Text(role));
                                    }).toList(),
                                    onChanged: (value) => setState(() => _selectedRole = value!),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink[400],
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shadowColor: Colors.pink.withOpacity(0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Đăng Ký Tài Khoản', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Đã có tài khoản? ', style: TextStyle(color: Colors.grey[600])),
                           GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text('Đăng nhập', style: TextStyle(color: Colors.pink[400], fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.pink[300]),
        suffixIcon: isPassword
          ? IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey[400]),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            )
          : null,
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.pink[300]!)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Vui lòng nhập $label';
        if (isPassword && value.length < 6) return 'Mật khẩu phải > 6 ký tự';
        // Basic phone validation if it's the phone controller
        if (controller == _phoneController && (value.length < 9 || int.tryParse(value) == null)) {
             return 'Số điện thoại không hợp lệ';
        }
        return null;
      },
    );
  }
}
