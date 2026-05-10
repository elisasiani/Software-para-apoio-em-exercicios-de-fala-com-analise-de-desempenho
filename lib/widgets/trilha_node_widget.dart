import 'package:flutter/material.dart';

// Enum: tipo especial que define opções fixas para o estado de um nó
// Usar enum evita bugs com strings soltas como 'completo', 'Completo', etc.
enum EstadoNo {
  completo,    // Exercício feito ✅
  disponivel,  // Próximo a fazer 🔓
  bloqueado,   // Ainda não chegou lá 🔒
}

// Widget de cada bolinha/nó na trilha do mapa
class TrilhaNodeWidget extends StatelessWidget {
  final int numero;         // Qual exercício é (1 a 5)
  final EstadoNo estado;    // Estado atual do nó
  final VoidCallback? onTap; // Função chamada quando o usuário toca

  const TrilhaNodeWidget({
    super.key,
    required this.numero,
    required this.estado,
    this.onTap,
  });

  // Retorna as cores certas para cada estado
  Color _getCorFundo() {
    switch (estado) {
      case EstadoNo.completo:
        return const Color(0xFF7B2FBE);    // Roxo cheio
      case EstadoNo.disponivel:
        return const Color(0xFFCE93D8);    // Lilás
      case EstadoNo.bloqueado:
        return const Color(0xFFE0E0E0);    // Cinza
    }
  }

  // Retorna o ícone ou número certo para cada estado
  Widget _getConteudo() {
    switch (estado) {
      case EstadoNo.completo:
        return const Icon(Icons.star_rounded, color: Colors.yellow, size: 32);
      case EstadoNo.bloqueado:
        return const Icon(Icons.lock_rounded, color: Colors.grey, size: 28);
      case EstadoNo.disponivel:
        return Text(
          '$numero',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector: detecta toques. Só habilita se o estado for disponivel.
    return GestureDetector(
      onTap: estado == EstadoNo.disponivel ? onTap : null,
      child: AnimatedContainer(
        // AnimatedContainer: transiciona automaticamente quando as propriedades mudam
        duration: const Duration(milliseconds: 300),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getCorFundo(),
          boxShadow: estado == EstadoNo.disponivel
              ? [
                  BoxShadow(
                    color: const Color(0xFF7B2FBE).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
          border: estado == EstadoNo.disponivel
              ? Border.all(color: Colors.white, width: 3)
              : null,
        ),
        child: Center(child: _getConteudo()),
      ),
    );
  }
}