import 'package:astra/astra.dart';
import 'package:astra/src/routing/route.dart';
import 'package:astra/src/routing/router.dart';
import 'package:shelf/shelf.dart';
import 'dart:convert';

part 'sample_controller.g.dart';

// 1. Define a Service
class UserService {
  String getGreeting(String name) => "Hello service user: $name";
}

class CreateUserDto {
  final String name;
  final String email;

  CreateUserDto({required this.name, required this.email});

  factory CreateUserDto.fromJson(Map<String, dynamic> json) {
    return CreateUserDto(
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'email': email};
}

@Controller('/users')
class UserController {
  // 2. Inject Service via Constructor
  final UserService userService;
  // Inject Logger
  final AstraLogger logger;

  UserController(this.userService, this.logger);

  @Get('/')
  Response getAll() {
    logger.info('Fetching all users');
    return Response.ok(userService.getGreeting('Guest'));
  }

  @Get('/me')
  Response getProfile(Request req) {
    final user = req.user;
    if (user == null) {
      throw UnauthorizedException('Not Logged In');
    }
    return Response.ok('Hello ${user.username} (${user.id})');
  }

  @Post('/create')
  Response create(@Body() CreateUserDto body) {
    return Response.ok('Created user: ${body.name}');
  }

  @Get('/:id')
  Response getById(@Path() int id, @Query() String details) {
    return Response.ok('User: $id, details: $details');
  }

  @Get('/dto')
  Future<CreateUserDto> getDto() async {
    return CreateUserDto(name: 'Auto', email: 'auto@example.com');
  }

  @Get('/error')
  Future<void> throwError() async {
    throw BadRequestException('Simulated Error');
  }
}
