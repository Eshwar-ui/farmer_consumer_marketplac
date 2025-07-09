import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmer_consumer_marketplace/models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _currentUser;
  
  // Get current user
  UserModel? get currentUser => _currentUser;
  
  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Initialize service
Future<void> initialize() async {
  // Check if already logged in on app start
  final User? currentUser = _auth.currentUser;
  if (currentUser != null) {
    // Fetch user data from Firestore
    _currentUser = await _getUserData(currentUser.uid);
    notifyListeners();
  }

  // Set up listener for future auth changes
  _auth.authStateChanges().listen((User? user) async {
    if (user != null) {
      // Only fetch user data if not already loaded
      if (_currentUser == null || _currentUser!.id != user.uid) {
        _currentUser = await _getUserData(user.uid);
        notifyListeners();
      }
    } else {
      _currentUser = null;
      notifyListeners();
    }
  });
}
  
  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
  try {
    final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (userCredential.user != null) {
      // Make sure we wait for the user data to be loaded
      final userData = await _getUserData(userCredential.user!.uid);
      _currentUser = userData;
      notifyListeners();
      return userData;
    }
    return null;
  } catch (e) {
    print('Sign in error: $e');
    rethrow;
  }
}
  
  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String phoneNumber,
    UserRole role,
    String location,
  ) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Create user document in Firestore
        final userId = userCredential.user!.uid;
        final newUser = UserModel(
          id: userId,
          name: name,
          email: email,
          phoneNumber: phoneNumber,
          role: role,
          location: location,
        );
        
        await _firestore.collection('users').doc(userId).set(newUser.toJson());
        
        _currentUser = newUser;
        notifyListeners();
        return newUser;
      }
      return null;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  
  
  // Get user data from Firestore
  Future<UserModel?> _getUserData(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Get user data error: $e');
      rethrow;
    }
  }
  
  // Get current user data
  Future<UserModel?> getCurrentUser() async {
    try {
      final User? user = _auth.currentUser;
      
      if (user != null) {
        if (_currentUser != null) {
          return _currentUser;
        }
        
        final userData = await _getUserData(user.uid);
        _currentUser = userData;
        notifyListeners();
        return userData;
      }
      return null;
    } catch (e) {
      print('Get current user error: $e');
      rethrow;
    }
  }
  
  // Update user profile
  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      await _firestore.collection('users').doc(updatedUser.id).update(updatedUser.toJson());
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Update user profile error: $e');
      rethrow;
    }
  }

  
  
  // Upload profile image
  Future<String> uploadProfileImage(String imagePath) async {
    try {
      // In a real implementation, this would use Firebase Storage
      // For this example, we'll return a placeholder image URL
      
      // Simulate network delay
      await Future.delayed(Duration(seconds: 1));
      
      return 'https://example.com/profile_image.jpg';
    } catch (e) {
      print('Upload profile image error: $e');
      rethrow;
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    }
  }
  
  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final User? user = _auth.currentUser;
      
      if (user != null && user.email != null) {
        // Re-authenticate user
        final AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        
        await user.reauthenticateWithCredential(credential);
        
        // Change password
        await user.updatePassword(newPassword);
      } else {
        throw Exception('User not authenticated');
      }
    } catch (e) {
      print('Change password error: $e');
      rethrow;
    }
  }
  
  // Check if email exists
  Future<bool> checkEmailExists(String email) async {
    try {
      final List<String> methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print('Check email error: $e');
      rethrow;
    }
  }
}