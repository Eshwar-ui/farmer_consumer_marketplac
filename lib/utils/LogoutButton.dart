import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farmer_consumer_marketplace/services/auth_service.dart';
import 'package:farmer_consumer_marketplace/screens/auth/login_screen.dart';

class LogoutButton extends StatelessWidget {
  final bool showIcon;
  final String? label;
  final Color? color;
  
  const LogoutButton({
    Key? key,
    this.showIcon = true,
    this.label,
    this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Determine if this is an icon button or a text button
    if (label == null) {
      return IconButton(
        icon: Icon(Icons.logout),
        color: color ?? Colors.white,
        tooltip: 'Logout',
        onPressed: () => _confirmLogout(context, authService),
      );
    } else {
      return TextButton.icon(
        onPressed: () => _confirmLogout(context, authService),
        icon: showIcon ? Icon(Icons.logout) : SizedBox.shrink(),
        label: Text(label!),
        style: TextButton.styleFrom(
          foregroundColor: color ?? Colors.red,
        ),
      );
    }
  }
  
  Future<void> _confirmLogout(BuildContext context, AuthService authService) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout Confirmation'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Logout'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirm) {
      _performLogout(context, authService);
    }
  }
  
  Future<void> _performLogout(BuildContext context, AuthService authService) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Perform logout
      await authService.signOut();
      
      // Remove loading indicator
      Navigator.of(context).pop();
      
      // Navigate to login screen and clear all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      // Remove loading indicator
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}