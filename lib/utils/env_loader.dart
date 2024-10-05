import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvLoader {
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: ".env");
      if (kDebugMode) {
        print("Environment file loaded successfully.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to load .env file: $e");
      }
    }
  }

  static String get(String key) {
    // Make sure that dotenv is loaded before accessing
    if (!dotenv.isInitialized) {
      throw Exception("Dotenv not initialized. Make sure `EnvLoader.load()` is called before accessing any environment variables.");
    }
    return dotenv.env[key] ?? '';
  }
}
