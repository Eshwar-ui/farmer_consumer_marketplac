import 'package:farmer_consumer_marketplace/utils/LogoutButton.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:farmer_consumer_marketplace/widgets/common/app_bar.dart';
import 'package:farmer_consumer_marketplace/services/firebase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class FarmerProfileScreen extends StatefulWidget {
  @override
  _FarmerProfileScreenState createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _isNewProfile = false;
  
  Map<String, dynamic> _farmerData = {};
  
  // Controllers for editing
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _farmSizeController = TextEditingController();
  final TextEditingController _farmTypeController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  File? _profileImageFile;
  
  @override
  void initState() {
    super.initState();
    _loadFarmerProfile();
  }
  
  Future<void> _loadFarmerProfile() async {
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
      
      Map<String, dynamic>? userData = await _firebaseService.getUserProfile();
      
      // Check if user exists and is a farmer
      if (userData == null) {
        setState(() {
          _errorMessage = 'User profile not found. Please create your profile.';
          _isNewProfile = true;
          _isEditing = true;
          _isLoading = false;
          _initializeDefaultValues();
        });
        return;
      }
      
      // Check if user is a farmer
      if (userData['role'] != 'farmer') {
        setState(() {
          _errorMessage = 'This account is not registered as a farmer.';
          _isLoading = false;
        });
        return;
      }
      
      // Get additional farmer data
      Map<String, dynamic>? farmerData = await _firebaseService.getFarmerProfile();
      
      if (farmerData != null && farmerData.isNotEmpty) {
        setState(() {
          _farmerData = farmerData;
          _isLoading = false;
        });
        
        // Set controller values
        _setControllerValues();
      } else {
        // Profile not found - create a new profile
        print('Farmer profile not found, creating a new one');
        setState(() {
          _isNewProfile = true;
          _isEditing = true;
          _isLoading = false;
          
          // Add user data to farmer data
          _farmerData = userData;
          
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
      
      // Pre-fill email in farmerData (readonly)
      _farmerData['email'] = user.email;
    }
    
    // Extract city and state from location if available
    String location = _farmerData['location'] ?? '';
    if (location.isNotEmpty) {
      List<String> parts = location.split(', ');
      if (parts.length >= 1) {
        _cityController.text = parts[0];
      }
      if (parts.length >= 2) {
        _stateController.text = parts[1];
      }
    }
    
    // Set other default values
    _farmTypeController.text = 'Mixed';
    _experienceController.text = '0';
    _farmSizeController.text = '0';
  }
  
  void _setControllerValues() {
    _nameController.text = _farmerData['name'] ?? '';
    _phoneController.text = _farmerData['phoneNumber'] ?? '';
    _addressController.text = _farmerData['address'] ?? '';
    
    // Parse location if it exists (format: "City, State")
    String location = _farmerData['location'] ?? '';
    if (location.isNotEmpty) {
      List<String> parts = location.split(', ');
      if (parts.length >= 1) {
        _cityController.text = parts[0];
      }
      if (parts.length >= 2) {
        _stateController.text = parts[1];
      }
    }
    
    _pincodeController.text = _farmerData['pincode'] ?? '';
    _farmNameController.text = _farmerData['farmName'] ?? '';
    _farmSizeController.text = _farmerData['farmSize']?.toString() ?? '';
    _farmTypeController.text = _farmerData['farmType'] ?? '';
    _experienceController.text = _farmerData['experience']?.toString() ?? '';
    _bioController.text = _farmerData['bio'] ?? '';
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
      String fileName = 'profile_${_firebaseService.currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child('profile_images/$fileName');
      
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
      String? profileImageUrl = _profileImageFile != null 
          ? await _uploadProfileImage() 
          : _farmerData['profileImageUrl'];
      
      // Prepare updated data
      Map<String, dynamic> updatedData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'email': _farmerData['email'],
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'pincode': _pincodeController.text,
        'farmName': _farmNameController.text,
        'farmSize': double.tryParse(_farmSizeController.text) ?? 0,
        'farmType': _farmTypeController.text,
        'experience': int.tryParse(_experienceController.text) ?? 0,
        'bio': _bioController.text,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      // Add profile pic URL if available
      if (profileImageUrl != null) {
        updatedData['profilePic'] = profileImageUrl;
      }
      
      // For new profiles, add creation timestamp
      if (_isNewProfile) {
        updatedData['createdAt'] = DateTime.now().toIso8601String();
        updatedData['totalProducts'] = 0;
        updatedData['totalSales'] = 0;
        updatedData['rating'] = 0.0;
      }
      
      // Save to Firebase
      bool success = await _firebaseService.updateFarmerProfile(updatedData);
      
      if (success) {
        // Reload profile
        setState(() {
          _isNewProfile = false;
        });
        await _loadFarmerProfile();
        
        // Exit edit mode
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile ${_isNewProfile ? 'created' : 'updated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to ${_isNewProfile ? 'create' : 'update'} profile');
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
        title: _isNewProfile ? 'Create Farmer Profile' : 'Farmer Profile',
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
            LogoutButton(),
        ],
      ),
      body: _isLoading
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
              backgroundColor: Colors.green,
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
                // Profile image
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green,
                      width: 3,
                    ),
                    image: _farmerData['profileImageUrl'] != null
                        ? DecorationImage(
                            image: NetworkImage(_farmerData['profileImageUrl']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _farmerData['profileImageUrl'] == null
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey[400],
                        )
                      : null,
                ),
                SizedBox(height: 16),
                // Name
                Text(
                  _farmerData['name'] ?? 'Farmer',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                // Farm name
                if (_farmerData['farmName'] != null && _farmerData['farmName'].isNotEmpty)
                  Text(
                    _farmerData['farmName'],
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                  ),
                SizedBox(height: 8),
                // Verified badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.green,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Verified Farmer',
                        style: TextStyle(
                          color: Colors.green[800],
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
          
          // Bio
          if (_farmerData['bio'] != null && _farmerData['bio'].isNotEmpty) ...[
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
                      'About Me',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _farmerData['bio'],
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
          
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _infoItem(
                    Icons.phone,
                    'Phone',
                    _farmerData['phoneNumber'] ?? _farmerData['phone'] ?? 'Not provided',
                  ),
                  SizedBox(height: 12),
                  _infoItem(
                    Icons.email,
                    'Email',
                    _farmerData['email'] ?? 'Not provided',
                  ),
                  SizedBox(height: 12),
                  _infoItem(
                    Icons.location_on,
                    'Address',
                    _formatAddress(),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Farm Information
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
                    'Farm Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _infoItem(
                    Icons.agriculture,
                    'Farm Name',
                    _farmerData['farmName'] ?? 'Not provided',
                  ),
                  SizedBox(height: 12),
                  _infoItem(
                    Icons.landscape,
                    'Farm Size',
                    _farmerData['farmSize'] != null
                        ? '${_farmerData['farmSize']} acres'
                        : 'Not provided',
                  ),
                  SizedBox(height: 12),
                  _infoItem(
                    Icons.eco,
                    'Farm Type',
                    _farmerData['farmType'] ?? 'Not provided',
                  ),
                  SizedBox(height: 12),
                  _infoItem(
                    Icons.history,
                    'Farming Experience',
                    _farmerData['experience'] != null
                        ? '${_farmerData['experience']} years'
                        : 'Not provided',
                  ),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _infoItem(
                    Icons.calendar_today,
                    'Member Since',
                    _formatDate(_farmerData['createdAt']),
                  ),
                  SizedBox(height: 12),
                  _infoItem(
                    Icons.star,
                    'Rating',
                    _farmerData['rating'] != null
                        ? '${_farmerData['rating']} / 5.0'
                        : 'No ratings yet',
                  ),
                  SizedBox(height: 12),
                  _infoItem(
                    Icons.shopping_basket,
                    'Total Products',
                    _farmerData['totalProducts']?.toString() ?? '0',
                  ),
                  SizedBox(height: 12),
                  _infoItem(
                    Icons.shopping_cart,
                    'Total Sales',
                    _farmerData['totalSales']?.toString() ?? '0',
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
                'Create Your Farmer Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Please fill in your details to get started',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
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
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green,
                          width: 3,
                        ),
                        image: _profileImageFile != null
                            ? DecorationImage(
                                image: FileImage(_profileImageFile!),
                                fit: BoxFit.cover,
                              )
                            : _farmerData['profileImageUrl'] != null
                                ? DecorationImage(
                                    image: NetworkImage(_farmerData['profileImageUrl']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: _profileImageFile == null && _farmerData['profileImageUrl'] == null
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey[400],
                            )
                          : null,
                    ),
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
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
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
                      color: Colors.green[800],
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
                  SizedBox(height: 12),
                  TextField(
                    controller: _bioController,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: 'Tell us about yourself and your farming practices',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
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
                      color: Colors.green[800],
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
          
          SizedBox(height: 16),
          
          // Farm Information
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
                    'Farm Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _farmNameController,
                    decoration: InputDecoration(
                      labelText: 'Farm Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.agriculture),
                      hintText: 'Enter your farm name',
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _farmSizeController,
                    decoration: InputDecoration(
                      labelText: 'Farm Size (acres)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.landscape),
                      hintText: 'Enter farm size in acres',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _farmTypeController,
                    decoration: InputDecoration(
                      labelText: 'Farm Type',
                      hintText: 'e.g., Organic, Conventional, Mixed',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.eco),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _experienceController,
                    decoration: InputDecoration(
                      labelText: 'Farming Experience (years)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.history),
                      hintText: 'Enter years of farming experience',
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
                  child: _isSaving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isNewProfile ? 'Create Profile' : 'Save Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
                    onPressed: _isSaving
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
            color: Colors.green[50],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.green,
            size: 20,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: value == 'Not provided' ? FontWeight.normal : FontWeight.bold,
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
    List<String> addressParts = [];
    
    if (_farmerData['address'] != null && _farmerData['address'].isNotEmpty) {
      addressParts.add(_farmerData['address']);
    }
    
    if (_farmerData['location'] != null && _farmerData['location'].isNotEmpty) {
      addressParts.add(_farmerData['location']);
    } else {
      if (_farmerData['city'] != null && _farmerData['city'].isNotEmpty) {
        addressParts.add(_farmerData['city']);
      }
      
      if (_farmerData['state'] != null && _farmerData['state'].isNotEmpty) {
        addressParts.add(_farmerData['state']);
      }
    }
    
    if (_farmerData['pincode'] != null && _farmerData['pincode'].isNotEmpty) {
      addressParts.add(_farmerData['pincode']);
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
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _farmNameController.dispose();
    _farmSizeController.dispose();
    _farmTypeController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}