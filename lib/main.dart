import 'package:ukk_2025/login.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://rxpyhqwzwdhenygseojs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ4cHlocXd6d2RoZW55Z3Nlb2pzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg3MTM4MDMsImV4cCI6MjA1NDI4OTgwM30.yHxgHSwL4SsdNwi4I8AnP_4g0gQM-F3hnjxB4y28POQ',
  );
  runApp(MyApp());
}
        

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
   return MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Login',
    home : LoginPage()
   );
    
  }
}

