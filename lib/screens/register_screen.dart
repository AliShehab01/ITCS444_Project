import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import 'home/admin_home.dart';
import 'home/renter_home.dart';
import 'home/guest_home.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _contactController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.renter;
  String _preferredContactMethod = 'email';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _contactController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserModel? user = await _authService.registerWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          contact: _contactController.text.trim(),
          idNumber: _idNumberController.text.trim(),
          preferredContactMethod: _preferredContactMethod,
          role: _selectedRole,
        );

        if (user != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful!'),
              backgroundColor: Colors.green,
            ),
          );
          _navigateToHome(user.role);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _navigateToHome(UserRole role) {
    Widget homeScreen;
    switch (role) {
      case UserRole.admin:
        homeScreen = const AdminHome();
        break;
      case UserRole.renter:
        homeScreen = const RenterHome();
        break;
      case UserRole.guest:
        homeScreen = const GuestHome();
        break;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => homeScreen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text('Register'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name Field
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.person, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[400]!),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.email, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[400]!),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.lock, color: Colors.grey[400]),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey[400],
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[400]!),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Colors.grey[400],
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey[400],
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[400]!),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Contact Field
                TextFormField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Contact Number',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.phone, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[400]!),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your contact number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ID Number Field
                TextFormField(
                  controller: _idNumberController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'ID Number',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.badge, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[400]!),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your ID number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Role Selection
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Role',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ...UserRole.values.map((role) {
                        // Don't show guest option in registration
                        if (role == UserRole.guest)
                          return const SizedBox.shrink();

                        return RadioListTile<UserRole>(
                          title: Text(
                            role.displayName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          value: role,
                          groupValue: _selectedRole,
                          activeColor: Colors.blue[400],
                          onChanged: (UserRole? value) {
                            if (value != null) {
                              setState(() {
                                _selectedRole = value;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Preferred Contact Method
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferred Contact Method',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<String>(
                        title: const Text(
                          'Email',
                          style: TextStyle(color: Colors.white),
                        ),
                        value: 'email',
                        groupValue: _preferredContactMethod,
                        activeColor: Colors.blue[400],
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _preferredContactMethod = value;
                            });
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text(
                          'Phone',
                          style: TextStyle(color: Colors.white),
                        ),
                        value: 'phone',
                        groupValue: _preferredContactMethod,
                        activeColor: Colors.blue[400],
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _preferredContactMethod = value;
                            });
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text(
                          'SMS',
                          style: TextStyle(color: Colors.white),
                        ),
                        value: 'sms',
                        groupValue: _preferredContactMethod,
                        activeColor: Colors.blue[400],
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _preferredContactMethod = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Register Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
