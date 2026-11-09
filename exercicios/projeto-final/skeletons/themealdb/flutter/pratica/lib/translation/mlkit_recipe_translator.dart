import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import 'recipe_translator.dart';

/// Tradução no próprio aparelho com o ML Kit (Google): gratuita, sem chave e
/// sem enviar as receitas a um servidor. O modelo de português (~30 MB) é
/// baixado uma vez; depois funciona offline.
class MlKitRecipeTranslator implements RecipeTranslator {
  OnDeviceTranslator? _toPortuguese;
  OnDeviceTranslator? _toEnglish;

  @override
  Future<void> prepare() async {
    final models = OnDeviceTranslatorModelManager();
    final portuguese = TranslateLanguage.portuguese.bcpCode;
    try {
      if (!await models.isModelDownloaded(portuguese)) {
        // Também por dados móveis: sem o modelo não há tradução nenhuma.
        final ok = await models.downloadModel(
          portuguese,
          isWifiRequired: false,
        );
        if (!ok) {
          throw const TranslationUnavailable(
            'Não foi possível baixar o tradutor de português.',
          );
        }
      }
    } on TranslationUnavailable {
      rethrow;
    } on Object {
      throw const TranslationUnavailable(
        'Tradutor indisponível. Conecte-se à internet para baixá-lo.',
      );
    }
    _toPortuguese ??= OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: TranslateLanguage.portuguese,
    );
    _toEnglish ??= OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.portuguese,
      targetLanguage: TranslateLanguage.english,
    );
  }

  @override
  Future<String> toPortuguese(String english) =>
      _require(_toPortuguese).translateText(english);

  @override
  Future<String> toEnglish(String portuguese) =>
      _require(_toEnglish).translateText(portuguese);

  OnDeviceTranslator _require(OnDeviceTranslator? translator) {
    if (translator == null) {
      throw const TranslationUnavailable('Tradutor ainda não está pronto.');
    }
    return translator;
  }

  @override
  Future<void> dispose() async {
    await _toPortuguese?.close();
    await _toEnglish?.close();
  }
}
