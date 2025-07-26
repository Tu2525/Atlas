import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String? baseUrl = dotenv.env['API_KEY'] ?? "whatever";
  static const String analyzeEndpoint = '/analyze';
  static const String evaluateEndpoint = '/evaluate';
  static const String chatEndpoint = '/chat';
  static const String rootEndpoint = '/';

  // Helper method to get full URL
  static String getUrl(String endpoint) {
    // Remove leading slash from endpoint if baseUrl already has trailing slash
    String cleanEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$baseUrl$cleanEndpoint';
  }

  // Helper method to check if URL is configured
  static bool isUrlConfigured() {
    return baseUrl != 'YOUR_NGROK_URL' && baseUrl!.isNotEmpty;
  }

  // Helper method to get ngrok URL instructions
  static String getSetupInstructions() {
    return '''
To connect to your FastAPI backend:

1. In your Google Colab notebook, run:
   !ngrok http 8000

2. Copy the ngrok URL (e.g., https://abc123.ngrok.io)

3. Update the baseUrl in this file:
   static const String baseUrl = 'YOUR_NGROK_URL';
   
   Replace 'YOUR_NGROK_URL' with your actual ngrok URL

4. Restart the Flutter app

Note: The ngrok URL changes every time you restart ngrok, so you'll need to update this file each time.
''';
  }
}
