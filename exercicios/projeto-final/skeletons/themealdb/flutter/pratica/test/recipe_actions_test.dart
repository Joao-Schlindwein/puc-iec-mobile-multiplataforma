import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themeal_final/api/themealdb_api.dart';
import 'package:themeal_final/main.dart';
import 'package:themeal_final/storage/favorites_store.dart';

void main() {
  const channel = MethodChannel('dev.fluttercommunity.plus/share');
  const videoChannel = MethodChannel('plugins.flutter.io/url_launcher');
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(videoChannel, null);
  });

  Future<void> showDetail(WidgetTester tester, {String video = ''}) async {
    final api = TheMealDbApi(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'meals': [
              {
                'idMeal': '1',
                'strMeal': 'Arroz',
                'strMealThumb': '',
                'strIngredient1': 'Arroz',
                'strMeasure1': '1 xícara',
                'strYoutube': video,
                'strSource': 'https://example.com/arroz',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    await tester.pumpWidget(
      TheMealDbFinalApp(api: api, favoritesStore: FavoritesStore()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arroz').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Compartilhar'));
  }

  testWidgets('compartilha nome, ingredientes e fonte pela plataforma', (
    tester,
  ) async {
    MethodCall? captured;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          captured = call;
          return 'dev.fluttercommunity.plus/share/dismissed';
        });
    await showDetail(tester);
    expect(find.text('Ver vídeo'), findsNothing);
    await tester.tap(find.text('Compartilhar'));
    await tester.pumpAndSettle();
    expect(captured?.method, 'share');
    final arguments = captured!.arguments as Map;
    expect(arguments['text'], contains('Arroz — 1 xícara'));
    expect(arguments['text'], contains('https://example.com/arroz'));
  });

  testWidgets('falha do compartilhamento mostra SnackBar sem crash', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(code: 'indisponivel');
        });
    await showDetail(tester);
    await tester.tap(find.text('Compartilhar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Não foi possível compartilhar a receita. Tente novamente.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('envia o link HTTPS para abertura externa', (tester) async {
    MethodCall? captured;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(videoChannel, (call) async {
          captured = call;
          return true;
        });
    await showDetail(tester, video: 'https://www.youtube.com/watch?v=abc');
    await tester.tap(find.text('Ver vídeo'));
    await tester.pumpAndSettle();
    final args = captured!.arguments as Map;
    expect(args['url'], 'https://www.youtube.com/watch?v=abc');
    expect(args['useWebView'], isFalse);
    expect(args['useSafariVC'], isFalse);
  });

  testWidgets('sem app para abrir vídeo mostra SnackBar', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(videoChannel, (_) async => false);
    await showDetail(tester, video: 'https://www.youtube.com/watch?v=abc');
    await tester.tap(find.text('Ver vídeo'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Não foi possível abrir o vídeo. Verifique se há um navegador instalado.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('exceção da plataforma ao abrir vídeo não derruba tela', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(videoChannel, (_) async {
          throw PlatformException(code: 'falha');
        });
    await showDetail(tester, video: 'https://www.youtube.com/watch?v=abc');
    await tester.tap(find.text('Ver vídeo'));
    await tester.pumpAndSettle();
    expect(
      find.text('Não foi possível abrir o vídeo. Tente novamente.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('vídeo só aparece com link e link inválido mostra SnackBar', (
    tester,
  ) async {
    await showDetail(tester, video: 'não é uma URL');
    expect(find.text('Ver vídeo'), findsOneWidget);
    await tester.tap(find.text('Ver vídeo'));
    await tester.pumpAndSettle();
    expect(find.text('O link do vídeo é inválido.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
