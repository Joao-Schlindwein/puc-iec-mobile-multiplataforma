// src/components/TokenMissingScreen.tsx
//
// Tela de erro amigável quando TMDB API token não está configurado.
// Aparece automaticamente quando service detecta erro 401 ou token ausente.

import { ScrollView, StyleSheet, Text, View } from 'react-native';

export default function TokenMissingScreen() {
  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.emoji}>🔑</Text>
      <Text style={styles.title}>TMDB Token ausente ou inválido</Text>
      <Text style={styles.subtitle}>
        Esse app precisa de uma API key da TMDB pra carregar filmes.
      </Text>

      <View style={styles.steps}>
        <Text style={styles.stepTitle}>Como resolver (~2min):</Text>

        <View style={styles.step}>
          <Text style={styles.stepNum}>1.</Text>
          <Text style={styles.stepText}>
            Cria conta grátis em{'\n'}
            <Text style={styles.link}>https://www.themoviedb.org/signup</Text>
          </Text>
        </View>

        <View style={styles.step}>
          <Text style={styles.stepNum}>2.</Text>
          <Text style={styles.stepText}>
            Settings → API → Request API key{'\n'}(Developer, uso pessoal/educacional)
          </Text>
        </View>

        <View style={styles.step}>
          <Text style={styles.stepNum}>3.</Text>
          <Text style={styles.stepText}>
            Copia o <Text style={styles.code}>API Read Access Token</Text>
            {'\n'}(começa com{' '}<Text style={styles.code}>eyJhbGc...</Text>)
          </Text>
        </View>

        <View style={styles.step}>
          <Text style={styles.stepNum}>4.</Text>
          <Text style={styles.stepText}>
            Na raiz do projeto, copia{' '}
            <Text style={styles.code}>.env.example</Text> pra{' '}
            <Text style={styles.code}>.env</Text> e cola o token:
          </Text>
        </View>

        <View style={styles.codeBlock}>
          <Text style={styles.codeBlockText}>
            EXPO_PUBLIC_TMDB_TOKEN=eyJhbGc...
          </Text>
        </View>

        <View style={styles.step}>
          <Text style={styles.stepNum}>5.</Text>
          <Text style={styles.stepText}>
            Reinicia o Expo (Ctrl+C no terminal e{' '}
            <Text style={styles.code}>npx expo start</Text> de novo).
          </Text>
        </View>
      </View>

      <Text style={styles.warning}>
        ⚠️ Nunca comite <Text style={styles.code}>.env</Text>. Já está no{' '}
        <Text style={styles.code}>.gitignore</Text>.
      </Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { padding: 24, gap: 16, maxWidth: 600, alignSelf: 'center' },
  emoji: { fontSize: 64, textAlign: 'center' },
  title: { fontSize: 22, fontWeight: 'bold', textAlign: 'center', color: '#003366' },
  subtitle: { fontSize: 16, textAlign: 'center', color: '#555', marginBottom: 8 },
  steps: { gap: 12, marginTop: 8 },
  stepTitle: { fontSize: 18, fontWeight: '600', marginBottom: 8 },
  step: { flexDirection: 'row', gap: 8 },
  stepNum: { fontSize: 16, fontWeight: 'bold', color: '#2C5F8F', minWidth: 24 },
  stepText: { fontSize: 14, flex: 1, lineHeight: 20 },
  link: { color: '#0066cc', textDecorationLine: 'underline' },
  code: {
    fontFamily: 'monospace',
    backgroundColor: '#f0f0f0',
    paddingHorizontal: 4,
    fontSize: 13,
  },
  codeBlock: {
    backgroundColor: '#1e1e1e',
    padding: 12,
    borderRadius: 6,
    marginVertical: 8,
  },
  codeBlockText: { color: '#7ec699', fontFamily: 'monospace', fontSize: 13 },
  warning: { fontSize: 13, textAlign: 'center', color: '#cc6600', marginTop: 16 },
});
