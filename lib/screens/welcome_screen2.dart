import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'access_screen.dart';

/// Classe de estilos para centralizar a tipografia e cores da tela.
/// Segue os princípios de Clean Code ao separar a aparência da estrutura.
class _WelcomeStyles {
  static const String fontFamily = 'LeagueSpartan';
  static const Color accentColor = Color(0xFF7F00B2);
  static const Color primaryColor = Color(0xFFBC4ED8);
  static const Color greenAccent = Color(0xFF9BFAB0);
  static const Color yellowAccent = Color(0xFFFFC067);
  static const Color backgroundColor = Color(0xFFFFF0FF);

  static TextStyle titleStyle(double scale) => TextStyle(
        fontFamily: fontFamily,
        color: accentColor,
        fontSize: 50 * scale,
        fontWeight: FontWeight.w500,
        height: 1.0,
      );

  static TextStyle subtitleStyle(double scale) => TextStyle(
        fontFamily: fontFamily,
        color: accentColor,
        fontSize: 20 * scale,
        fontWeight: FontWeight.w400,
        height: 1.2,
      );

  static TextStyle buttonTextStyle(double scale) => TextStyle(
        fontFamily: fontFamily,
        color: accentColor,
        fontSize: 25 * scale,
        fontWeight: FontWeight.w500,
      );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _openAccess(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AccessScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _WelcomeStyles.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final scale = math.min(width / 375, height / 850);

            return DefaultTextStyle(
              style: const TextStyle(fontFamily: _WelcomeStyles.fontFamily),
              child: Stack(
                children: [
                  // 1. Formas de Fundo (Decorativas - Camada Inferior)
                  _buildBackgroundShapes(scale),
                  
                  // 2. Estrutura de Conteúdo (Camada Superior)
                  SizedBox(
                    width: width,
                    height: height,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Espaçador para o topo (ajusta conforme as formas decorativas)
                        SizedBox(height: 160 * scale),
                        
                        // Bloco central com Expanded para centralização vertical absoluta
                        Expanded(
                          child: Center(
                            child: _buildMainContent(context, scale),
                          ),
                        ),
                        
                        // Imagem de Rodapé (Sempre na base)
                        _buildFooterImage(width),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Constrói as formas geométricas do topo.
  Widget _buildBackgroundShapes(double scale) {
    return Stack(
      children: [
        Positioned(
          left: -60 * scale,
          top: 30 * scale,
          child: Transform.rotate(
            angle: -0.4,
            child: CustomPaint(
              size: Size(170 * scale, 170 * scale),
              painter: const _StarAssetPainter(_WelcomeStyles.primaryColor),
            ),
          ),
        ),
        Positioned(
          left: 135 * scale,
          top: -50 * scale,
          child: Transform.rotate(
            angle: 0.5,
            child: CustomPaint(
              size: Size(150 * scale, 150 * scale),
              painter: const _PolygonAssetPainter(_WelcomeStyles.greenAccent),
            ),
          ),
        ),
        Positioned(
          right: -55 * scale,
          top: 60 * scale,
          child: Container(
            width: 160 * scale,
            height: 160 * scale,
            decoration: const BoxDecoration(
              color: _WelcomeStyles.yellowAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  /// Constrói o conteúdo principal (Textos e Botão).
  Widget _buildMainContent(BuildContext context, double scale) {
    return SizedBox(
      width: 250 * scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, // Alinhamento interno à esquerda
        children: [
          Text(
            'Bem vindo!',
            style: _WelcomeStyles.titleStyle(scale),
          ),
          SizedBox(height: 10 * scale),
          Text(
            'Olá Amiguinho!\nPronto para treinar hoje?',
            style: _WelcomeStyles.subtitleStyle(scale),
          ),
          SizedBox(height: 30 * scale),
          _buildAccessButton(context, scale),
        ],
      ),
    );
  }

  /// Constrói o botão de acesso que preenche a largura do bloco.
  Widget _buildAccessButton(BuildContext context, double scale) {
    return SizedBox(
      width: double.infinity,
      height: 55 * scale,
      child: OutlinedButton(
        onPressed: () => _openAccess(context),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          side: BorderSide(
            color: _WelcomeStyles.accentColor,
            width: 4 * scale,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10 * scale),
          ),
        ),
        child: Text(
          'Acesse',
          style: _WelcomeStyles.buttonTextStyle(scale),
        ),
      ),
    );
  }

  /// Constrói a imagem SVG no rodapé ocupando toda a largura.
  Widget _buildFooterImage(double width) {
    return SvgPicture.asset(
      'assets/images/Prancheta2.svg',
      width: width,
      fit: BoxFit.fitWidth,
      alignment: Alignment.bottomCenter,
      placeholderBuilder: (BuildContext context) => const SizedBox.shrink(),
    );
  }
}

// --- Custom Painters mantidos para as formas ---
class _PolygonAssetPainter extends CustomPainter {
  const _PolygonAssetPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 140.104;
    final scaleY = size.height / 133.908;
    final path = Path()
      ..moveTo(52.4002 * scaleX, 10.597 * scaleY)
      ..cubicTo(59.9269 * scaleX, -3.53234 * scaleY, 80.1771 * scaleX, -3.53234 * scaleY, 87.7037 * scaleX, 10.597 * scaleY)
      ..lineTo(137.728 * scaleX, 104.505 * scaleY)
      ..cubicTo(144.825 * scaleX, 117.827 * scaleY, 135.17 * scaleX, 133.908 * scaleY, 120.076 * scaleX, 133.908 * scaleY)
      ..lineTo(20.0276 * scaleX, 133.908 * scaleY)
      ..cubicTo(4.93359 * scaleX, 133.908 * scaleY, -4.7206 * scaleX, 117.827 * scaleY, 2.37584 * scaleX, 104.505 * scaleY)
      ..lineTo(52.4002 * scaleX, 10.597 * scaleY)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }
  @override
  bool shouldRepaint(covariant _PolygonAssetPainter oldDelegate) => oldDelegate.color != color;
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
      ..cubicTo(99.9703 * scaleX, -4.70651 * scaleY, 126.62 * scaleX, -4.70656 * scaleY, 132.411 * scaleX, 14.1196 * scaleY)
      ..lineTo(144.874 * scaleX, 54.6338 * scaleY)
      ..cubicTo(147.456 * scaleX, 63.0263 * scaleY, 155.209 * scaleX, 68.7534 * scaleY, 163.99 * scaleX, 68.7534 * scaleY)
      ..lineTo(206.551 * scaleX, 68.7534 * scaleY)
      ..cubicTo(225.66 * scaleX, 68.7534 * scaleY, 233.886 * scaleX, 92.9865 * scaleY, 218.727 * scaleX, 104.62 * scaleY)
      ..lineTo(182.445 * scaleX, 132.463 * scaleY)
      ..cubicTo(175.816 * scaleX, 137.55 * scaleY, 173.048 * scaleX, 146.223 * scaleY, 175.505 * scaleX, 154.21 * scaleY)
      ..lineTo(188.914 * scaleX, 197.8 * scaleY)
      ..cubicTo(194.642 * scaleX, 216.42 * scaleY, 173.077 * scaleX, 231.407 * scaleY, 157.622 * scaleX, 219.546 * scaleY)
      ..lineTo(125.471 * scaleX, 194.874 * scaleY)
      ..cubicTo(118.289 * scaleX, 189.362 * scaleY, 108.301 * scaleX, 189.362 * scaleY, 101.119 * scaleX, 194.874 * scaleY)
      ..lineTo(68.9682 * scaleX, 219.546 * scaleY)
      ..cubicTo(53.513 * scaleX, 231.407 * scaleY, 31.9481 * scaleX, 216.42 * scaleY, 37.6761 * scaleX, 197.8 * scaleY)
      ..lineTo(51.085 * scaleX, 154.21 * scaleY)
      ..cubicTo(53.5419 * scaleX, 146.223 * scaleY, 50.7743 * scaleX, 137.55 * scaleY, 44.1451 * scaleX, 132.463 * scaleY)
      ..lineTo(7.86303 * scaleX, 104.62 * scaleY)
      ..cubicTo(-7.29618 * scaleX, 92.9865 * scaleY, 0.93052 * scaleX, 68.7534 * scaleY, 20.0391 * scaleX, 68.7534 * scaleY)
      ..lineTo(62.6003 * scaleX, 68.7534 * scaleY)
      ..cubicTo(71.3809 * scaleX, 68.7534 * scaleY, 79.1346 * scaleX, 63.0263 * scaleY, 81.7163 * scaleX, 54.6338 * scaleY)
      ..lineTo(94.1791 * scaleX, 14.1196 * scaleY)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }
  @override
  bool shouldRepaint(covariant _StarAssetPainter oldDelegate) => oldDelegate.color != color;
}
