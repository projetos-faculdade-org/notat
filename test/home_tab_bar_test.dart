import 'package:flutter/material.dart';
import 'package:flutter_application_again/utils/colors.dart';
import 'package:flutter_application_again/widgets/notesRelated/home_tab_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Monta as abas da tela inicial com o tema do app, na largura de um celular.
Future<void> pumpTabs(WidgetTester tester, {required double width}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: CustomTheme.DarkTheme,
    home: DefaultTabController(
      length: 2,
      child: Builder(
          builder: (context) => Scaffold(
              body: HomeTabBar(controller: DefaultTabController.of(context)))),
    ),
  ));
}

void main() {
  // Sem internet nos testes: usa a fonte padrao no lugar da Roboto.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // No Flutter 3.44 (Material 3) o indicador passou a ter a largura do
  // texto da aba. O MaterialIndicator exige ser mais largo que 2 x 75 px:
  // a pintura da TabBar falhava e as abas ficavam invisiveis.
  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets('as abas sao desenhadas sem erro (largura $width)',
        (tester) async {
      await pumpTabs(tester, width: width);

      expect(tester.takeException(), isNull);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Folder'), findsOneWidget);
    });
  }

  testWidgets('tocar em "Folder" troca de aba sem erro', (tester) async {
    await pumpTabs(tester, width: 390);

    await tester.tap(find.text('Folder'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final controller =
        DefaultTabController.of(tester.element(find.byType(HomeTabBar)));
    expect(controller.index, 1);
  });
}
