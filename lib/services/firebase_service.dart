import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Expose Firestore instance through a getter
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is logged in
  bool get isUserLoggedIn => _auth.currentUser != null;



  // // Update farmer profile
  // Future<bool> updateFarmerProfile(Map<String, dynamic> data) async {
  //   try {
  //     if (currentUserId == null) return false;

  //     await _firestore.collection('farmers').doc(currentUserId).update(data);
  //     return true;
  //   } catch (e) {
  //     print('Error updating farmer profile: $e');
  //     return false;
  //   }
  // }
Future<List<Map<String, dynamic>>> getFarmerInventory() async {
  try {
    if (currentUserId == null) return [];

    QuerySnapshot snapshot = await _firestore
        .collection('inventory')
        .where('farmerId', isEqualTo: currentUserId)
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      
      // Ensure numeric values are properly converted to doubles for consistency
      if (data['quantity'] != null) {
        data['quantity'] = double.parse(data['quantity'].toString());
      }
      
      if (data['unitPrice'] != null) {
        data['unitPrice'] = double.parse(data['unitPrice'].toString());
      }
      
      if (data['totalValue'] != null) {
        data['totalValue'] = double.parse(data['totalValue'].toString());
      } else if (data['unitPrice'] != null && data['quantity'] != null) {
        // Calculate total value if not present
        data['totalValue'] = (data['unitPrice'] as double) * (data['quantity'] as double);
      }
      
      return data;
    }).toList();
  } catch (e) {
    print('Error getting farmer inventory: $e');
    return [];
  }
}

  // Add inventory item
  Future<bool> addInventoryItem(Map<String, dynamic> item) async {
    try {
      if (currentUserId == null) return false;

      // Add additional fields
      item['farmerId'] = currentUserId;
      item['createdAt'] = FieldValue.serverTimestamp();
      item['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('inventory').add(item);
      return true;
    } catch (e) {
      print('Error adding inventory item: $e');
      return false;
    }
  }

  // Update inventory item
  Future<bool> updateInventoryItem(String itemId, Map<String, dynamic> data) async {
    try {
      if (currentUserId == null) return false;

      // Add update timestamp
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('inventory').doc(itemId).update(data);
      return true;
    } catch (e) {
      print('Error updating inventory item: $e');
      return false;
    }
  }

  // Delete inventory item
  Future<bool> deleteInventoryItem(String itemId) async {
    try {
      if (currentUserId == null) return false;

      await _firestore.collection('inventory').doc(itemId).delete();
      return true;
    } catch (e) {
      print('Error deleting inventory item: $e');
      return false;
    }
  }

  // Get recent sales
  Future<List<Map<String, dynamic>>> getRecentSales({int limit = 3}) async {
    try {
      if (currentUserId == null) return [];

      final snapshot = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'completed')
          .orderBy('orderDate', descending: true)
          .limit(limit)
          .get();
      
      List<Map<String, dynamic>> sales = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Format the sales data
        sales.add({
          'product': data['productName'] ?? 'Unknown Product',
          'quantity': '${data['quantity'] ?? 0} ${data['unit'] ?? 'items'}',
          'price': '₹${NumberFormat('#,##0').format(data['totalAmount'] ?? 0)}',
          'date': data['orderDate'] ?? 'Unknown Date',
        });
      }
      
      return sales;
    } catch (e) {
      print('Error getting recent sales: $e');
      return [];
    }
  }


// Add this method to your FirebaseService class
Future<Map<String, dynamic>> getTotalRevenueData() async {
  try {
    print('Total Revenue: Starting...');
    
    if (currentUserId == null) {
      print('Total Revenue: User not logged in (currentUserId is null)');
      return {
        'hasData': false,
        'message': 'User not logged in',
        'totalRevenue': 0.0,
        'monthlyRevenue': [],
      };
    }

    print('Total Revenue: Querying for seller ID: $currentUserId');

    // Get all completed orders for this seller (regardless of date)
    QuerySnapshot snapshot = await _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'completed')
        .get();
    
    print('Total Revenue: Found ${snapshot.docs.length} completed orders');
    
    if (snapshot.docs.isEmpty) {
      return {
        'hasData': false,
        'message': 'No completed orders found. Revenue data will appear once you have sales.',
        'totalRevenue': 0.0,
        'monthlyRevenue': [],
      };
    }

    // Initialize for tracking revenue by month
    Map<String, double> monthlyRevenueMap = {};
    double totalRevenue = 0.0;
    
    for (var doc in snapshot.docs) {
      try {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('Total Revenue: Processing order: ${doc.id}');
        
        // Parse amount
        double orderAmount = 0.0;
        if (data['totalAmount'] != null) {
          try {
            orderAmount = double.parse(data['totalAmount'].toString());
          } catch (e) {
            print('Total Revenue: Error parsing amount: $e');
            // Try to parse as int
            try {
              int intAmount = int.parse(data['totalAmount'].toString());
              orderAmount = intAmount.toDouble();
            } catch (e) {
              print('Total Revenue: Failed to parse amount: ${data['totalAmount']}');
            }
          }
        }
        
        // Add to total
        totalRevenue += orderAmount;
        print('Total Revenue: Order amount: ₹$orderAmount, Running total: ₹$totalRevenue');
        
        // Group by month (if order date is available)
        if (data['orderDate'] != null) {
          try {
            // Parse order date
            DateTime orderDate = DateFormat('yyyy-MM-dd').parse(data['orderDate']);
            String monthYear = DateFormat('MMM yyyy').format(orderDate); // e.g., "Apr 2025"
            
            // Add to monthly total
            if (!monthlyRevenueMap.containsKey(monthYear)) {
              monthlyRevenueMap[monthYear] = 0.0;
            }
            monthlyRevenueMap[monthYear] = (monthlyRevenueMap[monthYear] ?? 0.0) + orderAmount;
            print('Total Revenue: Added ₹$orderAmount to $monthYear');
          } catch (e) {
            print('Total Revenue: Error parsing date: $e');
          }
        } else {
          // If no date, add to "Unknown" category
          String unknown = "Unknown";
          if (!monthlyRevenueMap.containsKey(unknown)) {
            monthlyRevenueMap[unknown] = 0.0;
          }
          monthlyRevenueMap[unknown] = (monthlyRevenueMap[unknown] ?? 0.0) + orderAmount;
        }
      } catch (e) {
        print('Total Revenue: Error processing order: $e');
      }
    }

    // Convert monthly map to list for the chart
    List<Map<String, dynamic>> monthlyRevenue = monthlyRevenueMap.entries.map((entry) {
      return {
        'month': entry.key,
        'amount': entry.value,
      };
    }).toList();
    
    // Sort by month in chronological order
    monthlyRevenue.sort((a, b) {
      // If either is "Unknown", handle special case
      if (a['month'] == "Unknown") return 1;  // Unknown goes at the end
      if (b['month'] == "Unknown") return -1;
      
      // Try to parse dates for comparison
      try {
        DateTime dateA = DateFormat('MMM yyyy').parse(a['month']);
        DateTime dateB = DateFormat('MMM yyyy').parse(b['month']);
        return dateA.compareTo(dateB);
      } catch (e) {
        // If parsing fails, sort alphabetically
        return a['month'].compareTo(b['month']);
      }
    });

    print('Total Revenue: Total all-time revenue: ₹$totalRevenue');
    print('Total Revenue: Monthly breakdown: $monthlyRevenue');

    return {
      'hasData': true,
      'totalRevenue': totalRevenue,
      'monthlyRevenue': monthlyRevenue,
    };
  } catch (e) {
    print('Total Revenue: Error getting revenue data: $e');
    return {
      'hasData': false,
      'message': 'Error: $e',
      'totalRevenue': 0.0,
      'monthlyRevenue': [],
    };
  }
}

  // Get all available products
  Future<List<Map<String, dynamic>>> getAllAvailableProducts() async {
    try {
      // Query the inventory collection for products with quantity > 0
      QuerySnapshot snapshot = await _firestore
          .collection('inventory')
          .where('status', isEqualTo: 'In Stock')
          .where('quantity', isGreaterThan: 0)
          .get();

      List<Map<String, dynamic>> products = [];
      
      // Process each document
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Get farmer details
        if (data['farmerId'] != null) {
          DocumentSnapshot farmerDoc = await _firestore
              .collection('users')
              .doc(data['farmerId'])
              .get();
          
          if (farmerDoc.exists) {
            Map<String, dynamic> farmerData = farmerDoc.data() as Map<String, dynamic>;
            data['farmerName'] = farmerData['name'] ?? 'Unknown Farmer';
            data['farmerLocation'] = farmerData['location'] ?? 'Unknown Location';
          }
        }
        
        products.add(data);
      }
      
      return products;
    } catch (e) {
      print('Error getting available products: $e');
      return [];
    }
  }

  // Get product details
  Future<Map<String, dynamic>?> getProductDetails(String productId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('inventory')
          .doc(productId)
          .get();
      
      if (!doc.exists) return null;
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      
      // Get farmer details
      if (data['farmerId'] != null) {
        DocumentSnapshot farmerDoc = await _firestore
            .collection('users')
            .doc(data['farmerId'])
            .get();
        
        if (farmerDoc.exists) {
          Map<String, dynamic> farmerData = farmerDoc.data() as Map<String, dynamic>;
          data['farmerName'] = farmerData['name'] ?? 'Unknown Farmer';
          data['farmerLocation'] = farmerData['location'] ?? 'Unknown Location';
          data['farmerPhone'] = farmerData['phoneNumber'] ?? 'N/A';
        }
      }
      
      return data;
    } catch (e) {
      print('Error getting product details: $e');
      return null;
    }
  }

  // Get products by search query
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      // In a real app, you'd use full-text search or Algolia
      // For simplicity, we'll just query local data
      
      QuerySnapshot snapshot = await _firestore
          .collection('inventory')
          .where('status', isEqualTo: 'In Stock')
          .where('quantity', isGreaterThan: 0)
          .get();
      
      List<Map<String, dynamic>> products = [];
      
      // Filter documents by name or category containing the query
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String name = (data['name'] ?? '').toString().toLowerCase();
        String category = (data['category'] ?? '').toString().toLowerCase();
        
        if (name.contains(query.toLowerCase()) || 
            category.contains(query.toLowerCase())) {
          data['id'] = doc.id;
          products.add(data);
        }
      }
      
      return products;
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  // Email notification function
  Future<bool> sendEmailNotification({
    required String recipientEmail,
    required String subject,
    required String body,
  }) async {
    try {
      // In a real app, you would use a cloud function or backend service
      // to send emails. This is a simplified example using an API
      
      // This URL would be your actual email sending endpoint
      final Uri url = Uri.parse('https://api.youremailservice.com/send');

      // Make the POST request to the email service
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_KEY', // Replace with your actual API key
        },
        body: jsonEncode(<String, String>{
          'to': recipientEmail,
          'subject': subject,
          'body': body,
        }),
      );

      if (response.statusCode == 200) {
        print('Email sent successfully');
        return true;
      } else {
        print('Failed to send email: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }

  // Place an order
  Future<bool> placeOrder({
    required String userId,
    required String productId,
    required String farmerId,
    required String productName,
    required int quantity,
    required String unit,
    required double unitPrice,
    required double totalAmount,
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    try {
      if (userId == null) return false;
      
      // Get current timestamp
      final now = FieldValue.serverTimestamp();
      // Use regular Timestamp for array items
      final Timestamp regularTimestamp = Timestamp.now();
      
      // Initial status history entry - using regular Timestamp
      final initialStatusUpdate = {
        'status': 'pending',
        'timestamp': regularTimestamp, // Use regular Timestamp, not FieldValue
        'updatedBy': userId, // Customer placed the order
      };
      
      // Create order document
      Map<String, dynamic> orderData = {
        'buyerId': userId,
        'sellerId': farmerId,
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
        'totalAmount': totalAmount,
        'deliveryAddress': deliveryAddress,
        'paymentMethod': paymentMethod,
        'status': 'pending',
        'orderDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'createdAt': now,
        'statusHistory': [initialStatusUpdate], // Initialize status history
      };
      
      // Add to main orders collection
      DocumentReference orderRef = await _firestore.collection('orders').add(orderData);
      
      // Get the order ID
      String orderId = orderRef.id;
      
      // Add order ID to the data
      orderData['id'] = orderId;
      
      // Also add to buyer's orders collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId)
          .set(orderData);
      
      // Also add to seller's orders collection
      await _firestore
          .collection('users')
          .doc(farmerId)
          .collection('orders')
          .doc(orderId)
          .set(orderData);
      
      // Update inventory quantity
      DocumentSnapshot productDoc = await _firestore
          .collection('inventory')
          .doc(productId)
          .get();
      
      if (productDoc.exists) {
        Map<String, dynamic> productData = productDoc.data() as Map<String, dynamic>;
        int currentQuantity = productData['quantity'] ?? 0;
        
        if (currentQuantity >= quantity) {
          await _firestore.collection('inventory').doc(productId).update({
            'quantity': currentQuantity - quantity,
            'updatedAt': now,
            // If quantity becomes 0, update status to "Out of Stock"
            'status': (currentQuantity - quantity <= 0) ? 'Out of Stock' : 'In Stock',
          });
          
          // Get buyer details for the notification
          DocumentSnapshot buyerDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();
          
          String buyerName = 'Customer';
          String buyerPhone = 'N/A';
          
          if (buyerDoc.exists) {
            Map<String, dynamic> buyerData = buyerDoc.data() as Map<String, dynamic>;
            buyerName = buyerData['name'] ?? 'Customer';
            buyerPhone = buyerData['phoneNumber'] ?? 'N/A';
          }
          
          // Get seller details for email notification
          DocumentSnapshot sellerDoc = await _firestore
              .collection('users')
              .doc(farmerId)
              .get();
          
          String sellerEmail = '';
          String sellerName = 'Farmer';
          
          if (sellerDoc.exists) {
            Map<String, dynamic> sellerData = sellerDoc.data() as Map<String, dynamic>;
            sellerEmail = sellerData['email'] ?? '';
            sellerName = sellerData['name'] ?? 'Farmer';
          }
          
          // If seller has email, send notification
          if (sellerEmail.isNotEmpty) {
            // Format date for email
            String formattedDate = DateFormat('MMMM d, yyyy').format(DateTime.now());
            
            // Prepare email content
            String emailSubject = 'New Order Received: $productName';
            String emailBody = '''
Dear $sellerName,

You have received a new order on Farmer Consumer Marketplace!

Order Details:
- Order ID: $orderId
- Product: $productName
- Quantity: $quantity $unit
- Unit Price: ₹${unitPrice.toStringAsFixed(2)}
- Total Amount: ₹${totalAmount.toStringAsFixed(2)}
- Payment Method: $paymentMethod
- Order Date: $formattedDate

Customer Details:
- Name: $buyerName
- Phone: $buyerPhone
- Delivery Address: $deliveryAddress

Please login to your account to process this order.

Thank you for using our marketplace!

Best Regards,
Farmer Consumer Marketplace Team
            ''';
            
            // Send email notification
            await sendEmailNotification(
              recipientEmail: sellerEmail,
              subject: emailSubject,
              body: emailBody,
            );
          }
          
          // Add notification for the seller in Firestore
          await _firestore.collection('notifications').add({
            'userId': farmerId,
            'title': 'New Order Received',
            'message': 'You have received a new order for $quantity $unit of $productName.',
            'orderId': orderId,
            'type': 'new_order',
            'isRead': false,
            'createdAt': now,
          });
          
          return true;
        } else {
          // Insufficient quantity available
          await _firestore.collection('orders').doc(orderId).delete();
          
          // Also clean up the user collections
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('orders')
              .doc(orderId)
              .delete();
              
          await _firestore
              .collection('users')
              .doc(farmerId)
              .collection('orders')
              .doc(orderId)
              .delete();
              
          return false;
        }
      } else {
        // Product not found
        await _firestore.collection('orders').doc(orderId).delete();
        
        // Also clean up the user collections
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('orders')
            .doc(orderId)
            .delete();
            
        await _firestore
            .collection('users')
            .doc(farmerId)
            .collection('orders')
            .doc(orderId)
            .delete();
        
        return false;
      }
    } catch (e) {
      print('Error placing order: $e');
      return false;
    }
  }

  // Get buyer orders directly from user's collection
  Future<List<Map<String, dynamic>>> getBuyerOrders(String userId, {int limit = 20}) async {
    try {
      if (userId == null) return [];
      
      // Query from the user's orders collection directly
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      List<Map<String, dynamic>> orders = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Add seller name if not already in the data
        if (data['sellerName'] == null && data['sellerId'] != null) {
          final sellerDoc = await _firestore
              .collection('users')
              .doc(data['sellerId'])
              .get();
          
          if (sellerDoc.exists) {
            Map<String, dynamic> sellerData = sellerDoc.data() as Map<String, dynamic>;
            data['sellerName'] = sellerData['name'] ?? 'Unknown Seller';
          }
        }
        
        orders.add(data);
      }
      
      return orders;
    } catch (e) {
      print('Error getting buyer orders: $e');
      return [];
    }
  }

  // Get seller orders directly from user's collection
  Future<List<Map<String, dynamic>>> getSellerOrders(String sellerId, {int limit = 20}) async {
    try {
      if (sellerId == null) return [];
      
      // Query from the seller's orders collection directly
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(sellerId)
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      List<Map<String, dynamic>> orders = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Add buyer name if not already in the data
        if (data['buyerName'] == null && data['buyerId'] != null) {
          final buyerDoc = await _firestore
              .collection('users')
              .doc(data['buyerId'])
              .get();
          
          if (buyerDoc.exists) {
            Map<String, dynamic> buyerData = buyerDoc.data() as Map<String, dynamic>;
            data['buyerName'] = buyerData['name'] ?? 'Unknown Buyer';
            data['buyerPhone'] = buyerData['phoneNumber'] ?? 'N/A';
          }
        }
        
        orders.add(data);
      }
      
      return orders;
    } catch (e) {
      print('Error getting seller orders: $e');
      return [];
    }
  }

  // Update order status with timestamp
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      if (currentUserId == null) return false;
      
      // Get current timestamp
      final now = FieldValue.serverTimestamp();
      // Use regular Timestamp for array items
      final Timestamp regularTimestamp = Timestamp.now();
      
      // Get the order first to get buyer and seller IDs
      DocumentSnapshot orderDoc = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();
      
      if (!orderDoc.exists) return false;
      
      Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
      String buyerId = orderData['buyerId'];
      String sellerId = orderData['sellerId'];
      
      // Create a status update history entry
      final statusUpdate = {
        'status': newStatus,
        'timestamp': regularTimestamp, // Use regular Timestamp, not FieldValue
        'updatedBy': currentUserId,
      };
      
      // Update in main orders collection
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': now,
        'statusHistory': FieldValue.arrayUnion([statusUpdate]),
      });
      
      // Update in buyer's orders collection
      await _firestore
          .collection('users')
          .doc(buyerId)
          .collection('orders')
          .doc(orderId)
          .update({
            'status': newStatus,
            'updatedAt': now,
            'statusHistory': FieldValue.arrayUnion([statusUpdate]),
          });
      
      // Update in seller's orders collection
      await _firestore
          .collection('users')
          .doc(sellerId)
          .collection('orders')
          .doc(orderId)
          .update({
            'status': newStatus,
            'updatedAt': now,
            'statusHistory': FieldValue.arrayUnion([statusUpdate]),
          });
      
      // Get order details for notification
      String productName = orderData['productName'] ?? 'Your order';
      
      // Add notification for the buyer
      await _firestore.collection('notifications').add({
        'userId': buyerId,
        'title': 'Order Status Updated',
        'message': 'Your order for $productName has been updated to: $newStatus.',
        'orderId': orderId,
        'type': 'order_update',
        'isRead': false,
        'createdAt': now,
      });
      
      return true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId) async {
    try {
      if (currentUserId == null) return false;
      
      // Get current timestamp
      final now = FieldValue.serverTimestamp();
      // Use regular Timestamp for array items
      final Timestamp regularTimestamp = Timestamp.now();
      
      // Get order data
      DocumentSnapshot orderDoc = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();
      
      if (!orderDoc.exists) return false;
      
      Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
      String buyerId = orderData['buyerId'];
      String sellerId = orderData['sellerId'];
      
      // Only allow cancellation if order is pending
      if (orderData['status'] != 'pending') {
        return false;
      }
      
      // Create a status update history entry for cancellation
      final statusUpdate = {
        'status': 'cancelled',
        'timestamp': regularTimestamp, // Use regular Timestamp, not FieldValue
        'updatedBy': currentUserId,
        'reason': 'Cancelled by user', // Optional: could add cancellation reason parameter
      };
      
      // Update in main orders collection
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled',
        'updatedAt': now,
        'statusHistory': FieldValue.arrayUnion([statusUpdate]),
      });
      
      // Update in buyer's orders collection
      await _firestore
          .collection('users')
          .doc(buyerId)
          .collection('orders')
          .doc(orderId)
          .update({
            'status': 'cancelled',
            'updatedAt': now,
            'statusHistory': FieldValue.arrayUnion([statusUpdate]),
          });
      
      // Update in seller's orders collection
      await _firestore
          .collection('users')
          .doc(sellerId)
          .collection('orders')
          .doc(orderId)
          .update({
            'status': 'cancelled',
            'updatedAt': now,
            'statusHistory': FieldValue.arrayUnion([statusUpdate]),
          });
      
      // Return product to inventory
      String productId = orderData['productId'];
      int quantity = orderData['quantity'] ?? 0;
      
      if (productId != null && quantity > 0) {
        DocumentSnapshot productDoc = await _firestore
            .collection('inventory')
            .doc(productId)
            .get();
        
        if (productDoc.exists) {
          Map<String, dynamic> productData = productDoc.data() as Map<String, dynamic>;
          int currentQuantity = productData['quantity'] ?? 0;
          
          await _firestore.collection('inventory').doc(productId).update({
            'quantity': currentQuantity + quantity,
            'status': 'In Stock',
            'updatedAt': now,
          });
        }
      }
      
      // Add notification for the seller
      String productName = orderData['productName'] ?? 'An order';
      
      await _firestore.collection('notifications').add({
        'userId': sellerId,
        'title': 'Order Cancelled',
        'message': 'Order for $productName has been cancelled by the customer.',
        'orderId': orderId,
        'type': 'order_cancelled',
        'isRead': false,
        'createdAt': now,
      });
      
      return true;
    } catch (e) {
      print('Error cancelling order: $e');
      return false;
    }
  }


// Get user orders
Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
  try {
    if (userId == null) return [];
    
    // For backward compatibility, this now calls the more specific method
    return await getBuyerOrders(userId);
  } catch (e) {
    print('Error getting user orders: $e');
    return [];
  }
}
  // Get user order statistics
  Future<Map<String, dynamic>> getUserOrderStats(String userId, {bool isSeller = false}) async {
    try {
      if (userId == null) return {
        'total': 0,
        'pending': 0,
        'processing': 0,
        'shipped': 0,
        'delivered': 0,
        'completed': 0,
        'cancelled': 0,
      };
      
      // Field to filter on based on whether user is buyer or seller
      String fieldName = isSeller ? 'sellerId' : 'buyerId';
      
      // Query all orders for this user
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .get();
      
      // Count orders by status
      int totalOrders = snapshot.docs.length;
      int pendingOrders = 0;
      int processingOrders = 0;
      int shippedOrders = 0;
      int deliveredOrders = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String status = data['status'] ?? '';
        
        switch (status.toLowerCase()) {
          case 'pending':
            pendingOrders++;
            break;
          case 'processing':
            processingOrders++;
            break;
          case 'shipped':
            shippedOrders++;
            break;
          case 'delivered':
            deliveredOrders++;
            break;
          case 'completed':
            completedOrders++;
            break;
          case 'cancelled':
            cancelledOrders++;
            break;
        }
      }
      
      // Return stats as map
      return {
        'total': totalOrders,
        'pending': pendingOrders,
        'processing': processingOrders,
        'shipped': shippedOrders,
        'delivered': deliveredOrders,
        'completed': completedOrders,
        'cancelled': cancelledOrders,
      };
    } catch (e) {
      print('Error getting user order stats: $e');
      return {
        'total': 0,
        'pending': 0,
        'processing': 0,
        'shipped': 0,
        'delivered': 0,
        'completed': 0,
        'cancelled': 0,
      };
    }
  }

  // Get user notifications
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      if (userId == null) return [];
      
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      List<Map<String, dynamic>> notifications = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        notifications.add(data);
      }
      
      return notifications;
    } catch (e) {
      print('Error getting user notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
      
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Get market prices
  Future<List<Map<String, dynamic>>> getMarketPrices() async {
    try {
      // In a real app, this would fetch from an external API
      // For this example, we'll create sample market data
      
      // Create a 2-second delay to simulate network request
      await Future.delayed(Duration(seconds: 2));
      
      List<Map<String, dynamic>> marketPrices = [
        {
          'product': 'Wheat',
          'minPrice': 25.0,
          'maxPrice': 35.0,
          'avgPrice': 30.0,
          'unit': 'kg',
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        },
        {
          'product': 'Rice',
          'minPrice': 45.0,
          'maxPrice': 60.0,
          'avgPrice': 52.5,
          'unit': 'kg',
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        },
        {
          'product': 'Tomatoes',
          'minPrice': 30.0,
          'maxPrice': 40.0,
          'avgPrice': 35.0,
          'unit': 'kg',
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        },
        {
          'product': 'Potatoes',
          'minPrice': 20.0,
          'maxPrice': 25.0,
          'avgPrice': 22.5,
          'unit': 'kg',
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        },
        {
          'product': 'Onions',
          'minPrice': 25.0,
          'maxPrice': 35.0,
          'avgPrice': 30.0,
          'unit': 'kg',
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        },
        {
          'product': 'Apples',
          'minPrice': 100.0,
          'maxPrice': 150.0,
          'avgPrice': 125.0,
          'unit': 'kg',
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        },
      ];
      
      return marketPrices;
    } catch (e) {
      print('Error getting market prices: $e');
      return [];
    }
  }

  // Get price history for a product
  Future<List<Map<String, dynamic>>> getProductPriceHistory(String productName) async {
    try {
      // This would normally fetch historical data from an API
      // For this example, we'll generate sample data
      
      // Create a 2-second delay to simulate network request
      await Future.delayed(Duration(seconds: 2));
      
      // Create data for the last 7 days
      List<Map<String, dynamic>> priceHistory = [];
      DateTime now = DateTime.now();
      
      // Generate some randomized price fluctuations
      double basePrice = 30.0; // For wheat
      if (productName.toLowerCase() == 'rice') basePrice = 50.0;
      if (productName.toLowerCase() == 'tomatoes') basePrice = 35.0;
      if (productName.toLowerCase() == 'potatoes') basePrice = 22.0;
      if (productName.toLowerCase() == 'onions') basePrice = 28.0;
      if (productName.toLowerCase() == 'apples') basePrice = 120.0;
      
      for (int i = 30; i >= 0; i--) {
        DateTime date = now.subtract(Duration(days: i));
        String dateStr = DateFormat('yyyy-MM-dd').format(date);
        
        // Create some price variation with a slight upward trend
        double randomFactor = 0.9 + (0.2 * (i / 30)) + (0.1 * (date.day % 5));
        double price = basePrice * randomFactor;
        
        priceHistory.add({
          'date': dateStr,
          'price': double.parse(price.toStringAsFixed(2)),
        });
      }
      
      return priceHistory;
    } catch (e) {
      print('Error getting price history: $e');
      return [];
    }
  }
  
  // Get inventory value statistics
  Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      if (currentUserId == null) return {
        'totalItems': 0,
        'totalValue': 0,
        'inStockItems': 0,
        'outOfStockItems': 0,
        'lowStockItems': 0, // Items with quantity < 5
        'topCategories': [],
      };
      
      // Get all inventory items for this farmer
      List<Map<String, dynamic>> inventory = await getFarmerInventory();
      
      if (inventory.isEmpty) {
        return {
          'totalItems': 0,
          'totalValue': 0,
          'inStockItems': 0,
          'outOfStockItems': 0,
          'lowStockItems': 0,
          'topCategories': [],
        };
      }
      
      // Calculate stats
      int totalItems = inventory.length;
      double totalValue = 0;
      int inStockItems = 0;
      int outOfStockItems = 0;
      int lowStockItems = 0;
      Map<String, int> categoryCount = {};
      
      for (var item in inventory) {
        // Calculate total value
        double itemValue = 0;
        if (item['unitPrice'] != null && item['quantity'] != null) {
          double unitPrice = double.parse(item['unitPrice'].toString());
          int quantity = item['quantity'];
          itemValue = unitPrice * quantity;
        }
        totalValue += itemValue;
        
        // Count items by status
        String status = item['status'] ?? '';
        if (status.toLowerCase() == 'in stock') {
          inStockItems++;
          
          // Check if low stock
          if (item['quantity'] != null && item['quantity'] < 5) {
            lowStockItems++;
          }
        } else if (status.toLowerCase() == 'out of stock') {
          outOfStockItems++;
        }
        
        // Count by category
        String category = item['category'] ?? 'Uncategorized';
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }
      
      // Get top categories
      List<Map<String, dynamic>> topCategories = categoryCount.entries.map((entry) {
        return {
          'category': entry.key,
          'count': entry.value,
        };
      }).toList();
      
      // Sort categories by count (descending)
      topCategories.sort((a, b) => b['count'] - a['count']);
      
      // Limit to top 5
      if (topCategories.length > 5) {
        topCategories = topCategories.sublist(0, 5);
      }
      
      return {
        'totalItems': totalItems,
        'totalValue': totalValue,
        'inStockItems': inStockItems,
        'outOfStockItems': outOfStockItems,
        'lowStockItems': lowStockItems,
        'topCategories': topCategories,
      };
    } catch (e) {
      print('Error getting inventory stats: $e');
      return {
        'totalItems': 0,
        'totalValue': 0,
        'inStockItems': 0,
        'outOfStockItems': 0,
        'lowStockItems': 0,
        'topCategories': [],
      };
    }
  }

  // Add these methods to your FirebaseService class

// Get user profile data
Future<Map<String, dynamic>?> getUserProfile() async {
  try {
    if (currentUserId == null) return null;

    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();

    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    } else {
      // Return empty map for new users
      print('No user profile found for user: $currentUserId');
      return {};
    }
  } catch (e) {
    print('Error getting user profile: $e');
    return null;
  }
}

// Update user profile
Future<bool> updateUserProfile(Map<String, dynamic> data) async {
  try {
    if (currentUserId == null) return false;

    // Check if document exists first
    DocumentSnapshot docSnapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();
    
    if (docSnapshot.exists) {
      // Document exists, update it
      await _firestore.collection('users').doc(currentUserId).update(data);
    } else {
      // Document doesn't exist, create it
      await _firestore.collection('users').doc(currentUserId).set(data);
    }
    
    return true;
  } catch (e) {
    print('Error updating user profile: $e');
    return false;
  }
}

// Get farmer profile data - looks in the 'inventory' collection for farmer data
Future<Map<String, dynamic>?> getFarmerProfile() async {
  try {
    if (currentUserId == null) return null;

    // First try to get the user data
    Map<String, dynamic>? userData = await getUserProfile();
    
    // If we didn't get user data or role isn't farmer, return null
    if (userData == null || userData['role'] != 'farmer') {
      print('User is not a farmer or profile not found');
      return null;
    }
    
    // Get additional farmer-specific data from farmers collection if it exists
    DocumentSnapshot farmerDoc = await _firestore
        .collection('farmers')
        .doc(currentUserId)
        .get();

    Map<String, dynamic> farmerData = {};
    
    // Merge user and farmer data
    if (userData.isNotEmpty) {
      farmerData.addAll(userData);
    }
    
    // Add farmer-specific fields if they exist
    if (farmerDoc.exists) {
      farmerData.addAll(farmerDoc.data() as Map<String, dynamic>);
    }
    
    return farmerData.isEmpty ? {} : farmerData;
  } catch (e) {
    print('Error getting farmer profile: $e');
    return null;
  }
}

// Update farmer profile - updates both users and farmers collections
Future<bool> updateFarmerProfile(Map<String, dynamic> data) async {
  try {
    if (currentUserId == null) return false;
    
    // Separate user and farmer data
    Map<String, dynamic> userData = {
      'name': data['name'],
      'email': data['email'],
      'phoneNumber': data['phone'],
      'location': data['address'] != null ? '${data['city']}, ${data['state']}' : null,
      'role': 'farmer',
      'profileImageUrl': data['profilePic'],
    };
    
    // Farmer specific data
    Map<String, dynamic> farmerData = {
      'farmName': data['farmName'],
      'farmSize': data['farmSize'],
      'farmType': data['farmType'],
      'experience': data['experience'],
      'bio': data['bio'],
      'address': data['address'],
      'city': data['city'],
      'state': data['state'],
      'pincode': data['pincode'],
      'updatedAt': data['updatedAt'],
    };
    
    if (data['createdAt'] != null) {
      farmerData['createdAt'] = data['createdAt'];
    }
    
    // Update user profile first
    bool userUpdateSuccess = await updateUserProfile(userData);
    
    if (!userUpdateSuccess) {
      return false;
    }
    
    // Then update farmer-specific data
    DocumentSnapshot farmerDoc = await _firestore
        .collection('farmers')
        .doc(currentUserId)
        .get();
    
    if (farmerDoc.exists) {
      await _firestore.collection('farmers').doc(currentUserId).update(farmerData);
    } else {
      await _firestore.collection('farmers').doc(currentUserId).set(farmerData);
    }
    
    return true;
  } catch (e) {
    print('Error updating farmer profile: $e');
    return false;
  }
}

// Get consumer profile data
Future<Map<String, dynamic>?> getConsumerProfile() async {
  try {
    // For consumers, we just use the users collection
    return await getUserProfile();
  } catch (e) {
    print('Error getting consumer profile: $e');
    return null;
  }
}

// Update consumer profile
Future<bool> updateConsumerProfile(Map<String, dynamic> data) async {
  try {
    // Make sure role is set to consumer
    data['role'] = 'consumer';
    return await updateUserProfile(data);
  } catch (e) {
    print('Error updating consumer profile: $e');
    return false;
  }
}
}