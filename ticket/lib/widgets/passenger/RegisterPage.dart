import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'LoginPage.dart';

class BusRegisterPage extends StatefulWidget {
  const BusRegisterPage({super.key});

  @override
  State<BusRegisterPage> createState() => _BusRegisterPageState();
}

class _BusRegisterPageState extends State<BusRegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.ref().child('users');

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final uid = userCredential.user!.uid;

        await _database.child(uid).set({
          'full_name': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'account_type': 'passenger',
          'registration_date': DateTime.now().toString(),
          'wallet_balance': 0.0,
          'trips_taken': 0,
          'ukey': uid,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration Successful!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BusLoginPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bus_background.jpg'), // Replace with your asset
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // Header with back button
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Spacer(),
                    ],
                  ),

                  SizedBox(height: 20),

                  // App logo and title
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      size: 50,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Book your bus tickets with ease',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Registration Form
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Full Name
                            _buildInputField(
                              controller: _fullNameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              validator: (value) =>
                              value!.isEmpty ? 'Please enter your full name' : null,
                            ),
                            const SizedBox(height: 16),

                            // Email
                            _buildInputField(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) =>
                              value!.isEmpty
                                  ? 'Please enter your email'
                                  : !value.contains('@')
                                  ? 'Enter a valid email'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Phone Number
                            _buildInputField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (value) =>
                              value!.isEmpty ? 'Please enter your phone number' : null,
                            ),
                            const SizedBox(height: 16),

                            // Password
                            _buildInputField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outlined,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: (value) =>
                              value!.isEmpty
                                  ? 'Please enter a password'
                                  : value.length < 6
                                  ? 'Password must be at least 6 characters'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password
                            _buildInputField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              icon: Icons.lock_outlined,
                              obscureText: _obscureConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              validator: (value) =>
                              value!.isEmpty
                                  ? 'Please confirm your password'
                                  : value != _passwordController.text
                                  ? 'Passwords do not match'
                                  : null,
                            ),
                            const SizedBox(height: 24),

                            // Register Button
                            SizedBox(
                              height: 50,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _registerUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF4285F4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )
                                    : const Text(
                                  'CREATE ACCOUNT',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Terms and Conditions
                            Text(
                              'By registering, you agree to our Terms of Service and Privacy Policy',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Already have account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => BusLoginPage()),
                          );
                        },
                        child: Text(
                          'Login Here',
                          style: TextStyle(
                            color: Color(0xFF4285F4),
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
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: Color(0xFF4285F4),
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        labelStyle: TextStyle(
          color: Colors.grey[600],
        ),
      ),
    );
  }
}