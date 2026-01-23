import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:teamgrid/pages/Auth/auth_service.dart';
import 'package:teamgrid/routes/app_rouutes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;

  bool _isObscured = true;

  void _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      String? role = await _authService.loginUser(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (role != null) {
        if (role == 'Admin') {
          Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        } else if (role == 'PM') {
          Navigator.pushReplacementNamed(context, AppRoutes.pmDashboard);
        } else if (role == 'Employee') {
          Navigator.pushReplacementNamed(context, AppRoutes.employeeDashboard);
        }
      } else {
        _showErrorSnackBar("Data role tidak ditemukan.");
      }
    } catch (e) {
      _showErrorSnackBar("Login Gagal: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                    child: Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.shade50,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/Logo-TeamGrid.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(begin: const Offset(0.5, 0.5), curve: Curves.bounceOut)
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    delay: 0.2.seconds,
                    duration: 1.seconds,
                    color: Colors.blue.shade100,
                  ),

              const SizedBox(height: 40),

              const Text(
                "Welcome",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlue,
                ),
              ),
              const SizedBox(height: 30),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: const TextStyle(color: Colors.blueGrey),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Colors.blue,
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: _isObscured,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: const TextStyle(color: Colors.blueGrey),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.blue,
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        shadowColor: Colors.blue.withOpacity(0.4),
                      ),
                      onPressed: _handleLogin,
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
