import 'package:flutter/material.dart';

class SubjectManagementScreen extends StatelessWidget {
  const SubjectManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subject Management')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text('SubjectManagementScreen - 工事中', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
