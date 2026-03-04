class CreateTodoDto {
  final String title;
  CreateTodoDto({required this.title});

  // 必须有 fromJson 供框架解析 Body
  factory CreateTodoDto.fromJson(Map<String, dynamic> json) {
    return CreateTodoDto(title: json['title']);
  }
}

class LoginDto {
  final String username;
  final String password;
  LoginDto({required this.username, required this.password});

  factory LoginDto.fromJson(Map<String, dynamic> json) =>
      LoginDto(username: json['username'], password: json['password']);

  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

class TokenDto {
  final String accessToken;
  TokenDto({required this.accessToken});

  Map<String, dynamic> toJson() => {'access_token': accessToken};

  factory TokenDto.fromJson(Map<String, dynamic> json) {
    return TokenDto(accessToken: json['access_token']);
  }
}
