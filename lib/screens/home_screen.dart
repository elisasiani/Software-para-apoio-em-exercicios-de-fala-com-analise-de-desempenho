import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../models/exercicio.dart';
import '../models/user_progress.dart';
import 'trilha_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.nomeUsuario = 'Amiguinho',
    this.onTabSelected,
  });

  final String nomeUsuario;
  final ValueChanged<int>? onTabSelected;

  static const List<String> _labelsSemana = ['D','S','T','Q','Q','S','S'];

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProgress>(
      builder: (context, progresso, child) {
        return DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFFF5C6F5)),
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: _TopSection(nomeUsuario: _formatarNome(nomeUsuario)),
                          ),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _ContentSection(progresso: progresso),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: _HomeBottomBar(onTabSelected: onTabSelected),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatarNome(String valor) {
    final texto = valor.trim();
    if (texto.isEmpty) return 'Amiguinho';
    final base = texto.contains('@') ? texto.split('@').first : texto;
    final palavras = base
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (palavras.isEmpty) return 'Amiguinho';
    return palavras
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }
}

class _TopSection extends StatelessWidget {
  const _TopSection({required this.nomeUsuario});
  final String nomeUsuario;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 0, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Texto de saudação — ocupa todo espaço disponível
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Estrela amarela decorativa acima do texto
                SvgPicture.asset(
                  'assets/images/home_star_yellow.png',
                  width: 16,
                ),
                const SizedBox(height: 60),
                Text(
                  'Olá ${nomeUsuario},',
                  style: const TextStyle(
                    color: Color(0xFF4A1A6E),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'O que Vamos Treinar Hoje?',
                  style: TextStyle(
                    color: Color(0xFF4A1A6E),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          // Girafa à direita
          Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                'assets/images/home_giraffe.png',
                width: 190,
                fit: BoxFit.contain,
              ),
              // Estrela verde ao lado da girafa
              Positioned(
                right: 4,
                bottom: 40,
                child: SvgPicture.asset(
                  'assets/images/home_star_green.png',
                  width: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  const _ContentSection({required this.progresso});
  final UserProgress progresso;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFCF0FF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StreakSection(progresso: progresso),
          const SizedBox(height: 22),
          const Text(
            'Suas Trilhas',
            style: TextStyle(
              color: Color(0xFF7B2FBE),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _TrilhaCard(
            trilha: DadosApp.trilhas.firstWhere((t) => t.id == 'fonemas'),
            backgroundColor: const Color(0xFFFFCC80),
            iconAsset: 'assets/images/home_fonemas_icon.png',
            progresso: progresso.getProgressoTrilha('fonemas'),
            total: DadosApp.trilhas.firstWhere((t) => t.id == 'fonemas').exercicios.length,
          ),
          const SizedBox(height: 14),
          _TrilhaCard(
            trilha: DadosApp.trilhas.firstWhere((t) => t.id == 'trava_linguas'),
            backgroundColor: const Color(0xFFFFB4DF),
            iconAsset: 'assets/images/home_trava_icon.png',
            progresso: progresso.getProgressoTrilha('trava_linguas'),
            total: DadosApp.trilhas.firstWhere((t) => t.id == 'trava_linguas').exercicios.length,
          ),
        ],
      ),
    );
  }
}

class _StreakSection extends StatelessWidget {
  const _StreakSection({required this.progresso});
  final UserProgress progresso;

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final diaAtual = DateTime(hoje.year, hoje.month, hoje.day);
    final inicioSemana = diaAtual.subtract(
      Duration(days: diaAtual.weekday % DateTime.daysPerWeek),
    );
    final atividadeSemana = progresso.getAtividadeSemanaAtual(referenceDate: diaAtual);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sua Sequência',
          style: TextStyle(
            color: Color(0xFF7B2FBE),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFB8F07A),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Image.asset('assets/images/home_streak_fire.png', width: 36),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List<Widget>.generate(
                    HomeScreen._labelsSemana.length,
                    (index) {
                      final data = inicioSemana.add(Duration(days: index));
                      return _DiaChip(
                        label: HomeScreen._labelsSemana[index],
                        concluido: atividadeSemana[index],
                        ehHoje: _mesmaData(data, diaAtual),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _mesmaData(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DiaChip extends StatelessWidget {
  const _DiaChip({
    required this.label,
    required this.concluido,
    required this.ehHoje,
  });
  final String label;
  final bool concluido;
  final bool ehHoje;

  @override
  Widget build(BuildContext context) {
    final Color fillColor;
    final Color borderColor;
    final Color textColor;

    if (concluido) {
      fillColor = const Color(0xFF5CAD4E);
      borderColor = const Color(0xFF5CAD4E);
      textColor = Colors.white;
    } else if (ehHoje) {
      fillColor = Colors.white;
      borderColor = const Color(0xFF3A7D44);
      textColor = const Color(0xFF3A7D44);
    } else {
      fillColor = Colors.white;
      borderColor = const Color(0xFFA8D880);
      textColor = const Color(0xFF6DB56D);
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: fillColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.8),
      ),
      child: Center(
        child: concluido
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _TrilhaCard extends StatelessWidget {
  const _TrilhaCard({
    required this.trilha,
    required this.backgroundColor,
    required this.iconAsset,
    required this.progresso,
    required this.total,
  });
  final Trilha trilha;
  final Color backgroundColor;
  final String iconAsset;
  final int progresso;
  final int total;

  @override
  Widget build(BuildContext context) {
    final double pct = total > 0 ? progresso / total : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TrilhaScreen(trilha: trilha)),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            // Icone
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.55),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(6),
              child: Image.asset(iconAsset, fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
            // Texto + barra
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trilha.titulo,
                    style: const TextStyle(
                      color: Color(0xFF5C1A8A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    trilha.subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7A4490),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 5,
                            backgroundColor: Colors.white.withOpacity(0.6),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF7B2FBE),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$progresso/$total',
                        style: const TextStyle(
                          color: Color(0xFF5C1A8A),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF7B2FBE),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBottomBar extends StatelessWidget {
  const _HomeBottomBar({required this.onTabSelected});
  final ValueChanged<int>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEDDF8), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomBarItem(
            label: 'Trilhas',
            iconAsset: 'assets/images/home_nav_trilhas.png',
            selected: true,
            onTap: () => onTabSelected?.call(0),
          ),
          _BottomBarItem(
            label: 'Relatório',
            iconAsset: 'assets/images/home_nav_relatorio.png',
            selected: false,
            onTap: () => onTabSelected?.call(1),
          ),
          _BottomBarItem(
            label: 'Perfil',
            iconAsset: 'assets/images/home_nav_perfil.png',
            selected: false,
            onTap: () => onTabSelected?.call(2),
          ),
        ],
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.label,
    required this.iconAsset,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String iconAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(iconAsset, width: 26, fit: BoxFit.contain),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF7B2FBE)
                    : const Color(0xFFAA88CC),
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
