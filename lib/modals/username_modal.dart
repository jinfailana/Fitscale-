import 'package:flutter/material.dart';

class UsernameInputModal extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Username'),
      content: TextField(
        controller: usernameController,
        decoration: const InputDecoration(
          labelText: 'Username',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, null);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final username = usernameController.text.trim();
            Navigator.pop(context, username.isNotEmpty ? username : null);
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
