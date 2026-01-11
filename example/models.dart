class CreateTodoDto {
  final String title;
  CreateTodoDto({required this.title});

  // 必须有 fromJson 供框架解析 Body
  factory CreateTodoDto.fromJson(Map<String, dynamic> json) {
    return CreateTodoDto(title: json['title']);
  }
}
