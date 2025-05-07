import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_project1/admin_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_project1/tab_menu.dart';
import 'package:flutter_project1/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    //ตรวจสอบ admin local login
    if (_emailController.text == 'admin' && _passwordController.text == 'admin') {
      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminScreen()),
      );
      return;
    }

    try {
      final url = Uri.parse('http://localhost:5000/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        })
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];

        if (token != null && token is String) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          print(response.body);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TabMenu()),
          );
        } else {
          setState(() {
            _errorMessage = 'Login failed: Invalid token received';
          });
        }
      } else {
        final responseData = jsonDecode(response.body);
        setState(() {
          _errorMessage = responseData['message'] ?? 'Login failed';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color.fromARGB(255, 251, 251, 251),
    body: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const SizedBox(height: 60),
            
            Center(
              child: Image.asset(
                'assets/carrent.jpg',
                height: 100,
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              "Login to your Account",
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  } else if (!value.contains('@') && value != 'admin') {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
            ),

            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  } else if (value.length < 6 && value != 'admin') {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF132B94),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _login();
                        }
                      },
                      child: const Text("Sign In",style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                    ),
            ),

            const SizedBox(height: 16),
            const Center(child: Text("– Or don't have an account yet –")),
            const SizedBox(height: 12),
            const SizedBox(height: 24),

            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text(
                  "Sign Up",
                  style: TextStyle(color: Colors.blue),
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