import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLoginSelected = true; // Toggle between Login and Signup

  // Form Key for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _reenterPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureReenterPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _reenterPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    // Validate form inputs
    if (_formKey.currentState!.validate()) {
      if (!isLoginSelected && !_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to the Terms & Privacy Policy to sign up.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // If valid, proceed with authentication logic
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 24),

                // App / Brand Title
                const Center(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_rounded,
                          size: 40,
                          color: Color(0xFF00A884),
                        ),
                      Text(
                        'Techaxe Chat',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111B21),
                          letterSpacing: 0.5,
                        ),
                      ),
                      ]
                  ),
                ),
                const SizedBox(height: 34),

                // Pill Segmented Toggle Button (Login / Sign up)
                Center(
                  child: Container(
                    height: 50,
                    width: 260,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4E6EB),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isLoginSelected = true;
                                _formKey.currentState?.reset();
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isLoginSelected ? const Color(0xFF00A884) : Colors.transparent,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Text(
                                'Log in',
                                style: TextStyle(
                                  color: isLoginSelected ? Colors.white : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isLoginSelected = false;
                                _formKey.currentState?.reset();
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: !isLoginSelected ? const Color(0xFF00A884) : Colors.transparent,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Text(
                                'Sign up',
                                style: TextStyle(
                                  color: !isLoginSelected ? Colors.white : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 42),

                // Form Fields with Validation
                if (!isLoginSelected) ...[
                  _buildLabel('Full Name'),
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'Hussnain Shahid',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      if (value.trim().length < 3) {
                        return 'Name must be at least 3 characters long';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                ],

                _buildLabel('Email Address'),
                _buildTextField(
                  controller: _emailController,
                  hintText: 'alex@gmail.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    // Email regex validation
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                _buildLabel('Password'),
                _buildTextField(
                  controller: _passwordController,
                  hintText: '12ac34ed56tG',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),

                if (!isLoginSelected) ...[
                  const SizedBox(height: 18),
                  _buildLabel('Confirm Password'),
                  _buildTextField(
                    controller: _reenterPasswordController,
                    hintText: '12ac34ed56tG',
                    prefixIcon: Icons.lock_reset_rounded,
                    obscureText: _obscureReenterPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureReenterPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureReenterPassword = !_obscureReenterPassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 12),

                // Forgot Password / Terms Checkbox
                if (isLoginSelected) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                        );
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFF00A884),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _agreeToTerms,
                          activeColor: const Color(0xFF00A884),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'I agree with ',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Terms & Privacy Policy.',
                          style: TextStyle(
                            color: Color(0xFF00A884),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                const SizedBox(height: 16),

                // Main Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A884),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                      shadowColor: const Color(0xFF00A884).withOpacity(0.4),
                    ),
                    onPressed: _submitForm,
                    child: Text(
                      isLoginSelected ? 'Log In' : 'Sign Up',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Or Continue With Divider
                Row(
                  children: const [
                    Expanded(child: Divider(color: Colors.black12)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or Continue with',
                        style: TextStyle(color: Colors.black45, fontSize: 13),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.black12)),
                  ],
                ),
                const SizedBox(height: 24),

                // Social Sign-in Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.black12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                        label: const Text(
                          'Google',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        onPressed: () {},
                      ),
                    ),
                    // const SizedBox(width: 16),
                    // Expanded(
                    //   child: OutlinedButton.icon(
                    //     style: OutlinedButton.styleFrom(
                    //       padding: const EdgeInsets.symmetric(vertical: 12),
                    //       side: const BorderSide(color: Colors.black12),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(14),
                    //       ),
                    //       backgroundColor: Colors.white,
                    //     ),
                    //     icon: const Icon(Icons.apple, size: 22, color: Colors.black),
                    //     label: const Text(
                    //       'Apple',
                    //       style: TextStyle(
                    //         fontSize: 14,
                    //         fontWeight: FontWeight.w600,
                    //         color: Colors.black87,
                    //       ),
                    //     ),
                    //     onPressed: () {},
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 30),

                // Switch Between Modes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLoginSelected ? "Don't have an account? " : "Already have an account? ",
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isLoginSelected = !isLoginSelected;
                          _formKey.currentState?.reset();
                        });
                      },
                      child: Text(
                        isLoginSelected ? 'Sign up' : 'Log in',
                        style: const TextStyle(
                          color: Color(0xFF00A884),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: Colors.black45, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00A884), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}