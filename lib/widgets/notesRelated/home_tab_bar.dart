import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';

/// Abas "All" (notas) e "Folder" (pastas) da tela inicial.
class HomeTabBar extends StatelessWidget {
  const HomeTabBar({super.key, required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      unselectedLabelColor: Colors.white54,
      controller: controller,
      splashFactory: NoSplash.splashFactory,
      // Desde o Flutter 3.44 (Material 3) o padrao e o indicador ter a largura
      // do texto, e o MaterialIndicator abaixo exige mais de 2 x 75 px: a
      // pintura falhava e as abas sumiam. Volta ao indicador da largura da
      // aba, como no Material 2, e tira a linha divisoria que o M3 adiciona.
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      tabs: [
        Tab(
          child: Text(
            'All',
            style: GoogleFonts.roboto(
                letterSpacing: 1, fontSize: 17, fontWeight: FontWeight.w400),
          ),
        ),
        Tab(
            child: Text('Folder',
                style: GoogleFonts.roboto(
                    letterSpacing: 1,
                    fontSize: 17,
                    fontWeight: FontWeight.w500)))
      ],
      indicator: MaterialIndicator(
          color: Theme.of(context).tabBarTheme.labelColor!,
          topLeftRadius: 2,
          topRightRadius: 2,
          horizontalPadding: 75),
    );
  }
}
