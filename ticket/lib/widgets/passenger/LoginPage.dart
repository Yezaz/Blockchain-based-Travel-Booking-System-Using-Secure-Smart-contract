import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/auth_services.dart';
import 'RegisterPage.dart';

class BusLoginPage extends StatefulWidget {
  @override
  _BusLoginPageState createState() => _BusLoginPageState();
}

class _BusLoginPageState extends State<BusLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final AuthService _authService = AuthService();

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login Failed', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Color(0xFF4285F4))),
          ),
        ],
      ),
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error = await _authService.womensLogin({
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      }, context);

      if (mounted) {
        setState(() => _isLoading = false);
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => NextPage()),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Background Image
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/bus_background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo
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
                      SizedBox(height: 16),

                      // App Title
                      Text(
                        'BusTicket Pro',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Book your journey with ease',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 32),

                      // Login Card
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 24),

                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email, color: Color(0xFF4285F4)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  validator: (value) => value!.isEmpty || !value.contains('@')
                                      ? 'Enter a valid email'
                                      : null,
                                ),
                                SizedBox(height: 16),

                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(Icons.lock, color: Color(0xFF4285F4)),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  validator: (value) => value!.isEmpty || value.length < 6
                                      ? 'Password must be 6+ characters'
                                      : null,
                                ),
                                SizedBox(height: 20),

                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF4285F4),
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : Text(
                                      'LOGIN',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 16),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey)),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Text('OR', style: TextStyle(color: Colors.grey)),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Sign Up Option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "New to BusTicket Pro? ",
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => BusRegisterPage()),
                              );
                            },
                            child: Text(
                              "Create Account",
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
            ),
          ],
        ),
      ),
    );
  }
}
