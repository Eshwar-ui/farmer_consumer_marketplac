import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final double height;
  final bool centerTitle;
  final Widget? leading;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions = const [],
    this.height = kToolbarHeight,
    this.centerTitle = true,
    this.leading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      foregroundColor: Colors.white,
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      centerTitle: centerTitle,
      elevation: 0,
      backgroundColor: Colors.green,
      leading: leading,
      actions: actions,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
