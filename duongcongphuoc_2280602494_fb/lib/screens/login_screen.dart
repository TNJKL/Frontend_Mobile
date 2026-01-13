import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/auth.dart';
import 'admin_screen.dart';
import 'main_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _checkToken();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    String? role = prefs.getString('user_role');

    if (token != null && role != null) {
      final roleLower = role.toLowerCase();
      if (roleLower == 'admin' || roleLower == 'staff') {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminScreen()));
      } else {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
      }
    }
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    //serverClientId: '558602254684-49j936b38qirvgho596n3m05a675judq.apps.googleusercontent.com',
    serverClientId: '299592018613-rf44cmgf562gkrhhfkhopjmrkuep1en5.apps.googleusercontent.com',
  );

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken != null) {
        Map<String, dynamic> result = await Auth.loginWithGoogle(idToken);
        setState(() => _isLoading = false);

        if (result['success'] == true) {
          String role = result['role'] ?? 'User';
          final roleLower = role.toLowerCase();
          if (!mounted) return;
          if (roleLower == 'admin' || roleLower == 'staff') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminScreen()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
          }
        } else {
          _showError(result['message'] ?? 'Đăng nhập Google thất bại');
        }
      } else {
        setState(() => _isLoading = false);
        _showError('Không thể lấy ID Token từ Google');
      }
    } catch (error) {
      setState(() => _isLoading = false);
      _showError('Lỗi đăng nhập: $error');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    Map<String, dynamic> result = await Auth.login(_usernameController.text.trim(), _passwordController.text);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_username', _usernameController.text);
      await prefs.setString('saved_password', _passwordController.text);

      String role = result['role'] ?? 'User';
      final roleLower = role.toLowerCase();
      if (!mounted) return;

      if (roleLower == 'admin' || roleLower == 'staff') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
      }
    } else {
      if (!mounted) return;
      _showError(result['message'] ?? 'Sai tên đăng nhập hoặc mật khẩu');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background subtle pattern or gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.pink[50]!],
                stops: const [0.3, 1.0],
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.pink[100]!.withOpacity(0.3),
              ),
            ),
          ),
           Positioned(
            top: 100,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange[100]!.withOpacity(0.3),
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
                      // Logo
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.pink.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                          ],
                        ),
                        child: Icon(Icons.favorite_rounded, size: 60, color: Colors.pink[400]),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Chào mừng trở lại',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          fontFamily: 'PlayfairDisplay', // Suggesting a standard serif if available, else falls back
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đăng nhập để tiếp tục quản lý đám cưới',
                         style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 40),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextField(_usernameController, 'Tên đăng nhập / Email', Icons.person_outline),
                            const SizedBox(height: 16),
                            _buildTextField(
                              _passwordController, 
                              'Mật khẩu', 
                              Icons.lock_outline,
                              isPassword: true,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink[400],
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shadowColor: Colors.pink.withOpacity(0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Đăng Nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('hoặc', style: TextStyle(color: Colors.grey[400])),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Google Login
                      SizedBox(
                         width: double.infinity,
                         height: 52,
                         child: OutlinedButton.icon(
                           onPressed: _isLoading ? null : _handleGoogleLogin,
                           style: OutlinedButton.styleFrom(
                             side: BorderSide(color: Colors.grey[300]!),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                             backgroundColor: Colors.white,
                           ),
                           icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 28),
                           label: Text('Tiếp tục với Google', style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                         ),
                      ),

                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Chưa có tài khoản? ', style: TextStyle(color: Colors.grey[600])),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistrationScreen())),
                            child: Text('Đăng ký ngay', style: TextStyle(color: Colors.pink[400], fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
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

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        labelText: hint,
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
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red)),
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập $hint' : null,
    );
  }
}
