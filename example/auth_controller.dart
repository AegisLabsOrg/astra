import 'package:astra_dart/astra.dart';
import 'package:astra_dart/src/routing/route.dart';
import 'models.dart';
import 'dart:convert';

part 'auth_controller.g.dart';

@Controller('/auth')
class AuthController {
  final AuthService authService;

  AuthController(this.authService);

  @Post('/login')
  Future<TokenDto> login(@Body() LoginDto body) async {
    // 模拟验证：用户名 admin，密码 admin
    if (body.username == 'admin' && body.password == 'admin') {
      final user = UserPrincipal('1', 'admin');
      final token = await authService.signToken(user);
      return TokenDto(accessToken: token);
    }
    throw AstraHttpException(401,'Invalid credentials', );
  }

  @Get('/me')
  Future<Map<String, dynamic>> me(Request req) async {
    final user = req.user;
    if (user == null) throw AstraHttpException(401,'Invalid credentials', );
    return {
      'id': user.id,
      'username': user.username,
      'message': 'You are accessing a protected route!',
    };
  }
}
