import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:farmer_consumer_marketplace/models/user_model.dart';
import 'package:farmer_consumer_marketplace/services/auth_service.dart';
import 'package:farmer_consumer_marketplace/widgets/common/app_bar.dart';
import 'package:farmer_consumer_marketplace/utils/validators.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getCurrentUser();

      if (user != null) {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _phoneController.text = user.phoneNumber;
        _locationController.text = user.location;

        setState(() {
          _user = user;
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final updatedUser = _user!.copyWith(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        location: _locationController.text.trim(),
      );

      await authService.updateUserProfile(updatedUser);

      setState(() {
        _user = updatedUser;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final imageUrl = await authService.uploadProfileImage(image.path);

        final updatedUser = _user!.copyWith(
          profileImageUrl: imageUrl,
        );

        await authService.updateUserProfile(updatedUser);

        setState(() {
          _user = updatedUser;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture updated'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: ${error.toString()}'),
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

  Future<void> _signOut() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Profile',
        // showBackButton: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile picture
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60.0,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _user?.profileImageUrl != null
                            ? NetworkImage(_user!.profileImageUrl!)
                            : null,
                        child: _user?.profileImageUrl == null
                            ? Icon(
                                Icons.person,
                                size: 60.0,
                                color: Colors.grey[400],
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickImage,
                          child: Container(
                            padding: EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  
                  // User role badge
                  if (_user != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: _user!.role == UserRole.farmer
                            ? Colors.green[100]
                            : Colors.blue[100],
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Text(
                        _user!.role == UserRole.farmer ? 'Farmer' : 'Consumer',
                        style: TextStyle(
                          color: _user!.role == UserRole.farmer
                              ? Colors.green[800]
                              : Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  SizedBox(height: 24.0),
                  
                  // Profile form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Name field
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                            enabled: _isEditing,
                          ),
                          validator: Validators.validateName,
                        ),
                        SizedBox(height: 16.0),
                        
                        // Email field (non-editable)
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                            enabled: false,
                          ),
                          validator: Validators.validateEmail,
                        ),
                        SizedBox(height: 16.0),
                        
                        // Phone field
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                            enabled: _isEditing,
                          ),
                          validator: Validators.validatePhone,
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 16.0),
                        
                        // Location field
                        TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                            enabled: _isEditing,
                            suffixIcon: _isEditing
                                ? IconButton(
                                    icon: Icon(Icons.my_location),
                                    onPressed: () {
                                      // Get current location
                                    },
                                  )
                                : null,
                          ),
                          validator: Validators.validateLocation,
                        ),
                        SizedBox(height: 24.0),
                        
                        // Action buttons
                        if (_isEditing) ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                      
                                      // Reset form fields
                                      _nameController.text = _user!.name;
                                      _phoneController.text = _user!.phoneNumber;
                                      _locationController.text = _user!.location;
                                    });
                                  },
                                  child: Text('Cancel'),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 16.0),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.0),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _updateProfile,
                                  child: Text('Save Changes'),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 16.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 32.0),
                  
                  // Account section
                  Card(
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16.0),
                          _buildAccountOption(
                            icon: Icons.lock,
                            title: 'Change Password',
                            onTap: () {
                              // Navigate to change password screen
                            },
                          ),
                          Divider(),
                          _buildAccountOption(
                            icon: Icons.notifications,
                            title: 'Notification Settings',
                            onTap: () {
                              // Navigate to notification settings
                            },
                          ),
                          Divider(),
                          _buildAccountOption(
                            icon: Icons.language,
                            title: 'Language',
                            value: 'English',
                            onTap: () {
                              // Show language options
                            },
                          ),
                          Divider(),
                          _buildAccountOption(
                            icon: Icons.help,
                            title: 'Help & Support',
                            onTap: () {
                              // Navigate to help screen
                            },
                          ),
                          Divider(),
                          _buildAccountOption(
                            icon: Icons.info,
                            title: 'About',
                            onTap: () {
                              // Navigate to about screen
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.0),
                  
                  // Sign out button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: Icon(Icons.logout, color: Colors.red),
                      label: Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        side: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAccountOption({
    required IconData icon,
    required String title,
    String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey[600],
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}