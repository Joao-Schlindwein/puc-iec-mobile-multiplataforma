// src/queries/movies/get-popular-movies.ts
//
// CAMADA QUERIES — gerencia cache + ciclo de vida dos dados do servidor.
// "Como gerenciar o ciclo de vida dos dados"
//
// HANDS-ON AULA 2 — Passo 4 (TanStack Query)
//
// Doc TanStack: https://tanstack.com/query/latest/docs/framework/react/overview
//
// Conceitos:
// - queryKey = identidade do cache (TanStack dedupe + invalidate por essa key)
// - queryFn = função pura que retorna Promise<dados>
// - staleTime = quanto tempo cache fica fresco antes de refetch background

import { useInfiniteQuery, useQuery } from '@tanstack/react-query';
import { api } from '@/services/api';
import type { MoviesResponse } from '@/types/movie';

const fetchPopularMovies = async (page = 1) => {
  const res = await api.get<MoviesResponse>('/movie/popular', { params: { page } });
  return res.data;
};

export const usePopularMovies = (page = 1) =>
  useQuery({
    queryKey: ['movies', 'popular', page],
    queryFn: () => fetchPopularMovies(page),
    staleTime: 1000 * 60 * 5, // 5 minutos
  });

// BÔNUS [TASK 10] — paginação infinita. TMDB devolve page/total_pages,
// usamos pra decidir se existe próxima página (getNextPageParam).
export const usePopularMoviesInfinite = () =>
  useInfiniteQuery({
    queryKey: ['movies', 'popular', 'infinite'],
    queryFn: ({ pageParam }) => fetchPopularMovies(pageParam),
    initialPageParam: 1,
    getNextPageParam: (lastPage) =>
      lastPage.page < lastPage.total_pages ? lastPage.page + 1 : undefined,
    staleTime: 1000 * 60 * 5,
  });
