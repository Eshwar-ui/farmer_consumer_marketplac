enum ProductCategory {
  fruits,
  vegetables,
  grains,
  dairy,
  poultry,
  meat,
  other
}

enum ProductUnit {
  kg,
  gram,
  liter,
  piece,
  dozen,
  quintal,
  ton
}

class ProductModel {
  final String id;
  final String farmerId;
  final String name;
  final String description;
  final ProductCategory category;
  final double price;
  final double quantity;
  final ProductUnit unit;
  final List<String>? imageUrls;
  final DateTime harvestDate;
  final DateTime listedDate;
  final bool organic;
  final String location;
  final Map<String, dynamic>? additionalInfo;

  ProductModel({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.quantity,
    required this.unit,
    this.imageUrls,
    required this.harvestDate,
    required this.listedDate,
    required this.organic,
    required this.location,
    this.additionalInfo,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      farmerId: json['farmerId'],
      name: json['name'],
      description: json['description'],
      category: _getCategoryFromString(json['category']),
      price: json['price'].toDouble(),
      quantity: json['quantity'].toDouble(),
      unit: _getUnitFromString(json['unit']),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      harvestDate: DateTime.parse(json['harvestDate']),
      listedDate: DateTime.parse(json['listedDate']),
      organic: json['organic'] ?? false,
      location: json['location'],
      additionalInfo: json['additionalInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmerId': farmerId,
      'name': name,
      'description': description,
      'category': category.toString().split('.').last,
      'price': price,
      'quantity': quantity,
      'unit': unit.toString().split('.').last,
      'imageUrls': imageUrls,
      'harvestDate': harvestDate.toIso8601String(),
      'listedDate': listedDate.toIso8601String(),
      'organic': organic,
      'location': location,
      'additionalInfo': additionalInfo,
    };
  }

  static ProductCategory _getCategoryFromString(String category) {
    switch (category) {
      case 'fruits':
        return ProductCategory.fruits;
      case 'vegetables':
        return ProductCategory.vegetables;
      case 'grains':
        return ProductCategory.grains;
      case 'dairy':
        return ProductCategory.dairy;
      case 'poultry':
        return ProductCategory.poultry;
      case 'meat':
        return ProductCategory.meat;
      default:
        return ProductCategory.other;
    }
  }

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

  ProductModel copyWith({
    String? id,
    String? farmerId,
    String? name,
    String? description,
    ProductCategory? category,
    double? price,
    double? quantity,
    ProductUnit? unit,
    List<String>? imageUrls,
    DateTime? harvestDate,
    DateTime? listedDate,
    bool? organic,
    String? location,
    Map<String, dynamic>? additionalInfo,
  }) {
    return ProductModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      imageUrls: imageUrls ?? this.imageUrls,
      harvestDate: harvestDate ?? this.harvestDate,
      listedDate: listedDate ?? this.listedDate,
      organic: organic ?? this.organic,
      location: location ?? this.location,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}