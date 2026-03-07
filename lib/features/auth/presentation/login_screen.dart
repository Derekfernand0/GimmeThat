// lib/features/auth/presentation/login_screen.dart

import 'package:flutter/material.dart';
import '../data/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Conectamos nuestro servicio de Firebase
  final AuthService _authService = AuthService();

  // Controladores para leer lo que el usuario escribe en las cajas de texto
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  // Variables para controlar el estado de la pantalla
  bool _isLogin = true; // ¿Estamos en modo Login o Registro?
  bool _isLoading = false; // ¿Está cargando (conectándose a internet)?

  // Función que se ejecuta al presionar el botón principal
  void _submit() async {
    setState(() {
      _isLoading = true; // Mostramos la ruedita de carga
    });

    try {
      if (_isLogin) {
        // Modo: Iniciar sesión
        await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        // Modo: Registro
        await _authService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _usernameController.text.trim(),
        );
      }
      // Nota: Si el login es exitoso, luego haremos que pase a otra pantalla.
      // Por ahora, si todo sale bien, simplemente dejará de cargar.
    } catch (e) {
      // Si hay error (contraseña corta, correo inválido), mostramos un mensaje
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false; // Ocultamos la ruedita de carga
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Aquí irá tu ilustración de la pony/mariposa en el futuro
                // AQUÍ VA TU NUEVO LOGO:
                Image.asset(
                  'lib/assets/images/logo_transparent.png',
                  height:
                      150, // Puedes ajustar este número para hacerlo más grande o pequeño
                ),
                const SizedBox(height: 40),

                Text(
                  _isLogin ? '¡Hola, estudiante!' : 'Únete al grupo',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isLogin
                      ? 'Qué gusto verte de nuevo 🦋'
                      : 'Prepárate para organizarte 🌸',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 40),

                if (!_isLogin)
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Tu apodo amigable',
                      prefixIcon: Icon(Icons.face, color: Color(0xFFF8BBD0)),
                    ),
                  ),
                if (!_isLogin) const SizedBox(height: 20),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: Color(0xFFF8BBD0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña secreta',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Color(0xFFF8BBD0),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.brown)
                        : Text(
                            _isLogin ? 'Entrar al jardín' : 'Crear mi espacio',
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(
                    _isLogin
                        ? '¿Eres nuevo? Crea tu cuenta aquí 🌱'
                        : '¿Ya nos conocemos? Entra aquí 🦋',
                    style: const TextStyle(
                      color: Color(0xFF5D4037),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
