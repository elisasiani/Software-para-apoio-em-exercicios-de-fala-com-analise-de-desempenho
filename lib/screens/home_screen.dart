import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../models/user_progress.dart';
import '../models/exercicio.dart';
import 'trilha_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.nomeUsuario = 'Amiguinho',
  });

  final String nomeUsuario;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5C6F5),

      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(widget.nomeUsuario),

              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFFCF0FF),
                ),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 320),

                child: Consumer<UserProgress>(
                  builder: (context, progresso, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStreakSection(progresso),

                        const SizedBox(height: 30),

                        const Text(
                          'Suas Trilhas',
                          style: TextStyle(
                            fontFamily: 'LeagueSpartan',
                            color: Color(0xFF7B2FBE),
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 5),

                        _TrilhaCard(
                          trilha: DadosApp.trilhas.firstWhere(
                            (t) => t.id == 'fonemas',
                          ),
                          backgroundColor: const Color(0xFFFFCC80),
                          iconAsset:
                              'assets/images/home_fonemas_icon.png',
                          progresso:
                              progresso.getProgressoTrilha('fonemas'),
                          total: DadosApp.trilhas
                              .firstWhere((t) => t.id == 'fonemas')
                              .exercicios
                              .length,
                        ),

                        const SizedBox(height: 15),

                        _TrilhaCard(
                          trilha: DadosApp.trilhas.firstWhere(
                            (t) => t.id == 'trava_linguas',
                          ),
                          backgroundColor: const Color(0xFFFFB4DF),
                          iconAsset:
                              'assets/images/home_trava_icon.png',
                          progresso: progresso
                              .getProgressoTrilha('trava_linguas'),
                          total: DadosApp.trilhas
                              .firstWhere(
                                (t) => t.id == 'trava_linguas',
                              )
                              .exercicios
                              .length,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,

        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        selectedItemColor: const Color(0xFF7B2FBE),
        unselectedItemColor: const Color(0xFFAA88CC),

        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/home_nav_trilhas.png',
              width: 20,
            ),
            label: 'Trilhas',
          ),

          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/home_nav_relatorio.png',
              width: 20,
            ),
            label: 'Relatório',
          ),

          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/home_nav_perfil.png',
              width: 20,
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String nomeUsuario) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;

  return SizedBox(
    height: 140,
    child: Stack(
      children: [
        Positioned(
          right: 0,
          bottom: 0,
          top: 0,
          child: SvgPicture.asset(
            'assets/images/Prancheta4.svg',
            width: 145,
            fit: BoxFit.fitHeight,
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 160, 0),

          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Olá $nomeUsuario,',

                  style: textTheme.titleMedium?.copyWith(
                    fontFamily: 'LeagueSpartan',
                    color: colorScheme.secondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                Text(
                  'O que vamos treinar hoje?',

                  style: textTheme.headlineSmall?.copyWith(
                    fontFamily: 'LeagueSpartan',
                    color: colorScheme.secondary,
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildStreakSection(UserProgress progresso) {
    final hoje = DateTime.now();

    final diaAtual = DateTime(
      hoje.year,
      hoje.month,
      hoje.day,
    );

    final inicioSemana = diaAtual.subtract(
      Duration(days: diaAtual.weekday % DateTime.daysPerWeek),
    );

    final atividadeSemana =
        progresso.getAtividadeSemanaAtual(
      referenceDate: diaAtual,
    );

    const labelsSemana = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          'Sua Sequência',

          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            color: Color(0xFF7B2FBE),
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: 5),

        Container(
          width: double.infinity,

          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),

          decoration: BoxDecoration(
            color: const Color(0xFFB8F07A),
            borderRadius: BorderRadius.circular(10),
          ),

          child: Row(
            children: [
              Image.asset(
                'assets/images/home_streak_fire.png',
                width: 35,
              ),

              Expanded(
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround,

                  children: List.generate(
                    labelsSemana.length,
                    (index) {
                      final data = inicioSemana.add(
                        Duration(days: index),
                      );

                      return _DiaChip(
                        label: labelsSemana[index],

                        concluido:
                            atividadeSemana[index],

                        ehHoje:
                            data.year == diaAtual.year &&
                                data.month ==
                                    diaAtual.month &&
                                data.day == diaAtual.day,
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
    final Color fillColor =
        concluido ? const Color(0xFF5CAD4E) : Colors.white;

    final Color borderColor = concluido
        ? const Color(0xFF5CAD4E)
        : (ehHoje
            ? const Color(0xFF3A7D44)
            : const Color(0xFFA8D880));

    final Color textColor = concluido
        ? Colors.white
        : (ehHoje
            ? const Color(0xFF3A7D44)
            : const Color(0xFF6DB56D));

    return Container(
      width: 35,
      height: 35,

      decoration: BoxDecoration(
        color: fillColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2.0,
        ),
      ),

      child: Center(
        child: concluido
            ? const Icon(
                Icons.check_rounded,
                size: 10,
                color: Colors.white,
              )
            : Text(
                label,

                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  color: textColor,
                  fontSize: 15,
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
    final double pct =
        total > 0 ? progresso / total : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrilhaScreen(
              trilha: trilha,
            ),
          ),
        );
      },

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),

        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,

              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.55),
                borderRadius: BorderRadius.circular(10),
              ),

              padding: const EdgeInsets.all(2),

              child: Image.asset(
                iconAsset,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    trilha.titulo,

                    style: const TextStyle(
                      fontFamily: 'LeagueSpartan',
                      color: Color(0xFF5C1A8A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  Text(
                    trilha.subtitulo,

                    style: const TextStyle(
                      fontFamily: 'LeagueSpartan',
                      color: Color(0xFF7A4490),
                      fontSize: 14,
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(5),

                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 5,

                            backgroundColor:
                                Colors.white.withOpacity(0.6),

                            valueColor:
                                const AlwaysStoppedAnimation<
                                    Color>(
                              Color(0xFF7B2FBE),
                            ),
                          ),
                        ),
                      ),

                      Text(
                        '$progresso/$total',

                        style: const TextStyle(
                          fontFamily: 'LeagueSpartan',
                          color: Color(0xFF5C1A8A),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF7B2FBE),
              size: 40,
            ),
          ],
        ),
      ),
    );
  }
}