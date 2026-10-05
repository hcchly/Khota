import 'package:flutter/material.dart';

/// Short message for features planned for later sprints.
void showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text('هذه الخدمة ستتوفر قريباً')),
    );
}
