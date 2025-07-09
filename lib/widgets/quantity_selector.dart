import 'package:flutter/material.dart';
import 'package:farmer_consumer_marketplace/utils/app_colors.dart';

class QuantitySelector extends StatelessWidget {
  final int initialValue;
  final int minValue;
  final int maxValue;
  final Function(int) onChanged;

  const QuantitySelector({
    Key? key,
    required this.initialValue,
    this.minValue = 1,
    required this.maxValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button
          _buildButton(
            icon: Icons.remove,
            onPressed: initialValue > minValue
                ? () => onChanged(initialValue - 1)
                : null,
          ),
          
          // Quantity display
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Text(
                initialValue.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Increase button
          _buildButton(
            icon: Icons.add,
            onPressed: initialValue < maxValue
                ? () => onChanged(initialValue + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onPressed != null ? AppColors.primaryColor.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onPressed != null ? AppColors.primaryColor : Colors.grey,
        ),
      ),
    );
  }
}