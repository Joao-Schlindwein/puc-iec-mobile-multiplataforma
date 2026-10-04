// src/screens/FavoritesList.tsx
//
// BÔNUS — aba "Favoritos" mostrando a lista de filmes favoritados,
// persistida via MMKV (useFavoritesStore).
//
// Cada id favoritado é buscado individualmente com useMovieById (já
// cacheado pelo TanStack Query se o filme já foi visto na Home/Detail).

import { ActivityIndicator, FlatList, StyleSheet, Text, View } from 'react-native';
import { useFavoritesStore } from '@/store/favoritesStore';
import { useMovieById } from '@/queries/movies/get-movie-by-id';
import MovieCard from '@/components/MovieCard';
import type { Movie } from '@/types/movie';

function FavoriteMovieLoader({ id }: { id: number }) {
  const { data, isLoading } = useMovieById(id);
  if (isLoading || !data) return null;
  return <MovieCard movie={data} />;
}

export default function FavoritesList() {
  const ids = useFavoritesStore((s) => s.ids);

  if (ids.length === 0) {
    return (
      <View style={styles.center}>
        <Text style={styles.emptyText}>Nenhum favorito ainda</Text>
        <Text style={styles.emptyHint}>Toque no ❤️ de um filme pra favoritar</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <FlatList<number>
        data={ids}
        keyExtractor={(id) => String(id)}
        renderItem={({ item: id }) => <FavoriteMovieLoader id={id} />}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, paddingTop: 16 },
  center: { flex: 1, justifyContent: 'center', alignItems: 'center', gap: 8 },
  emptyText: { fontSize: 18, fontWeight: '600' },
  emptyHint: { color: '#666', fontSize: 13 },
});
