/// Reusable error display helpers.
library;

import 'package:flutter/material.dart';

/// Shows a floating error [SnackBar] with the given [message].
///
/// Silently does nothing if [context] is no longer mounted.
void showErrorSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red.shade700,
      duration: const Duration(seconds: 4),
    ),
  );
}
