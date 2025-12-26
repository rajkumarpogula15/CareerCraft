import 'package:flutter/material.dart';

void showFooterPopup(BuildContext context, Widget child) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    ),
  );
}
