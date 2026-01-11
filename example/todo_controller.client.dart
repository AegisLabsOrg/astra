// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// ClientGenerator
// **************************************************************************

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'todo_controller.dart';

class TodoControllerClient {
  final String baseUrl;
  final http.Client httpClient;

  TodoControllerClient(this.baseUrl, {http.Client? client})
    : httpClient = client ?? http.Client();

  Future<List<Todo>> getAll() async {
    final uri = Uri.parse('$baseUrl/todos/');
    final url = uri;
    final response = await httpClient.get(url);
    if (response.statusCode >= 400) {
      throw Exception('API Error ${response.statusCode}: ${response.body}');
    }
    final List<dynamic> json = jsonDecode(response.body);
    return json.map((e) => Todo.fromJson(e)).toList();
  }

  Future<Todo> create(CreateTodoDto body) async {
    final uri = Uri.parse('$baseUrl/todos/');
    final url = uri;
    final response = await httpClient.post(
      url,
      headers: {'content-type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode >= 400) {
      throw Exception('API Error ${response.statusCode}: ${response.body}');
    }
    return Todo.fromJson(jsonDecode(response.body));
  }

  Future<Todo> getById(String id) async {
    final uri = Uri.parse('$baseUrl/todos/$id');
    final url = uri;
    final response = await httpClient.get(url);
    if (response.statusCode >= 400) {
      throw Exception('API Error ${response.statusCode}: ${response.body}');
    }
    return Todo.fromJson(jsonDecode(response.body));
  }

  Future<void> delete(String id, bool force) async {
    final uri = Uri.parse('$baseUrl/todos/$id');
    final url = uri.replace(queryParameters: {'force': force.toString()});
    final response = await httpClient.delete(url);
    if (response.statusCode >= 400) {
      throw Exception('API Error ${response.statusCode}: ${response.body}');
    }
  }
}
