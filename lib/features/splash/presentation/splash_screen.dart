// lib/features/splash/presentation/splash_screen.dart

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
// Importamos tu compuerta de autenticación para ir allí al terminar
import '../../auth/presentation/auth_gate.dart';

// Helper para opacidades limpias
Color _withOpacity(Color color, double opacity) =>
    color.withValues(alpha: (color.a * opacity).clamp(0.0, 1.0));

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Logo
  late final Animation<double> _logoScale;
  late final Animation<double> _logoRotate;
  late final Animation<double> _logoContainerFactor;

  // Text
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;

  // Background / fx
  late final Animation<double> _blur;
  late final Animation<double> _glowPulse;
  late final Animation<double> _finalBounce;

  // Duración de la intro (3.5 segundos de magia)
  static const _duration = Duration(milliseconds: 3500);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: _duration);

    // Animaciones suaves y rebotonas (estilo Fluttershy)
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.elasticOut),
      ),
    );

    _logoRotate = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _logoContainerFactor = Tween<double>(begin: 1.0, end: 0.35).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.68, curve: Curves.easeInOutCubic),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0.5, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.50, 0.85, curve: Curves.easeOutCubic),
          ),
        );

    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.50, 0.85)),
    );

    _blur = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );

    _glowPulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _finalBounce = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.80, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Al terminar, hacemos un "Fade" suave hacia la aplicación
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthGate(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(
              milliseconds: 800,
            ), // Transición súper suave
          ),
        );
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _logoSizeFor(BoxConstraints c) {
    final shortest = math.min(c.maxWidth, c.maxHeight);
    return (shortest * 0.22).clamp(90.0, 150.0);
  }

  @override
  Widget build(BuildContext context) {
    // Paleta de colores inspirada en Fluttershy 🌸🦋
    const Color cream = Color(0xFFFFFDF7);
    const Color pastelYellow = Color(0xFFFFF59D);
    const Color pastelPink = Color(0xFFF8BBD0);
    const Color pastelGreen = Color(0xFFC8E6C9);

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoSize = _logoSizeFor(constraints);

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final double t = _controller.value;
                final double sin = math.sin(t * math.pi * 2);
                final double glowDx = sin * 20;
                final double glowDy = math.cos(t * math.pi * 1.5) * 15;

                // --- CORRECCION MATEMATICA: Evitar el desbordamiento de la fila ---
                // 1. Calculamos el limite estricto de la fila (95% de la pantalla o max 600px)
                final double maxRowWidth = math.min(
                  constraints.maxWidth * 0.95,
                  600,
                );

                // 2. Basamos el area del logo en ese nuevo limite (dejando 10px libres para evitar choques)
                final double leftArea =
                    (maxRowWidth * _logoContainerFactor.value).clamp(
                      logoSize + 24,
                      maxRowWidth - 10,
                    );
                // ------------------------------------------------------------------

                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomRight,
                      colors: [
                        cream,
                        _withOpacity(pastelYellow, 0.4),
                        _withOpacity(pastelPink, 0.3),
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Brillo Verde Suave (Naturaleza)
                      Positioned(
                        left: constraints.maxWidth * 0.05 + glowDx,
                        top: constraints.maxHeight * 0.15 + glowDy,
                        child: RepaintBoundary(
                          child: Transform.scale(
                            scale: _glowPulse.value,
                            child: _GlowCircle(
                              color: _withOpacity(pastelGreen, 0.5),
                              size: math.max(constraints.maxWidth * 0.35, 200),
                            ),
                          ),
                        ),
                      ),

                      // Brillo Rosa Suave (Amabilidad)
                      Positioned(
                        right: constraints.maxWidth * 0.05 - glowDx,
                        bottom: constraints.maxHeight * 0.15 - glowDy,
                        child: RepaintBoundary(
                          child: Transform.scale(
                            scale: 1.0 / _glowPulse.value + 0.05,
                            child: _GlowCircle(
                              color: _withOpacity(pastelPink, 0.5),
                              size: math.max(constraints.maxWidth * 0.3, 180),
                            ),
                          ),
                        ),
                      ),

                      BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: _blur.value,
                          sigmaY: _blur.value,
                        ),
                        child: Container(color: Colors.transparent),
                      ),

                      Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          // 3. Usamos la misma variable limite para la caja constructora
                          constraints: BoxConstraints(maxWidth: maxRowWidth),
                          child: SizedBox(
                            height: constraints.maxHeight * 0.4,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: leftArea,
                                  child: Center(
                                    child: Transform.scale(
                                      scale:
                                          _logoScale.value * _finalBounce.value,
                                      child: Transform.rotate(
                                        angle: _logoRotate.value,
                                        child: _LogoWidget(size: logoSize),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FractionalTranslation(
                                    translation: const Offset(0.0, 0.0),
                                    child: SlideTransition(
                                      position: _textSlide,
                                      child: FadeTransition(
                                        opacity: _textFade,
                                        child: _SplashTextBlock(
                                          controllerValue: _controller.value,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// WIDGETS INTERNOS
// ----------------------------------------------------------------------

class _LogoWidget extends StatelessWidget {
  final double size;
  const _LogoWidget({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF8BBD0).withValues(alpha: 0.4),
            blurRadius: 25,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          // Aquí carga tu logo de assets de forma segura
          child: Image.asset(
            'lib/assets/images/logo_transparent.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.favorite,
                color: Color(0xFFF8BBD0),
                size: 40,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, _withOpacity(color, 0.5), Colors.transparent],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _SplashTextBlock extends StatelessWidget {
  final double controllerValue;
  const _SplashTextBlock({required this.controllerValue});

  @override
  Widget build(BuildContext context) {
    final double t = controllerValue;
    const Color darkBrown = Color(0xFF5D4037);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Efecto Shimmer mágico en el texto
        ShaderMask(
          shaderCallback: (bounds) {
            final double offset = (t * 2.0) % 1.0;
            return LinearGradient(
              begin: Alignment(-1.0 + offset * 2, 0),
              end: Alignment(1.0 + offset * 2, 0),
              colors: [
                darkBrown,
                const Color(0xFFA1887F), // Café claro (brillo)
                darkBrown,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: Text(
            'GimmeThat',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: darkBrown,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: math.max(28, MediaQuery.of(context).size.width * 0.06),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Organiza con amabilidad 🦋',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: darkBrown.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
            fontSize: math.max(14, MediaQuery.of(context).size.width * 0.035),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Flexible(
              child: Text(
                'Preparando magia...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: darkBrown.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
                overflow:
                    TextOverflow.ellipsis, // Si no cabe, pone 3 puntos (...)
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: const [
                _DotPulse(index: 0),
                SizedBox(width: 4),
                _DotPulse(index: 1),
                SizedBox(width: 4),
                _DotPulse(index: 2),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _DotPulse extends StatefulWidget {
  final int index;
  const _DotPulse({required this.index});

  @override
  State<_DotPulse> createState() => _DotPulseState();
}

class _DotPulseState extends State<_DotPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
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
        final double phase = (_dotController.value + widget.index * 0.2) % 1.0;
        final double scale = 0.5 + (math.sin(phase * 2 * math.pi) + 1) * 0.25;
        final double opacity = 0.3 + (math.cos(phase * 2 * math.pi) + 1) * 0.35;

        return Transform.scale(
          scale: scale,
          child: Container(
            height: 6,
            width: 6,
            decoration: BoxDecoration(
              color: const Color(
                0xFFF8BBD0,
              ).withValues(alpha: opacity), // Puntitos rosas
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
