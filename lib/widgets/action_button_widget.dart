import 'package:flutter/material.dart';

class ActionButtonWidget extends StatelessWidget {
  const ActionButtonWidget({
    Key? key,
    required this.label,
    required this.action,
  }) : super(key: key);

  final String label;
  final Function? action;

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () {
          action!();
        },
        child: Text(label));
  }
}