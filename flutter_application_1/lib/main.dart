import 'package:flutter/material.dart';
import 'app/app_shell.dart'; 
// import 'features/home/view/home_page.dart';
import 'core/auth/auth_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthHelper.silentLogin();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AppShell(),
    );
  }
}
