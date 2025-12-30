import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final String houseName;
  final Color houseColor;
  final String houseImage;

  const ProfilePage({
    super.key,
    required this.houseName,
    required this.houseColor,
    required this.houseImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: houseColor.withOpacity(0.15),

      appBar: AppBar(title: Text(houseName), backgroundColor: houseColor),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(houseImage, height: 200),

            const SizedBox(height: 20),

            Text(
              houseName,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: houseColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
