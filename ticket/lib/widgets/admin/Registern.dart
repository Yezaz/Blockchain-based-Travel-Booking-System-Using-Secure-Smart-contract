import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'Loginn.dart';


class SignUpiew extends StatefulWidget {
  const SignUpiew({super.key});

  @override
  State<SignUpiew> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpiew> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = credential.user;

        if (user != null) {
          final userData = {
            "uid": user.uid,
            "email": _emailController.text.trim(),
            "name": _usernameController.text.trim(),
            "contact": _phoneController.text.trim(),
            "city": _cityController.text.trim(),
            "status": "approved",
          };

          await FirebaseDatabase.instance.ref('homefoods/${user.uid}').set(userData);

          // Send verification email
          await user.sendEmailVerification();

          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration Successful! Please verify your email.')),
          );

          // Redirect to Login Page after registration
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminLoginPage()),
          );
        }
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration Failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 120),
                  Text(
                    "HomeFoods",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Create your account",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Form Fields
                  _buildTextField(_usernameController, "Full Name", Icons.person),
                  const SizedBox(height: 16),
                  _buildTextField(_emailController, "Email", Icons.email),
                  const SizedBox(height: 16),
                  _buildTextField(_phoneController, "Phone", Icons.phone),
                  const SizedBox(height: 16),
                  _buildTextField(_cityController, "City", Icons.location_city),
                  const SizedBox(height: 16),
                  _buildTextField(_passwordController, "Password", Icons.lock, isPassword: true),
                  const SizedBox(height: 30),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        "SIGN UP",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Login Redirect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => AdminLoginPage()),
                          );
                        },
                        child: Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool isPassword = false,
      }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: Colors.grey.shade800),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: Colors.orange),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
