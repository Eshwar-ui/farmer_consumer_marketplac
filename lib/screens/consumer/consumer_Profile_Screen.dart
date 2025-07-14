import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:farmer_consumer_marketplace/widgets/common/app_bar.dart';
import 'package:farmer_consumer_marketplace/services/firebase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:convert'; // Added for base64Decode

class ConsumerProfileScreen extends StatefulWidget {
  @override
  _ConsumerProfileScreenState createState() => _ConsumerProfileScreenState();
}

class _ConsumerProfileScreenState extends State<ConsumerProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _isNewProfile = false;

  Map<String, dynamic> _userData = {};

  // Controllers for editing
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  File? _profileImageFile;

  @override
  void initState() {
    super.initState();
    _loadConsumerProfile();
  }

  Future<void> _loadConsumerProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if user is logged in
      if (_firebaseService.currentUserId == null) {
        setState(() {
          _errorMessage = 'You need to be logged in to view your profile.';
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic>? userData =
          await _firebaseService.getConsumerProfile();

      if (userData != null && userData.isNotEmpty) {
        setState(() {
          _userData = userData;
          _isLoading = false;
        });

        // Set controller values
        _setControllerValues();
      } else {
        // Profile not found - create a new profile
        print('Consumer profile not found, creating a new one');
        setState(() {
          _isNewProfile = true;
          _isEditing = true;
          _isLoading = false;

          // Initialize with default values
          _initializeDefaultValues();
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _errorMessage = 'Error loading profile. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _initializeDefaultValues() {
    // Try to get user info from Firebase Auth
    final user = _firebaseService.auth.currentUser;

    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _phoneController.text = user.phoneNumber ?? '';

      // Pre-fill email in userData (readonly)
      _userData['email'] = user.email;
    }
  }

  void _setControllerValues() {
    _nameController.text = _userData['name'] ?? '';
    _phoneController.text = _userData['phoneNumber'] ?? '';
    _addressController.text = _userData['address'] ?? '';

    // Parse location if it exists (format: "City, State")
    String location = _userData['location'] ?? '';
    if (location.isNotEmpty) {
      List<String> parts = location.split(', ');
      if (parts.length >= 1) {
        _cityController.text = parts[0];
      }
      if (parts.length >= 2) {
        _stateController.text = parts[1];
      }
    }

    _pincodeController.text = _userData['pincode'] ?? '';
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_profileImageFile == null) return null;

    try {
      // Create a reference to the storage location
      String fileName =
          'profile_${_firebaseService.currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_images/$fileName',
      );

      // Upload file
      await storageRef.putFile(_profileImageFile!);

      // Get download URL
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    // Validate required fields
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Name and phone number are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Upload profile image if changed
      String? profileImageUrl =
          _profileImageFile != null
              ? await _uploadProfileImage()
              : _userData['profileImageUrl'];

      // Prepare updated data
      Map<String, dynamic> updatedData = {
        'name': _nameController.text,
        'phoneNumber': _phoneController.text,
        'address': _addressController.text,
        'location': '${_cityController.text}, ${_stateController.text}',
        'pincode': _pincodeController.text,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Add profile pic URL if available
      if (profileImageUrl != null) {
        updatedData['profileImageUrl'] = profileImageUrl;
      }

      // For new profiles, add creation timestamp
      if (_isNewProfile) {
        updatedData['createdAt'] = DateTime.now().toIso8601String();

        // Add email from Firebase Auth if available
        final user = _firebaseService.auth.currentUser;
        if (user != null && user.email != null) {
          updatedData['email'] = user.email;
        }
      }

      // Save to Firebase
      bool success = await _firebaseService.updateConsumerProfile(updatedData);

      if (success) {
        // Reload profile
        setState(() {
          _isNewProfile = false;
        });
        await _loadConsumerProfile();

        // Exit edit mode
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile ${_isNewProfile ? 'created' : 'updated'} successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(
          'Failed to ${_isNewProfile ? 'create' : 'update'} profile',
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isNewProfile ? 'Create Consumer Profile' : 'Consumer Profile',
        actions: [
          if (!_isEditing && !_isLoading && _errorMessage == null)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? _buildErrorView()
              : _isEditing
              ? _buildEditProfileView()
              : _buildProfileView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isEditing = true;
                _isNewProfile = true;
                _initializeDefaultValues();
              });
            },
            child: Text('Create Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                _buildProfileAvatar(),
                SizedBox(height: 16),
                // Name
                Text(
                  _userData['name'] ?? 'Consumer',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                // Verified badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 16, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        'Verified Consumer',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Contact Information
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  _infoItem(
                    Icons.phone,
                    'Phone',
                    _userData['phoneNumber'] ?? 'Not provided',
                  ),
                  SizedBox(height: 12),
                  _infoItem(
                    Icons.email,
                    'Email',
                    _userData['email'] ?? 'Not provided',
                  ),
                  SizedBox(height: 12),
                  _infoItem(Icons.location_on, 'Address', _formatAddress()),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Account Information
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  _infoItem(
                    Icons.calendar_today,
                    'Member Since',
                    _formatDate(_userData['createdAt']),
                  ),
                  SizedBox(height: 12),
                  _infoItem(
                    Icons.shopping_cart,
                    'Total Orders',
                    _userData['totalOrders']?.toString() ?? '0',
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEditProfileView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title for new profile
          if (_isNewProfile) ...[
            Center(
              child: Text(
                'Create Your Consumer Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Please fill in your details to get started',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: 24),
          ],

          // Profile image
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    _buildEditProfileAvatar(),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Profile Photo',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Personal Information
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name*',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.person),
                      hintText: 'Enter your full name',
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number*',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.phone),
                      hintText: 'Enter your phone number',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Address Information
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Address Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.home),
                      hintText: 'Enter your street address',
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.location_city),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _stateController,
                          decoration: InputDecoration(
                            labelText: 'State',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.map),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _pincodeController,
                    decoration: InputDecoration(
                      labelText: 'Pincode',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.pin_drop),
                      hintText: 'Enter your pincode',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 32),

          // Save and Cancel buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child:
                      _isSaving
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            _isNewProfile ? 'Create Profile' : 'Save Profile',
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              // Only show Cancel button if not creating a new profile
              if (!_isNewProfile) ...[
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isSaving
                            ? null
                            : () {
                              setState(() {
                                _isEditing = false;
                              });
                            },
                    child: Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      value == 'Not provided'
                          ? FontWeight.normal
                          : FontWeight.bold,
                  color: value == 'Not provided' ? Colors.grey : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatAddress() {
    String location = _userData['location'] ?? '';
    String address = _userData['address'] ?? '';
    String pincode = _userData['pincode'] ?? '';

    List<String> addressParts = [];

    if (address.isNotEmpty) {
      addressParts.add(address);
    }

    if (location.isNotEmpty) {
      addressParts.add(location);
    }

    if (pincode.isNotEmpty) {
      addressParts.add(pincode);
    }

    return addressParts.isEmpty ? 'Not provided' : addressParts.join(', ');
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Not available';

    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      return 'Not available';
    }
  }

  Widget _buildProfileAvatar() {
    Widget avatarWidget;
    if (_userData['profileImageBytes'] != null &&
        (_userData['profileImageBytes'] as String).isNotEmpty) {
      try {
        final bytes = base64Decode(_userData['profileImageBytes']);
        avatarWidget = ClipOval(
          child: Image.memory(
            bytes,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _networkOrDefaultAvatar();
            },
          ),
        );
      } catch (_) {
        avatarWidget = _networkOrDefaultAvatar();
      }
    } else {
      avatarWidget = _networkOrDefaultAvatar();
    }
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.green, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.10),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: avatarWidget,
    );
  }

  Widget _buildEditProfileAvatar() {
    if (_profileImageFile != null) {
      // Show preview of newly picked image
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.green, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.10),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.file(
            _profileImageFile!,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.agriculture,
                size: 60,
                color: Colors.green[700],
              );
            },
          ),
        ),
      );
    }
    // Otherwise, use the same logic as the view mode
    Widget avatarWidget;
    if (_userData['profileImageBytes'] != null &&
        (_userData['profileImageBytes'] as String).isNotEmpty) {
      try {
        final bytes = base64Decode(_userData['profileImageBytes']);
        avatarWidget = ClipOval(
          child: Image.memory(
            bytes,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _networkOrDefaultAvatar();
            },
          ),
        );
      } catch (_) {
        avatarWidget = _networkOrDefaultAvatar();
      }
    } else {
      avatarWidget = _networkOrDefaultAvatar();
    }
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.green, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.10),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: avatarWidget,
    );
  }

  Widget _networkOrDefaultAvatar() {
    if (_userData['profileImageUrl'] != null &&
        (_userData['profileImageUrl'] as String).isNotEmpty) {
      return ClipOval(
        child: FadeInImage.assetNetwork(
          placeholder: 'assets/app_logo.png',
          image: _userData['profileImageUrl'],
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          imageErrorBuilder: (context, error, stackTrace) {
            return Icon(Icons.agriculture, size: 60, color: Colors.green[700]);
          },
        ),
      );
    }
    return Icon(Icons.agriculture, size: 60, color: Colors.green[700]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }
}
