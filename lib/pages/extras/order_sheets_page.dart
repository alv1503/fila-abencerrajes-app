// lib/pages/extras/order_sheets_page.dart
import 'package:flutter/material.dart';

class OrderSheetsPage extends StatefulWidget {
  const OrderSheetsPage({super.key});

  @override
  State<OrderSheetsPage> createState() => _OrderSheetsPageState();
}

class _OrderSheetsPageState extends State<OrderSheetsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encàrrecs'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 60, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              "Secció d'Encàrrecs",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text("Pendent de rediseño..."),
          ],
        ),
      ),
    );
  }
}