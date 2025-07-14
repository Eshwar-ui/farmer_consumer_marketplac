import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:farmer_consumer_marketplace/utils/app_colors.dart';

class MarketProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const MarketProductCard({
    Key? key,
    required this.product,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format currency
    final priceFormat = NumberFormat('#,##0.00');
    final price =
        product['unitPrice'] != null
            ? double.parse(product['unitPrice'].toString())
            : 0.0;

    final String formattedPrice = '₹${priceFormat.format(price)}';
    final String unit = product['unit'] ?? 'kg';

    // Handle product images
    final List imageUrls = (product['imageUrls'] ?? []) as List;
    Widget productImageWidget;
    if (imageUrls.isEmpty) {
      productImageWidget = Image.asset(
        'assets/images/placeholder_product.png',
        fit: BoxFit.cover,
      );
    } else if (imageUrls.length == 1) {
      productImageWidget = Image.network(
        imageUrls.first,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/placeholder_product.png',
            fit: BoxFit.cover,
          );
        },
      );
    } else {
      productImageWidget = _MarketProductImageCarousel(imageUrls: imageUrls);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            AspectRatio(
              aspectRatio: 1.4,
              child: Hero(
                tag: 'product_${product['id']}',
                child: productImageWidget,
              ),
            ),

            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    product['name'] ?? 'Unknown',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 4),

                  // Farmer name
                  Text(
                    product['farmerName'] ?? 'Unknown Farmer',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 8),

                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$formattedPrice/$unit',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),

                      // Freshness indicator
                      if (product['harvestDate'] != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Fresh',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketProductImageCarousel extends StatefulWidget {
  final List imageUrls;
  const _MarketProductImageCarousel({Key? key, required this.imageUrls})
    : super(key: key);
  @override
  State<_MarketProductImageCarousel> createState() =>
      _MarketProductImageCarouselState();
}

class _MarketProductImageCarouselState
    extends State<_MarketProductImageCarousel> {
  int _current = 0;
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PageView.builder(
          itemCount: widget.imageUrls.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (context, idx) {
            return Image.network(
              widget.imageUrls[idx],
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Image.asset(
                    'assets/images/placeholder_product.png',
                    fit: BoxFit.cover,
                  ),
            );
          },
        ),
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (idx) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _current == idx ? Colors.green : Colors.grey[400],
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
