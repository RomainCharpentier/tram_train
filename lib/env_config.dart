import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String? apiKey;

  static Future<void> load() async {
    const environment = String.fromEnvironment('ENV');
    String envFile = '.env.local';

    if (environment == 'prod') {
      envFile = '.env.prod';
    } else if (environment == 'dev') {
      envFile = '.env.dev';
    }

    print('Chargement du fichier $envFile');
    await dotenv.load(fileName: envFile);

    apiKey = dotenv.env['API_KEY'];
  }
}
