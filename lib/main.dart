import 'package:farmer_consumer_marketplace/screens/consumer/consumer_dashboard.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/farmer_dashboard.dart';
import 'package:farmer_consumer_marketplace/widgets/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:farmer_consumer_marketplace/services/auth_service.dart';
import 'package:farmer_consumer_marketplace/screens/auth/login_screen.dart';
import 'package:farmer_consumer_marketplace/utils/app_colors.dart';
import 'package:farmer_consumer_marketplace/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthService()..initialize(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Farmer-Consumer Marketplace',
        theme: ThemeData(
          primarySwatch: Colors.green,
          primaryColor: AppColors.primaryColor,
          scaffoldBackgroundColor: AppColors.scaffoldBackground,
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.primaryColor,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              // primary: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              // primary: AppColors.primaryColor,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
          ),
        ),
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return StreamBuilder(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            // Show splash screen while checking auth state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SplashScreen();
            }

            // If authenticated
            if (snapshot.hasData) {
              // Check if user data is loaded
              if (authService.currentUser != null) {
                // Redirect based on user role
                if (authService.currentUser!.role == UserRole.farmer) {
                  return FarmerDashboard(user: authService.currentUser!);
                } else {
                  return ConsumerDashboard(user: authService.currentUser!);
                }
              } else {
                // User authenticated but data not loaded yet
                return SplashScreen();
              }
            }

            // Not authenticated
            return LoginScreen();
          },
        );
      },
    );
  }
}
