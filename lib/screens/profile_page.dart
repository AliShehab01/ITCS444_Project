import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import 'login_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _idNumberController = TextEditingController();
  
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isEditing = false;
  String _preferredContactMethod = 'email';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        if (userData != null && mounted) {
          setState(() {
            _currentUser = userData;
            _nameController.text = userData.name;
            _contactController.text = userData.contact;
            _idNumberController.text = userData.idNumber;
            _preferredContactMethod = userData.preferredContactMethod;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.updateUserProfile(
          uid: _currentUser!.uid,
          name: _nameController.text.trim(),
          contact: _contactController.text.trim(),
          idNumber: _idNumberController.text.trim(),
          preferredContactMethod: _preferredContactMethod,
        );

        await _loadUserData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isEditing = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
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

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Sign Out',
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.grey[850],
          title: const Text('Profile'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text('Profile'),
        actions: [
          if (!_isEditing && _currentUser?.role != UserRole.guest)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Avatar
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blue[400],
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getRoleColor(_currentUser?.role ?? UserRole.guest),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentUser?.role.displayName ?? 'Guest',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Name Field
              TextFormField(
                controller: _nameController,
                enabled: _isEditing,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.person, color: Colors.grey[400]),
                  filled: true,
                  fillColor: _isEditing ? Colors.grey[800] : Colors.grey[850],
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
                  if (_isEditing && (value == null || value.isEmpty)) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Field (Read-only)
              TextFormField(
                initialValue: _currentUser?.email ?? '',
                enabled: false,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.email, color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Contact Field
              TextFormField(
                controller: _contactController,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Contact Number',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.phone, color: Colors.grey[400]),
                  filled: true,
                  fillColor: _isEditing ? Colors.grey[800] : Colors.grey[850],
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
                  if (_isEditing && (value == null || value.isEmpty)) {
                    return 'Please enter your contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ID Number Field
              TextFormField(
                controller: _idNumberController,
                enabled: _isEditing,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'ID Number',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.badge, color: Colors.grey[400]),
                  filled: true,
                  fillColor: _isEditing ? Colors.grey[800] : Colors.grey[850],
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
                  if (_isEditing && (value == null || value.isEmpty)) {
                    return 'Please enter your ID number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Preferred Contact Method
              if (_isEditing)
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
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
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
                )
              else
                ListTile(
                  leading: Icon(Icons.contact_mail, color: Colors.grey[400]),
                  title: Text(
                    'Preferred Contact Method',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  subtitle: Text(
                    _preferredContactMethod.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  tileColor: Colors.grey[850],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              const SizedBox(height: 24),

              // Action Buttons
              if (_isEditing) ...[
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _nameController.text = _currentUser?.name ?? '';
                      _contactController.text = _currentUser?.contact ?? '';
                      _idNumberController.text = _currentUser?.idNumber ?? '';
                      _preferredContactMethod =
                          _currentUser?.preferredContactMethod ?? 'email';
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[400],
                    side: BorderSide(color: Colors.grey[400]!),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Account Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('User ID', _currentUser?.uid ?? 'N/A'),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Member Since',
                      _formatDate(_currentUser?.createdAt),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[500]),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple[400]!;
      case UserRole.renter:
        return Colors.green[400]!;
      case UserRole.guest:
        return Colors.orange[400]!;
    }
  }
}
