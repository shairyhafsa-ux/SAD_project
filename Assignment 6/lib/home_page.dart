import 'package:flutter/material.dart';
import 'profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hogwarts Houses"),
        backgroundColor: const Color.fromARGB(255, 3, 85, 152),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            // Main Hogwarts image
            Image.asset("assets/images/HP1.webp", height: 180),

            const SizedBox(height: 30),

            // House Buttons
            HouseButton(
              name: "Gryffindor",
              color: Colors.red,
              image: "assets/images/gryffindor.jpg",
            ),
            HouseButton(
              name: "Hufflepuff",
              color: Colors.amber,
              image: "assets/images/hufflepulf.jpg",
            ),
            HouseButton(
              name: "Ravenclaw",
              color: Colors.blue,
              image: "assets/images/ravenclaw2.jpg",
            ),
            HouseButton(
              name: "Slytherin",
              color: Colors.green,
              image: "assets/images/slytherin2.jpg",
            ),
          ],
        ),
      ),
    );
  }
}

class HouseButton extends StatelessWidget {
  final String name;
  final Color color;
  final String image;

  const HouseButton({
    super.key,
    required this.name,
    required this.color,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(
                houseName: name,
                houseColor: color,
                houseImage: image,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          fixedSize: const Size(200, 45),
        ),
        child: Text(name),
      ),
    );
  }
}
