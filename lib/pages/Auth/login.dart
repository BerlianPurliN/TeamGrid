import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const Text("TeamGrid Login")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                ),
              ),
              obscureText: _isObscured,
            ),
            const SizedBox(height: 20),

            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleLogin,
                    child: const Text("Login"),
                  ),
          ],
        ),
      ),
    );
  }
}
