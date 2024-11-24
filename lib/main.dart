import 'package:flutter/material.dart';
import 'package:pantry/utils/mongo_helper.dart';
import 'screens/main_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MongoDBHelper.connect(); // Inicjalizacja połączenia MongoDB
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pantry App',
      theme: darkTheme,
      home: MainScreen(),
    );
  }
}
