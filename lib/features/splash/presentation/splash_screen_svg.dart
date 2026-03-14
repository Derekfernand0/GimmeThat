// lib/features/splash/presentation/splash_screen_svg.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../auth/presentation/auth_gate.dart';

class SplashScreenSvg extends StatefulWidget {
  const SplashScreenSvg({super.key});

  @override
  State<SplashScreenSvg> createState() => _SplashScreenSvgState();
}

class _SplashScreenSvgState extends State<SplashScreenSvg>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // --- FASE 1: Formación del Logo (Escalado por capas) ---
  late Animation<double> _capa1Scale;
  late Animation<double> _capa2Scale;
  late Animation<double> _capa3Scale;
  late Animation<double> _capa4Scale;

  // --- FASE 2: Mitosis (Movimiento y tamaño) ---
  late Animation<double> _logoSizeDown; // Reduce el logo de grande a normal
  late Animation<Offset> _logoSlide; // Mueve el logo a la izquierda
  late Animation<Offset>
  _textSlide; // Mueve el texto a la derecha (desde atrás)
  late Animation<double> _textOpacity; // Aparece el texto suavemente

  @override
  void initState() {
    super.initState();

    // Animación un poco más larga (4 segundos) para disfrutar el ensamble
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // 1. Las capas hacen un "Pop" elástico formándose en el centro
    _capa1Scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.20, curve: Curves.elasticOut),
      ),
    );
    _capa2Scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.10, 0.30, curve: Curves.elasticOut),
      ),
    );
    _capa3Scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.40, curve: Curves.elasticOut),
      ),
    );
    _capa4Scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.50, curve: Curves.elasticOut),
      ),
    );

    // 2. Mitosis: El logo se hace más pequeño (de 1.5x a 1.0x)
    _logoSizeDown = Tween<double>(begin: 1.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.85, curve: Curves.easeInOutCubic),
      ),
    );

    // 3. Mitosis: El logo se mueve a la izquierda
    _logoSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.8, 0.0))
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.65, 0.85, curve: Curves.easeInOutCubic),
          ),
        );

    // 4. Mitosis: El texto sale de ATRÁS del logo hacia la derecha
    _textSlide =
        Tween<Offset>(
          begin: const Offset(-0.5, 0.0),
          end: const Offset(0.5, 0.0),
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.65, 0.85, curve: Curves.easeOutCubic),
          ),
        );

    // El texto aparece mientras sale de atrás
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.85, curve: Curves.easeIn),
      ),
    );

    // Iniciamos la magia
    _controller.forward();

    // Navegación automática al terminar (4.8 segundos para dar un respiro al final)
    Timer(const Duration(milliseconds: 4800), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (_, __, ___) => const AuthGate(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tomamos el tema actual (Para que respete el Modo Oscuro o Custom)
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores de los textos adaptables al tema
    final titleColor = isDark ? Colors.white : const Color(0xFF5D4037);
    final subtitleColor = isDark
        ? Colors.white70
        : const Color(0xFF5D4037).withOpacity(0.8);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Usamos un Stack centrado. Así nada choca con los bordes (adiós error de ParentData)
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // ==========================================
                // CAPA TRASERA: EL TEXTO (Nace desde el centro)
                // ==========================================
                FractionalTranslation(
                  translation: _textSlide.value,
                  child: Opacity(
                    opacity: _textOpacity.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GimmeThat',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Organiza con amabilidad 🦋',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: subtitleColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Preparando magia...',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: subtitleColor.withOpacity(0.5),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _BlinkingDots(color: theme.primaryColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ==========================================
                // CAPA FRONTAL: EL LOGO (Tapa al texto al inicio)
                // ==========================================
                FractionalTranslation(
                  translation: _logoSlide.value,
                  child: Transform.scale(
                    scale: _logoSizeDown.value,
                    child: SizedBox(
                      width: 140, // Tamaño base del logo
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Capa 1
                          Transform.scale(
                            scale: _capa1Scale.value,
                            child: SvgPicture.asset(
                              'lib/assets/icons/logo/capa1.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                          // Capa 2
                          Transform.scale(
                            scale: _capa2Scale.value,
                            child: SvgPicture.asset(
                              'lib/assets/icons/logo/capa2.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                          // Capa 3
                          Transform.scale(
                            scale: _capa3Scale.value,
                            child: SvgPicture.asset(
                              'lib/assets/icons/logo/capa3.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                          // Capa 4
                          Transform.scale(
                            scale: _capa4Scale.value,
                            child: SvgPicture.asset(
                              'lib/assets/icons/logo/capa4.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Mini-widget para los puntitos parpadeantes
class _BlinkingDots extends StatefulWidget {
  final Color color;
  const _BlinkingDots({required this.color});

  @override
  State<_BlinkingDots> createState() => _BlinkingDotsState();
}

class _BlinkingDotsState extends State<_BlinkingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotController,
      builder: (context, child) {
        return Row(
          children: [
            _buildDot(0.0),
            const SizedBox(width: 4),
            _buildDot(0.3),
            const SizedBox(width: 4),
            _buildDot(0.6),
          ],
        );
      },
    );
  }

  Widget _buildDot(double offset) {
    final double opacity = ((_dotController.value + offset) % 1.0).clamp(
      0.2,
      1.0,
    );
    return Container(
      height: 6,
      width: 6,
      decoration: BoxDecoration(
        color: widget.color.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
