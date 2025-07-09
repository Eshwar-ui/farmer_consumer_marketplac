import 'package:farmer_consumer_marketplace/models/product_model.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  outForDelivery,
  delivered,
  cancelled,
  returned
}

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final double quantity;
  final ProductUnit unit;
  final bool isOrganic;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.isOrganic,
    this.imageUrl,
    this.metadata,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'],
      name: json['name'],
      price: json['price'].toDouble(),
      quantity: json['quantity'].toDouble(),
      unit: _getUnitFromString(json['unit']),
      isOrganic: json['isOrganic'] ?? false,
      imageUrl: json['imageUrl'],
      metadata: json['metadata'],
    );
  }

  factory OrderItem.fromProduct(ProductModel product, double quantity) {
    return OrderItem(
      productId: product.id,
      name: product.name,
      price: product.price,
      quantity: quantity,
      unit: product.unit,
      isOrganic: product.organic,
      imageUrl: product.imageUrls?.isNotEmpty == true ? product.imageUrls!.first : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'unit': unit.toString().split('.').last,
      'isOrganic': isOrganic,
      'imageUrl': imageUrl,
      'metadata': metadata,
    };
  }

  double get totalPrice => price * quantity;

  static ProductUnit _getUnitFromString(String unit) {
    switch (unit) {
      case 'kg':
        return ProductUnit.kg;
      case 'gram':
        return ProductUnit.gram;
      case 'liter':
        return ProductUnit.liter;
      case 'piece':
        return ProductUnit.piece;
      case 'dozen':
        return ProductUnit.dozen;
      case 'quintal':
        return ProductUnit.quintal;
      case 'ton':
        return ProductUnit.ton;
      default:
        return ProductUnit.kg;
    }
  }

  String getUnitString() {
    switch (unit) {
      case ProductUnit.kg:
        return 'kg';
      case ProductUnit.gram:
        return 'g';
      case ProductUnit.liter:
        return 'L';
      case ProductUnit.piece:
        return 'pc';
      case ProductUnit.dozen:
        return 'dz';
      case ProductUnit.quintal:
        return 'qtl';
      case ProductUnit.ton:
        return 'ton';
      default:
        return 'unit';
    }
  }
}

class OrderAddress {
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final double? latitude;
  final double? longitude;

  OrderAddress({
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
    this.latitude,
    this.longitude,
  });

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      fullName: json['fullName'],
      phone: json['phone'],
      addressLine1: json['addressLine1'],
      addressLine2: json['addressLine2'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      country: json['country'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String getFormattedAddress() {
    return [
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2,
      '$city, $state - $pincode',
      country,
    ].join(', ');
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String farmerId;
  final String farmerName;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double total;
  final String paymentMethod;
  final String? paymentId;
  final OrderAddress deliveryAddress;
  final String? cancellationReason;
  final String? returnReason;
  final Map<String, dynamic>? metadata;

  OrderModel({
    required this.id,
    required this.userId,
    required this.farmerId,
    required this.farmerName,
    required this.items,
    required this.status,
    required this.orderDate,
    this.deliveryDate,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    this.paymentId,
    required this.deliveryAddress,
    this.cancellationReason,
    this.returnReason,
    this.metadata,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userId: json['userId'],
      farmerId: json['farmerId'],
      farmerName: json['farmerName'],
      items: (json['items'] as List).map((item) => OrderItem.fromJson(item)).toList(),
      status: _getStatusFromString(json['status']),
      orderDate: DateTime.parse(json['orderDate']),
      deliveryDate: json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
      subtotal: json['subtotal'].toDouble(),
      deliveryFee: json['deliveryFee'].toDouble(),
      tax: json['tax'].toDouble(),
      total: json['total'].toDouble(),
      paymentMethod: json['paymentMethod'],
      paymentId: json['paymentId'],
      deliveryAddress: OrderAddress.fromJson(json['deliveryAddress']),
      cancellationReason: json['cancellationReason'],
      returnReason: json['returnReason'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status.toString().split('.').last,
      'orderDate': orderDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'tax': tax,
      'total': total,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'deliveryAddress': deliveryAddress.toJson(),
      'cancellationReason': cancellationReason,
      'returnReason': returnReason,
      'metadata': metadata,
    };
  }

  static OrderStatus _getStatusFromString(String status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'outForDelivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'returned':
        return OrderStatus.returned;
      default:
        return OrderStatus.pending;
    }
  }

  String getReadableStatus() {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.returned:
        return 'Returned';
      default:
        return 'Unknown';
    }
  }

  int getTotalItemCount() {
    return items.fold(0, (sum, item) => sum + item.quantity.toInt());
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? farmerId,
    String? farmerName,
    List<OrderItem>? items,
    OrderStatus? status,
    DateTime? orderDate,
    DateTime? deliveryDate,
    double? subtotal,
    double? deliveryFee,
    double? tax,
    double? total,
    String? paymentMethod,
    String? paymentId,
    OrderAddress? deliveryAddress,
    String? cancellationReason,
    String? returnReason,
    Map<String, dynamic>? metadata,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      items: items ?? this.items,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      returnReason: returnReason ?? this.returnReason,
      metadata: metadata ?? this.metadata,
    );
  }
}