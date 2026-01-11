import 'package:astra/astra.dart';

void main() async {
  final app = AstraApp(controllers: [], providers: []);

  // Just to make it visible
  print('--- User App Starting (UPDATED) ---');
  await app.listen(8080);
}
