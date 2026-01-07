import 'package:flutter/material.dart';

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final TextEditingController usdController = TextEditingController();
  final TextEditingController discountController = TextEditingController();

  double bdt = 0;
  double discountedPrice = 0;

  void convertUSD() {
    final usd = double.tryParse(usdController.text) ?? 0;
    setState(() {
      bdt = usd * 105; // example conversion rate USD→BDT
    });
  }

  void applyDiscount() {
    final price = double.tryParse(usdController.text) ?? 0;
    final discount = double.tryParse(discountController.text) ?? 0;

    setState(() {
      discountedPrice = price - (price * discount / 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cafe Utility')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // USD → BDT Converter
            const Text(
              'USD → BDT Converter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount in USD',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: convertUSD,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
              child: const Text('Convert to BDT'),
            ),
            const SizedBox(height: 8),
            Text(
              '৳ $bdt',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 40, thickness: 2),
            // Discount Calculator
            const Text(
              'Discount Calculator',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: discountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Discount %',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: applyDiscount,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
              child: const Text('Apply Discount'),
            ),
            const SizedBox(height: 8),
            Text(
              'Discounted Price: $discountedPrice',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

