// src/queries/movies/search-movies.ts
//
// CAMADA QUERIES — busca de filmes (debounced).
//
// Bonus pra Atividade 2: implementar tela de busca usando esse hook.

import { useQuery } from '@tanstack/react-query';
import { api } from '@/services/api';
import type { MoviesResponse } from '@/types/movie';

const fetchSearchMovies = async (query: string) => {
  const res = await api.get<MoviesResponse>('/search/movie', { params: { query } });
  return res.data;
};

export const useSearchMovies = (query: string) =>
  useQuery({
    queryKey: ['movies', 'search', query],
    queryFn: () => fetchSearchMovies(query),
    enabled: query.trim().length >= 2, // só busca com 2+ chars
    staleTime: 1000 * 30, // resultado de busca dura 30s
  });
