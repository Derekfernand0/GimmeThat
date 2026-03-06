import 'package:flutter/material.dart';

void main() {
  // Aquí inicializaremos Firebase más adelante
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Por ahora, mostraremos una pantalla temporal
      home: const Scaffold(
        body: Center(child: Text('¡App configurada correctamente!')),
      ),
    );
  }
}
