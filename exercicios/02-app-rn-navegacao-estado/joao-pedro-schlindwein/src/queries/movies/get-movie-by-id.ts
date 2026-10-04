// src/queries/movies/get-movie-by-id.ts
//
// CAMADA QUERIES — detalhe de 1 filme.
//
// Doc TanStack: https://tanstack.com/query/latest/docs/framework/react/guides/dependent-queries

import { useQuery } from '@tanstack/react-query';
import { api } from '@/services/api';
import type { Movie } from '@/types/movie';

const fetchMovieById = async (id: number) => {
  const res = await api.get<Movie>(`/movie/${id}`);
  return res.data;
};

// Já implementado — usado na MovieDetail. Use como referência.
export const useMovieById = (id: number) =>
  useQuery({
    queryKey: ['movie', id],
    queryFn: () => fetchMovieById(id),
    enabled: Number.isFinite(id),
  });
