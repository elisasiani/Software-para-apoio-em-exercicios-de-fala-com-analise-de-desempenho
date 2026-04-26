import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'access_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color _backgroundColor = Color(0xFFFFF0FF);
  static const Color _primaryColor = Color(0xFFBC4ED8);
  static const Color _accentColor = Color(0xFF7F00B2);
  static const Color _greenAccent = Color(0xFF9BFAB0);
  static const Color _yellowAccent = Color(0xFFFFC067);

  void _openRegister(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  void _openAccess(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AccessScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final viewportHeight = constraints.maxHeight;
            final scale = math.min(width / 363, viewportHeight / 812);
            final canvasHeight = math.max(viewportHeight, 812 * scale);
            final buttonWidth = math.min(225 * scale, width - (69 * scale * 2));
            final horizontalPadding = math.max(_scale(40, scale), width * 0.11);
            final contentWidth = width - (horizontalPadding * 2);
            final textOffset = _scale(24, scale);
            final titleWidth = math.min(
              _scale(220, scale),
              contentWidth - textOffset,
            );
            final bodyWidth = math.min(
              _scale(214, scale),
              contentWidth - textOffset,
            );
            final contentTop = _scale(232, scale);
            final contentBottom = _scale(220, scale);

            return SingleChildScrollView(
              child: SizedBox(
                width: width,
                height: canvasHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(color: _backgroundColor),
                    ),
                    Positioned(
                      left: _scale(-52, scale),
                      top: _scale(38, scale),
                      child: Transform.rotate(
                        angle: -0.4,
                        child: CustomPaint(
                          size: Size(_scale(165, scale), _scale(163, scale)),
                          painter: const _StarAssetPainter(_primaryColor),
                        ),
                      ),
                    ),
                    Positioned(
                      left: _scale(180, scale),
                      top: _scale(-50, scale),
                      child: Transform.rotate(
                        angle: 0.62,
                        child: CustomPaint(
                          size: Size(_scale(124, scale), _scale(134, scale)),
                          painter: const _PolygonAssetPainter(_greenAccent),
                        ),
                      ),
                    ),
                    Positioned(
                      right: _scale(-52, scale),
                      top: _scale(72, scale),
                      child: SizedBox(
                        width: _scale(156, scale),
                        height: _scale(152, scale),
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: _yellowAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          contentTop,
                          horizontalPadding,
                          contentBottom,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: buttonWidth,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Bem vindo!',
                                  style: TextStyle(
                                    color: _accentColor,
                                    fontSize: _scale(48, scale),
                                    fontWeight: FontWeight.w600,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: _scale(12, scale)),
                            SizedBox(
                              width: buttonWidth,
                              child: Text(
                                'Olá Amiguinho!\nPronto para treinar hoje?',
                                style: TextStyle(
                                  color: _accentColor,
                                  fontSize: _scale(20, scale),
                                  fontWeight: FontWeight.w300,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            SizedBox(height: _scale(32, scale)),
                            Center(
                              child: SizedBox(
                                width: buttonWidth,
                                height: _scale(57, scale),
                                child: ElevatedButton(
                                  onPressed: () => _openRegister(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        _scale(10, scale),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Cadastre-se',
                                    style: TextStyle(
                                      fontSize: _scale(24, scale),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: _scale(14, scale)),
                            Center(
                              child: SizedBox(
                                width: buttonWidth,
                                height: _scale(57, scale),
                                child: OutlinedButton(
                                  onPressed: () => _openAccess(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _accentColor,
                                    side: BorderSide(
                                      color: _accentColor,
                                      width: _scale(4, scale),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        _scale(10, scale),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Acesse',
                                    style: TextStyle(
                                      fontSize: _scale(24, scale),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SizedBox(
                        height: _scale(297, scale),
                        child: IgnorePointer(
                          child: Image.asset(
                            'assets/images/welcome_giraffe.png',
                            fit: BoxFit.fitWidth,
                            alignment: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static double _scale(double value, double scale) => value * scale;
}

class _PolygonAssetPainter extends CustomPainter {
  const _PolygonAssetPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 140.104;
    final scaleY = size.height / 133.908;
    final path = Path()
      ..moveTo(52.4002 * scaleX, 10.597 * scaleY)
      ..cubicTo(
        59.9269 * scaleX,
        -3.53234 * scaleY,
        80.1771 * scaleX,
        -3.53234 * scaleY,
        87.7037 * scaleX,
        10.597 * scaleY,
      )
      ..lineTo(137.728 * scaleX, 104.505 * scaleY)
      ..cubicTo(
        144.825 * scaleX,
        117.827 * scaleY,
        135.17 * scaleX,
        133.908 * scaleY,
        120.076 * scaleX,
        133.908 * scaleY,
      )
      ..lineTo(20.0276 * scaleX, 133.908 * scaleY)
      ..cubicTo(
        4.93359 * scaleX,
        133.908 * scaleY,
        -4.7206 * scaleX,
        117.827 * scaleY,
        2.37584 * scaleX,
        104.505 * scaleY,
      )
      ..lineTo(52.4002 * scaleX, 10.597 * scaleY)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PolygonAssetPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _StarAssetPainter extends CustomPainter {
  const _StarAssetPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 226.59;
    final scaleY = size.height / 223.771;
    final path = Path()
      ..moveTo(94.1791 * scaleX, 14.1196 * scaleY)
      ..cubicTo(
        99.9703 * scaleX,
        -4.70651 * scaleY,
        126.62 * scaleX,
        -4.70656 * scaleY,
        132.411 * scaleX,
        14.1196 * scaleY,
      )
      ..lineTo(144.874 * scaleX, 54.6338 * scaleY)
      ..cubicTo(
        147.456 * scaleX,
        63.0263 * scaleY,
        155.209 * scaleX,
        68.7534 * scaleY,
        163.99 * scaleX,
        68.7534 * scaleY,
      )
      ..lineTo(206.551 * scaleX, 68.7534 * scaleY)
      ..cubicTo(
        225.66 * scaleX,
        68.7534 * scaleY,
        233.886 * scaleX,
        92.9865 * scaleY,
        218.727 * scaleX,
        104.62 * scaleY,
      )
      ..lineTo(182.445 * scaleX, 132.463 * scaleY)
      ..cubicTo(
        175.816 * scaleX,
        137.55 * scaleY,
        173.048 * scaleX,
        146.223 * scaleY,
        175.505 * scaleX,
        154.21 * scaleY,
      )
      ..lineTo(188.914 * scaleX, 197.8 * scaleY)
      ..cubicTo(
        194.642 * scaleX,
        216.42 * scaleY,
        173.077 * scaleX,
        231.407 * scaleY,
        157.622 * scaleX,
        219.546 * scaleY,
      )
      ..lineTo(125.471 * scaleX, 194.874 * scaleY)
      ..cubicTo(
        118.289 * scaleX,
        189.362 * scaleY,
        108.301 * scaleX,
        189.362 * scaleY,
        101.119 * scaleX,
        194.874 * scaleY,
      )
      ..lineTo(68.9682 * scaleX, 219.546 * scaleY)
      ..cubicTo(
        53.513 * scaleX,
        231.407 * scaleY,
        31.9481 * scaleX,
        216.42 * scaleY,
        37.6761 * scaleX,
        197.8 * scaleY,
      )
      ..lineTo(51.085 * scaleX, 154.21 * scaleY)
      ..cubicTo(
        53.5419 * scaleX,
        146.223 * scaleY,
        50.7743 * scaleX,
        137.55 * scaleY,
        44.1451 * scaleX,
        132.463 * scaleY,
      )
      ..lineTo(7.86303 * scaleX, 104.62 * scaleY)
      ..cubicTo(
        -7.29618 * scaleX,
        92.9865 * scaleY,
        0.93052 * scaleX,
        68.7534 * scaleY,
        20.0391 * scaleX,
        68.7534 * scaleY,
      )
      ..lineTo(62.6003 * scaleX, 68.7534 * scaleY)
      ..cubicTo(
        71.3809 * scaleX,
        68.7534 * scaleY,
        79.1346 * scaleX,
        63.0263 * scaleY,
        81.7163 * scaleX,
        54.6338 * scaleY,
      )
      ..lineTo(94.1791 * scaleX, 14.1196 * scaleY)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _StarAssetPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
