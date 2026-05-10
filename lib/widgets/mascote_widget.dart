import 'package:flutter/material.dart';

// Widget do Mascote Girafa
// É um StatefulWidget porque ele tem animação própria (piscar, balançar).
// SingleTickerProviderStateMixin: fornece o "relógio" para a animação.
// É um mixin, ou seja, adiciona funcionalidade à classe sem herança.
class MascoteWidget extends StatefulWidget {
  final String mensagem;   // Texto que a girafa vai "falar"
  final String animacao;   // Qual animação mostrar: 'idle', 'falando', 'comemorando'

  const MascoteWidget({
    super.key,
    this.mensagem = 'Vamos treinar juntos!',
    this.animacao = 'idle',
  });

  @override
  State<MascoteWidget> createState() => _MascoteWidgetState();
}

class _MascoteWidgetState extends State<MascoteWidget>
    with SingleTickerProviderStateMixin {
  
  // AnimationController: o "motor" da animação
  // Controla duração, repetição, direção
  late AnimationController _controller;

  // Animation<double>: define os valores que vão mudar (de 0.0 a 1.0, etc.)
  late Animation<double> _scalingAnimation;

  @override
  void initState() {
    super.initState();
    
    // Cria o motor com 1.5 segundos de duração, repetindo para sempre
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this, // 'this' funciona por causa do SingleTickerProviderStateMixin
    )..repeat(reverse: true); // repeat(reverse: true) = vai e volta

    // Tween: define o intervalo da animação (de 1.0 a 1.05 = pequeno "pulso")
    _scalingAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // SEMPRE libere o controller quando o widget for removido da tela
    // Evita vazamento de memória (memory leak)
    _controller.dispose();
    super.dispose();
  }

  // Retorna o emoji certo dependendo da animação pedida
  String _getEmojiPorAnimacao() {
    switch (widget.animacao) {
      case 'falando':
        return '🦒💬';
      case 'comemorando':
        return '🦒🎉';
      case 'pensando':
        return '🦒🤔';
      default:
        return '🦒'; // idle
    }
  }

  @override
  Widget build(BuildContext context) {
    // ScaleTransition: aplica a animação de escala ao filho
    return ScaleTransition(
      scale: _scalingAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B2FBE).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Placeholder do mascote — substituir por Lottie animation
            // Pacote recomendado: 'lottie: ^3.1.0' no pubspec.yaml
            // Uso: Lottie.asset('assets/animations/girafa_idle.json')
            Text(
              _getEmojiPorAnimacao(),
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 8),
            // Balão de fala da girafa
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCE93D8), width: 1.5),
              ),
              child: Text(
                widget.mensagem,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF4A148C),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}