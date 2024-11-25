import 'package:flutter/material.dart';
import 'second_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page d\'accueil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Bienvenue sur la page d\'accueil!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigation vers la deuxième page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SecondPage()),
                );
              },
              child: const Text('Aller à la deuxième page'),
            ),
          ],
        ),
      ),
    );
  }
}
