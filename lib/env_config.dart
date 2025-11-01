import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String? apiKey;

  static Future<void> load() async {
    try {
      const environment = String.fromEnvironment('ENV');
      String envFile = '.env.local';

      if (environment == 'prod') {
        envFile = '.env.prod';
      } else if (environment == 'dev') {
        envFile = '.env.dev';
      }

      await dotenv.load(fileName: envFile);

      apiKey = dotenv.env['API_KEY'];
    } catch (e) {
      apiKey = '61032076-d074-439e-8526-5c39a541479f';
    }
  }
}
