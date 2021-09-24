import 'package:flutter/material.dart';

class TextFieldWidget extends StatefulWidget {
  const TextFieldWidget({
    Key? key,
    required this.controller,
    required this.hint, this.isNumber = true,
  }) : super(key: key);

  final TextEditingController controller;
  final String hint;
  final bool isNumber;

  @override
  State<TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: widget.isNumber ? TextInputType.number : TextInputType.name,
      controller: widget.controller,
      decoration: InputDecoration(hintText: widget.hint),
    );
  }
}