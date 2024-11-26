import 'package:flutter/material.dart';
import 'package:tram_train/train_list.dart';
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Navigation vers la deuxième page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SecondPage()),
                    );
                  },
                  child: const Text('Page 2'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Navigation vers la deuxième page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TrainList()),
                    );
                  },
                  child: const Text('Liste des trains'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
