/// Tradução do conteúdo das receitas (a TheMealDB só fala inglês).
///
/// É uma interface para os testes usarem um tradutor falso, sem o plugin
/// nativo; o app usa `MlKitRecipeTranslator`.
abstract class RecipeTranslator {
  /// Deixa o tradutor pronto (no ML Kit: baixa o modelo de português na
  /// primeira vez). Lança [TranslationUnavailable] se não for possível.
  Future<void> prepare();

  /// Inglês → português: nomes, ingredientes, medidas, passos, origem.
  Future<String> toPortuguese(String english);

  /// Português → inglês: o texto da busca, para a API entender.
  Future<String> toEnglish(String portuguese);

  Future<void> dispose();
}

/// Sem tradução: o app mostra o texto original da API. É o padrão quando
/// nenhum tradutor é passado (por exemplo, nos testes de tela).
class NoRecipeTranslation implements RecipeTranslator {
  const NoRecipeTranslation();

  @override
  Future<void> prepare() async =>
      throw const TranslationUnavailable('Tradução desligada.');

  @override
  Future<String> toPortuguese(String english) async => english;

  @override
  Future<String> toEnglish(String portuguese) async => portuguese;

  @override
  Future<void> dispose() async {}
}

/// O tradutor não pode ser usado agora (sem o modelo e sem internet para
/// baixá-lo, ou plugin indisponível). O app mostra o texto original.
class TranslationUnavailable implements Exception {
  final String message;

  const TranslationUnavailable(this.message);

  @override
  String toString() => message;
}
