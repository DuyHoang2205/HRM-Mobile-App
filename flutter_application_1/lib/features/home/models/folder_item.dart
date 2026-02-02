import 'package:flutter/material.dart';

class FolderItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const FolderItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}
