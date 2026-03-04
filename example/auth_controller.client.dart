// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// ClientGenerator
// **************************************************************************

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'auth_controller.dart';
import 'models.dart';

class AuthControllerClient {
  final String baseUrl;
  final http.Client httpClient;

  AuthControllerClient(this.baseUrl, {http.Client? client})
    : httpClient = client ?? http.Client();

  Future<TokenDto> login(LoginDto body) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final url = uri;
    final response = await httpClient.post(
      url,
      headers: {'content-type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode >= 400) {
      throw Exception('API Error ${response.statusCode}: ${response.body}');
    }
    return TokenDto.fromJson(jsonDecode(response.body));
  }

  Future<Map<String, dynamic>> me() async {
    final uri = Uri.parse('$baseUrl/auth/me');
    final url = uri;
    final response = await httpClient.get(url);
    if (response.statusCode >= 400) {
      throw Exception('API Error ${response.statusCode}: ${response.body}');
    }
    return Map<String, dynamic>.from(jsonDecode(response.body));
  }
}
