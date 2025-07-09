import 'package:flutter/material.dart';
import 'package:farmer_consumer_marketplace/widgets/common/weather_Screen.dart';
import 'package:farmer_consumer_marketplace/screens/auth/login_screen.dart';
import 'package:farmer_consumer_marketplace/screens/auth/register_screen.dart';
import 'package:farmer_consumer_marketplace/screens/auth/profile_screen.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/farmer_dashboard.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/inventory_management.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/price_analysis.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/market_trend_analysis.dart';
import 'package:farmer_consumer_marketplace/screens/consumer/consumer_dashboard.dart';
import 'package:farmer_consumer_marketplace/screens/consumer/marketplace_view.dart';
import 'package:farmer_consumer_marketplace/screens/consumer/search_filter.dart';
import 'package:farmer_consumer_marketplace/screens/consumer/transaction_history.dart';
import 'package:farmer_consumer_marketplace/screens/consumer/market_price_viewer.dart';
import 'package:farmer_consumer_marketplace/models/user_model.dart';

// Route names
const String loginRoute = '/login';
const String registerRoute = '/register';
const String profileRoute = '/profile';
const String farmerDashboardRoute = '/farmer/dashboard';
const String inventoryManagementRoute = '/farmer/inventory';
const String priceAnalysisRoute = '/farmer/price-analysis';
const String weatherScreenRoute = '/farmer/weather';
const String marketTrendAnalysisRoute = '/farmer/market-trends';
const String consumerDashboardRoute = '/consumer/dashboard';
const String marketplaceViewRoute = '/consumer/marketplace';
const String searchFilterRoute = '/consumer/search';
const String transactionHistoryRoute = '/consumer/transactions';
const String marketPriceViewerRoute = '/consumer/market-prices';

// Route map
final Map<String, WidgetBuilder> appRoutes = {
  loginRoute: (context) => LoginScreen(),
  registerRoute: (context) => RegisterScreen(),
  profileRoute: (context) => ProfileScreen(),
  weatherScreenRoute: (context) => WeatherScreen(),
};

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Default error route
    Route<dynamic> _errorRoute() {
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('Route not found!'),
          ),
        ),
      );
    }

    // Getting arguments passed in while calling Navigator.pushNamed
    final args = settings.arguments;

    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case registerRoute:
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case profileRoute:
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      
      case farmerDashboardRoute:
        // Check if args is a UserModel
        if (args is UserModel) {
          return MaterialPageRoute(
            builder: (_) => FarmerDashboard(user: args),
          );
        }
        return _errorRoute();
      
      case inventoryManagementRoute:
        return MaterialPageRoute(builder: (_) => InventoryManagement());
      
      case priceAnalysisRoute:
        return MaterialPageRoute(builder: (_) => PriceAnalysis());
      
      case weatherScreenRoute:
        return MaterialPageRoute(builder: (_) => WeatherScreen());
      
      case marketTrendAnalysisRoute:
        return MaterialPageRoute(builder: (_) => MarketTrendAnalysis());
      
      case consumerDashboardRoute:
        // Check if args is a UserModel
        if (args is UserModel) {
          return MaterialPageRoute(
            builder: (_) => ConsumerDashboard(user: args),
          );
        }
        return _errorRoute();
      
      case marketplaceViewRoute:
        return MaterialPageRoute(builder: (_) => MarketplaceView());
      
      case searchFilterRoute:
        return MaterialPageRoute(builder: (_) => SearchFilter());
      
      case transactionHistoryRoute:
        return MaterialPageRoute(builder: (_) => TransactionHistory());
      
      case marketPriceViewerRoute:
        return MaterialPageRoute(builder: (_) => MarketPriceViewer());
      
      default:
        return _errorRoute();
    }
  }
}