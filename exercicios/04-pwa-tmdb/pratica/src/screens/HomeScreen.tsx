// src/screens/HomeScreen.tsx

import { useState, useRef } from 'react';
import { usePopularMovies, isTokenMissing } from '../hooks/useTmdb';
import { useInfiniteScroll } from '../hooks/useInfiniteScroll';
import { useOfflineStatus } from '../hooks/useOfflineStatus';
import { AppHeader } from '../components/AppHeader';
import { InstallButton } from '../components/InstallButton';
import { MovieCard } from '../components/MovieCard';
import { MovieCardSkeleton } from '../components/MovieCardSkeleton';
import { NetworkToggle } from '../components/NetworkToggle';
import { EmptyMoviesScreen } from './EmptyMoviesScreen';
import { ErrorScreen } from './ErrorScreen';
import { TokenMissingScreen } from './TokenMissingScreen';
import type { Tab } from '../components/BottomTabBar';
import { styles } from './HomeScreen.styles';

type Props = {
  activeTab: Tab;
  isFavorite: (id: number) => boolean;
  toggleFavorite: (id: number) => void;
  count: number;
};

const searchInputStyle: React.CSSProperties = {
  width: '100%',
  boxSizing: 'border-box',
  padding: '12px 16px',
  borderRadius: 12,
  border: '1px solid #2a3f55',
  background: '#1c2d40',
  color: '#e5e5e5',
  fontSize: 16,
  marginBottom: 16,
  outline: 'none',
};

export function HomeScreen({ activeTab, isFavorite, toggleFavorite }: Props) {
  const { movies, loading, error, hasMore, loadMore } = usePopularMovies();
  const [search, setSearch] = useState('');
  const sentinelRef = useRef<HTMLDivElement>(null);
  const { isOnline } = useOfflineStatus();

  useInfiniteScroll(sentinelRef, loadMore);

  if (isTokenMissing) return <TokenMissingScreen />;
  if (error) return <ErrorScreen error={error} />;

  const isEmpty = !loading && movies.length === 0;

  // ─── tab: favorites — lista dos favoritos + estado vazio + banner offline ───
  if (activeTab === 'favorites') {
    const favMovies = movies.filter((m) => isFavorite(m.id));
    return (
      <main style={styles.main} className="main-content">
        <AppHeader title="★ Favoritos" />
        {!isOnline && (
          <div style={{ background: '#C2410C', color: '#fff', padding: '8px 16px', textAlign: 'center', fontSize: 14 }}>
            📡 Offline — exibindo dados do cache
          </div>
        )}
        {favMovies.length === 0 ? (
          <p style={{ color: '#90a4ae', textAlign: 'center', padding: '40px 0', fontSize: 15 }}>
            {isEmpty ? 'Nenhum filme carregado ainda.' : 'Nenhum favorito ainda — toque ★ em um filme.'}
          </p>
        ) : (
          <section>
            {favMovies.map((m) => (
              <MovieCard key={m.id} movie={m} isFavorite={true} onToggleFavorite={toggleFavorite} />
            ))}
          </section>
        )}
      </main>
    );
  }

  // — tab: search
  if (activeTab === 'search') {
    const visible = search.trim()
      ? movies.filter((m) => m.title.toLowerCase().includes(search.toLowerCase()))
      : movies;
    return (
      <main style={styles.main} className="main-content">
        <AppHeader title="🔍 Buscar" />
        <NetworkToggle />
        <input
          type="search"
          placeholder="Buscar filme…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={searchInputStyle}
          aria-label="Buscar filme"
          // eslint-disable-next-line jsx-a11y/no-autofocus
          autoFocus
        />
        <section>
          {visible.length === 0 && search && (
            <p style={{ color: '#90a4ae', textAlign: 'center', padding: 24 }}>
              Nenhum resultado para "{search}"
            </p>
          )}
          {isEmpty && !search && <EmptyMoviesScreen />}
          {visible.map((m) => (
            <MovieCard
              key={m.id}
              movie={m}
              isFavorite={isFavorite(m.id)}
              onToggleFavorite={toggleFavorite}
            />
          ))}
        </section>
        {loading && (
          <section aria-label="Carregando mais filmes">
            <MovieCardSkeleton />
            <MovieCardSkeleton />
          </section>
        )}
        {hasMore && !loading && <div ref={sentinelRef} style={{ height: 1 }} />}
      </main>
    );
  }

  // — tab: home (default)
  return (
    <main style={styles.main} className="main-content">
      <AppHeader />
      <NetworkToggle />
      <InstallButton />
      <section>
        {isEmpty && <EmptyMoviesScreen />}
        {movies.map((m) => (
          <MovieCard
            key={m.id}
            movie={m}
            isFavorite={isFavorite(m.id)}
            onToggleFavorite={toggleFavorite}
          />
        ))}
      </section>
      {loading && (
        <section aria-label="Carregando mais filmes">
          <MovieCardSkeleton />
          <MovieCardSkeleton />
          <MovieCardSkeleton />
        </section>
      )}
      {hasMore && !loading && <div ref={sentinelRef} style={{ height: 1 }} />}
    </main>
  );
}
