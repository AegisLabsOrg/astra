// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// ClientGenerator
// **************************************************************************

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'websocket_controller.dart';

class WebSocketControllerClient {
  final String baseUrl;
  final http.Client httpClient;

  WebSocketControllerClient(this.baseUrl, {http.Client? client})
    : httpClient = client ?? http.Client();

  WebSocketChannel echo() {
    final uri = Uri.parse('$baseUrl/ws/echo');
    return WebSocketChannel.connect(uri);
  }

  WebSocketChannel chat(String room) {
    final uri = Uri.parse('$baseUrl/ws/chat/$room');
    return WebSocketChannel.connect(uri);
  }
}
