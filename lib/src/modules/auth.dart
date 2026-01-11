import 'dart:async';
import 'package:shelf/shelf.dart';

/// User Principal object
class UserPrincipal {
  final String id;
  final String username;
  final Map<String, dynamic> claims;

  UserPrincipal(this.id, this.username, {this.claims = const {}});
}

/// Abstract Auth Service
abstract class AuthService {
  Future<String> signToken(UserPrincipal user);
  Future<UserPrincipal?> verifyToken(String token);
}

/// Middleware that protects routes
/// Adds 'user' to context if valid.
/// Returns 401 if [optional] is false and token is missing/invalid.
Middleware authMiddleware(AuthService authService, {bool optional = false}) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];
      String? token;

      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        token = authHeader.substring(7);
      }

      if (token != null) {
        try {
          final user = await authService.verifyToken(token);
          if (user != null) {
            final newRequest = request.change(context: {'user': user});
            return await innerHandler(newRequest);
          }
        } catch (e) {
          // Token invalid
        }
      }

      if (!optional && token == null) {
        return Response(401, body: 'Unauthorized: Missing Token');
      }

      if (!optional) {
        return Response(401, body: 'Unauthorized: Invalid Token');
      }

      return await innerHandler(request);
    };
  };
}

// Extension to easily get user from request
extension RequestAuth on Request {
  UserPrincipal? get user => context['user'] as UserPrincipal?;
}

/// SIMULATED JWT Implementation (For Demo purposes without external deps)
/// In production, replace with `dart_jsonwebtoken`.
class SimpleAuthService implements AuthService {
  final String secret;
  SimpleAuthService(this.secret);

  @override
  Future<String> signToken(UserPrincipal user) async {
    // Mock Token: just base64 encoded json
    return "valid_token_${user.id}";
  }

  @override
  Future<UserPrincipal?> verifyToken(String token) async {
    if (token.startsWith("valid_token_")) {
      final parts = token.split("_");
      final id = parts.length > 2 ? parts[2] : "0";
      return UserPrincipal(id, "User$id");
    }
    throw Exception("Invalid token");
  }
}
