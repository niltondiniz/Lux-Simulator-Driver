import 'package:driver/pages/home.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lux Motorista',
      theme: ThemeData(        
        primarySwatch: Colors.blue
        
      ),
      home: const HomePage(title: 'Lux Motorista'),
    );
  } 
}