class OpenApiDocument {
  final String openapi = '3.0.0';
  final OpenApiInfo info;
  final Map<String, Map<String, OpenApiOperation>>
  paths; // path -> method -> operation

  OpenApiDocument({required this.info, this.paths = const {}});

  Map<String, dynamic> toJson() {
    // Transform paths map to json
    final pathJson = <String, Map<String, dynamic>>{};

    paths.forEach((pathUri, operations) {
      // OpenAPI paths use {param} instead of :param
      final normalizedPath = pathUri.replaceAllMapped(
        RegExp(r':(\w+)'),
        (match) => '{${match.group(1)}}',
      );

      pathJson[normalizedPath] = operations.map(
        (method, op) => MapEntry(method.toLowerCase(), op.toJson()),
      );
    });

    return {'openapi': openapi, 'info': info.toJson(), 'paths': pathJson};
  }
}

class OpenApiInfo {
  final String title;
  final String version;

  OpenApiInfo({this.title = 'Astra API', this.version = '1.0.0'});

  Map<String, dynamic> toJson() => {'title': title, 'version': version};
}

class OpenApiOperation {
  final String operationId;
  final List<OpenApiParameter> parameters;
  final Map<String, dynamic> responses; // code -> response
  final Map<String, dynamic>? requestBody;

  OpenApiOperation({
    required this.operationId,
    this.parameters = const [],
    this.responses = const {
      '200': {'description': 'OK'},
    },
    this.requestBody,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'operationId': operationId,
      'responses': responses,
    };
    if (parameters.isNotEmpty) {
      json['parameters'] = parameters.map((p) => p.toJson()).toList();
    }
    if (requestBody != null) {
      json['requestBody'] = requestBody;
    }
    return json;
  }
}

class OpenApiParameter {
  final String name;
  final String location; // path, query, header, cookie
  final bool required;
  final String type; // integer, string, etc.

  OpenApiParameter({
    required this.name,
    required this.location,
    required this.required,
    this.type = 'string',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'in': location,
    'required': required,
    'schema': {'type': type},
  };
}
