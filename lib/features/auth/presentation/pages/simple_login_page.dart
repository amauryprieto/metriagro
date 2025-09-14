import 'package:flutter/material.dart';

class SimpleLoginPage extends StatelessWidget {
  const SimpleLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.agriculture, size: 80, color: Colors.green),
            SizedBox(height: 32),
            Text(
              'Metriagro',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            SizedBox(height: 48),
            Text('Email'),
            SizedBox(height: 16),
            Text('Contraseña'),
            SizedBox(height: 24),
            ElevatedButton(onPressed: null, child: Text('Iniciar Sesión')),
          ],
        ),
      ),
    );
  }
}
