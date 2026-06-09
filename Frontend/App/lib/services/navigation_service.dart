import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/argusx_config.dart';

class ArgusXNavigationService {
  final String _base = ArgusXConfig.apiUrl;

  Future<Map<String, dynamic>> resolveRoute({
    required Map<String, dynamic> origin,
    required Map<String, dynamic> destination,
    int stepIndex = 0,
  }) async {
    final uri = Uri.parse('$_base/navigation/resolve');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'origin': origin,
        'destination': destination,
        'step_index': stepIndex,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Navigation resolve failed (${response.statusCode}): ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
